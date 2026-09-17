using System;
using System.Collections.Generic;
using System.Text;
using Game.Logic.AI;
using Game.Logic.Phy.Object;
using Game.Logic;
using SqlDataProvider.Data;
using Bussiness;

namespace GameServerScript.AI.Messions
{
    public class GCGC1364 : AMissionControl
    {
        private PhysicalObj m_kingMoive;

        private PhysicalObj m_kingFront;

		private PhysicalObj m_wallLeft = null;

        private SimpleBoss m_king = null;

		private SimpleBoss king = null;

		private SimpleBoss boss = null;

        private SimpleBoss m_secondKing = null;

        private PhysicalObj[] m_leftWall = null;

        private PhysicalObj[] m_rightWall = null;

		private List<SimpleNpc> someNpc = new List<SimpleNpc>();

        private int m_kill = 0;

        private int m_state = 7231;

        private int turn = 0;

        private int firstBossID = 7231;

        private int secondBossID = 7232;

        private int npcID = 7233;

		private int npcID2 = 7232;

        private int direction;

        private PhysicalObj front;

        private PhysicalObj m_front;

        public override int CalculateScoreGrade(int score)
        {
            base.CalculateScoreGrade(score);
            if (score > 1150)
            {
                return 3;
            }
            else if (score > 925)
            {
                return 2;
            }
            else if (score > 700)
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
            Game.AddLoadingFile(1, "bombs/83.swf", "tank.resource.bombs.Bomb83");
			Game.AddLoadingFile(1, "bombs/84.swf", "tank.resource.bombs.Bomb84");
            Game.AddLoadingFile(2, "image/map/1076/objects/1076MapAsset.swf", "com.mapobject.asset.WaveAsset_01_left");
            Game.AddLoadingFile(2, "image/map/1076/objects/1076MapAsset.swf", "com.mapobject.asset.WaveAsset_01_right");
            Game.AddLoadingFile(2, "image/game/thing/BossBornBgAsset.swf", "game.asset.living.BossBgAsset");
            Game.AddLoadingFile(2, "image/game/thing/BossBornBgAsset.swf", "game.asset.living.choudanbenbenAsset");
			Game.AddLoadingFile(2, "image/game/living/living177.swf", "game.living.Living177");
			Game.AddLoadingFile(2, "image/game/effect/7/choud.swf", "asset.game.seven.choud");
			Game.AddLoadingFile(2, "image/game/effect/7/jinqucd.swf", "asset.game.seven.jinqucd");
			Game.AddLoadingFile(2, "image/game/effect/7/du.swf", "asset.game.seven.du");
            Game.AddLoadingFile(2, "image/game/living/living177.swf", "living177_fla.diedie_9");
            int[] resources = { firstBossID, secondBossID, npcID, npcID2 };
            Game.LoadResources(resources);
            int[] gameOverResources = { firstBossID };
            Game.LoadNpcGameOverResources(gameOverResources);

            Game.SetMap(1164);
            Game.IsBossWar = "Gà mái xấu xí";
        }

        public override void OnStartGame()
        {
            base.OnStartGame();
            m_kingMoive = Game.Createlayer(0, 0, "kingmoive", "game.asset.living.BossBgAsset", "out", 1, 1);
            m_kingFront = Game.Createlayer(300, 595, "font", "game.asset.living.choudanbenbenAsset", "out", 1, 1);
            m_front = Game.Createlayer(2080, 635, "font", "game.living.Living178", "born", 1, 0);

			boss = Game.CreateBoss(npcID2, 1920, 915, -1, 1);
			m_king = Game.CreateBoss(m_state, 200, 590, 1, 1);
			m_king.FallFrom(m_king.X, m_king.Y, "", 0, 0, 2000);

            //m_king.SetRelateDemagemRect(-21, -87, 72, 59);
            m_king.SetRelateDemagemRect(m_king.NpcInfo.X, m_king.NpcInfo.Y, m_king.NpcInfo.Width, m_king.NpcInfo.Height);
            m_king.AddDelay(10);

            m_king.Say(LanguageMgr.GetTranslation("Định giải cứu gà con à ? Đừng có mơ ...."), 0, 4000);
            m_kingMoive.PlayMovie("in", 9000, 0);
            m_kingFront.PlayMovie("in", 9000, 0);
            m_kingMoive.PlayMovie("out", 13000, 0);
            m_kingFront.PlayMovie("out", 13400, 0);
            turn = Game.TurnIndex;

            Game.BossCardCount = 1;

        }


