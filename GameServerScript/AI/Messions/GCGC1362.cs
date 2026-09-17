using System;
using System.Collections.Generic;
using System.Text;
using Game.Logic.AI;
using Game.Logic.Phy.Object;
using Game.Logic;

namespace GameServerScript.AI.Messions
{
    public class GCGC1362 : AMissionControl
    {
        private int killCount = 0;

		private SimpleBoss boss1 = null;

		private SimpleBoss boss2 = null;

		private SimpleBoss boss3 = null;

        private int bossID1 = 7211;

		private int bossID2 = 7211;

		private int bossID3 = 7211;

        public override int CalculateScoreGrade(int score)
        {
            base.CalculateScoreGrade(score);
            if (score > 1750)
            {
                return 3;
            }
            else if (score > 1675)
            {
                return 2;
            }
            else if (score > 1600)
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
            int[] resources = { bossID1,bossID2,bossID3 };
            int[] gameOverResource = { bossID3,bossID1,bossID2 };
            Game.LoadResources(resources);
            Game.LoadNpcGameOverResources(gameOverResource);
            Game.AddLoadingFile(1, "bombs/84.swf", "tank.resource.bombs.Bomb84");
            Game.SetMap(1162);
        }


        public override void OnStartGame()
        {
            base.OnStartGame();
            boss1 = Game.CreateBoss(bossID1, 1565, 787, -1, 1);
            boss2 = Game.CreateBoss(bossID2, 1583, 495, -1, 1);
            boss3 = Game.CreateBoss(bossID3, 1643, 236, -1, 1);
            boss1.SetRelateDemagemRect(boss1.NpcInfo.X, boss1.NpcInfo.Y, boss1.NpcInfo.Width, boss1.NpcInfo.Height);
            boss2.SetRelateDemagemRect(boss2.NpcInfo.X, boss2.NpcInfo.Y, boss2.NpcInfo.Width, boss2.NpcInfo.Height);
            boss3.SetRelateDemagemRect(boss3.NpcInfo.X, boss3.NpcInfo.Y, boss3.NpcInfo.Width, boss3.NpcInfo.Height);
        }

        public override void OnNewTurnStarted()
        {
			base.OnNewTurnStarted();
        }

        public override void OnBeginNewTurn()
        {
			base.OnBeginNewTurn();
        }

		 public override bool CanGameOver()
        {
            if (boss2 != null && boss2.IsLiving == false && boss1 != null && boss1.IsLiving == false && boss3 != null && boss3.IsLiving == false)
            {
                return true;
            }
            return false;
        }

        public override int UpdateUIData()
        {
            return Game.TotalKillCount;
        }


        public override void OnGameOver()
        {
            base.OnGameOver();
            if (boss2 != null && boss2.IsLiving == false && boss1 != null && boss1.IsLiving == false && boss3 != null && boss3.IsLiving == false)
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
