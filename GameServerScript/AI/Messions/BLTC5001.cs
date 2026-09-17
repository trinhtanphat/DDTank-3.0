using System;
using System.Collections.Generic;
using System.Text;
using Game.Logic.AI;
using Game.Logic.Phy.Object;
using SqlDataProvider.Data;
using Game.Logic;
using Bussiness;

namespace GameServerScript.AI.Messions
{
    public class BLTC5001 : AMissionControl
    {
        private SimpleBoss boss = null;

        private int m_kill = 0;

        private int bossID = 3016;

        private int npcID = 2004;

        private PhysicalObj m_moive;

        private PhysicalObj m_front;

        public override int CalculateScoreGrade(int score)
        {
            base.CalculateScoreGrade(score);
            if (score > 1330)
            {
                return 3;
            }
            else if (score > 1150)
            {
                return 2;
            }
            else if (score > 970)
            {
                return 1;
            }
            else
            {
                return 0;
            }
        }

        public override void OnPrepareNewSession()
        {
            base.OnPrepareNewSession();
            int[] resources = { bossID, npcID };
            int[] gameOverResource = { bossID };
            Game.LoadResources(resources);
            Game.LoadNpcGameOverResources(gameOverResource);
			//Game.AddLoadingFile(1, "bombs/54.swf", "tank.resource.bombs.Bomb54");

            Game.AddLoadingFile(1, "bombs/51.swf", "tank.resource.bombs.Bomb51");
            Game.AddLoadingFile(2, "image/game/thing/BossBornBgAsset.swf", "game.asset.living.BossBgAsset");
            Game.AddLoadingFile(2, "image/game/thing/BossBornBgAsset.swf", "game.asset.living.ClanLeaderAsset");
            Game.SetMap(1126);
        }

        public override void OnStartGame()
        {
            base.OnStartGame();
            m_moive = Game.Createlayer(0, 0, "moive", "game.asset.living.BossBgAsset", "out", 1, 0);
            m_front = Game.Createlayer(600, 300, "font", "game.asset.living.ClanLeaderAsset", "out", 1, 0);
            boss = Game.CreateBoss(bossID, 750, -1500, -1, 1);

            boss.FallFrom(750, 301, "fall", 0, 2, 1000);
            boss.SetRelateDemagemRect(34, -35, 11, 18);
            boss.AddDelay(10);
           boss.Say("Đến đây thôi, dám ngăn cản nghi lễ của ta, không muốn sống à!", 0, 6000);

            //boss.PlayMovie("call", 5900, 0);
            //m_moive.PlayMovie("in", 9000, 0);
            //boss.PlayMovie("weakness", 10000, 5000);
            //m_front.PlayMovie("in", 9000, 0);
            //m_moive.PlayMovie("out", 15000, 0);

			m_moive.PlayMovie("in", 11000, 7000);
            m_front.PlayMovie("in", 12100, 0);
            m_moive.PlayMovie("out", 16000, 7000);
            m_front.PlayMovie("out", 600, 0);

        }



        public override void OnNewTurnStarted()
        {
            base.OnNewTurnStarted();
            if (boss.State == 0)
            {
                boss.SetRelateDemagemRect(-41, -187, 83, 140);
            }
        }

        public override void OnBeginNewTurn()
        {
            base.OnBeginNewTurn();

            if (m_moive != null)
            {
                Game.RemovePhysicalObj(m_moive, true);
                m_moive = null;
            }
            if (m_front != null)
            {
                Game.RemovePhysicalObj(m_front, true);
                m_front = null;
            }
        }

        public override bool CanGameOver()
        {
            if (boss.IsLiving == false)
            {
                m_kill++;
                return true;
            }
            return false;
        }


        public override int UpdateUIData()
        {
            base.UpdateUIData();
            return m_kill;
        }


        //public override void OnPrepareGameOver()
        //{
        //    base.OnPrepareGameOver();
        //}

        public override void OnGameOver()
        {
            base.OnGameOver();
            bool IsAllPlayerDie = true;
            foreach (Player player in Game.GetAllFightPlayers())
            {
                if (player.IsLiving == true)
                {
                    IsAllPlayerDie = false;
                }
            }
            if (boss.IsLiving == false && IsAllPlayerDie == false)
            {
                Game.IsWin = true;
            }
            else
            {
                Game.IsWin = false;
            }
        }
    }
}