        public override void OnNewTurnStarted()
        {
            base.OnNewTurnStarted();
            if (m_king != null && m_king.IsLiving == false)
            {
                m_leftWall = Game.FindPhysicalObjByName("wallLeft", false);

                if (m_leftWall != null)
                {
                    //Game.RemovePhysicalObj(m_leftWall[0], true);
                }

            }
        }

        public override void OnBeginNewTurn()
        {
            base.OnBeginNewTurn();
            if (Game.TurnIndex > turn + 1)
            {
                if (m_kingMoive != null)
                {
                    Game.RemovePhysicalObj(m_kingMoive, true);
                    m_kingMoive = null;
                }
                if (m_kingFront != null)
                {
                    Game.RemovePhysicalObj(m_kingFront, true);
                    m_kingFront = null;
                }
			}
		    if (Game.TurnIndex == 1)
            {
				m_wallLeft = ((PVEGame)Game).Createlayer(1920, 920, "wallLeft", "game.living.Living177", "standB", 1, 0);
				boss.Say(LanguageMgr.GetTranslation("Chúng mình không muốn bị lây bệnh, cứu cứu...."), 0, 3000);
                boss.PlayMovie("standB", 5000, 0);
            }

			if (Game.TurnIndex == 2)
            {
			    Game.RemoveLiving(boss.Id);
			}
        }

        public override bool CanGameOver()
        {
            base.CanGameOver();
            if (m_king.IsLiving == false)
            {
                if (m_state == firstBossID)
                {
                    m_state++;
                }
            }

            if (m_state == secondBossID && m_secondKing == null)
            {
                m_secondKing = Game.CreateBoss(secondBossID, 1920, 915, m_king.Direction, 1);
                m_secondKing.SetRelateDemagemRect(m_secondKing.NpcInfo.X, m_secondKing.NpcInfo.Y, m_secondKing.NpcInfo.Width, m_secondKing.NpcInfo.Height);
                Game.RemoveLiving(m_king.Id);



                m_secondKing.Say(LanguageMgr.GetTranslation("Hãy giải cứu chúng tôi !"), 1000, 0);

                List<Player> players = Game.GetAllFightPlayers();
                Player RandomPlayer = Game.FindRandomPlayer();
                int minDelay = 0;

                if (RandomPlayer != null)
                {
                    minDelay = RandomPlayer.Delay;
                }

                foreach (Player player in players)
                {
                    if (player.Delay < minDelay)
                    {
                        minDelay = player.Delay;
                    }
                }

                //m_secondKing.AddDelay(minDelay - 2000);
                //m_secondKing.AddDelay(m_secondKing.SelfTurnAddDelay());
                turn = Game.TurnIndex;
            }

            if (m_secondKing != null && m_secondKing.IsLiving == false)
            {
                direction = m_secondKing.Direction;
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

        public override void OnGameOver()
        {
            base.OnGameOver();
            if (m_state == secondBossID && m_secondKing.IsLiving == false)
            {
                Game.IsWin = true;
            }
            else
            {
                Game.IsWin = false;
            }

            List<LoadingFileInfo> loadingFileInfos = new List<LoadingFileInfo>();
            loadingFileInfos.Add(new LoadingFileInfo(2, "image/map/show7.jpg", ""));
            Game.SendLoadResource(loadingFileInfos);

            m_leftWall = Game.FindPhysicalObjByName("wallLeft");
            m_rightWall = Game.FindPhysicalObjByName("wallRight");

            for (int i = 0; i < m_leftWall.Length; i++)
                Game.RemovePhysicalObj(m_leftWall[i], true);

            for (int i = 0; i < m_rightWall.Length; i++)
                Game.RemovePhysicalObj(m_rightWall[i], true);
        }
    }
}
