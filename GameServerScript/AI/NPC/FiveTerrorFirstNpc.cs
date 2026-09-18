using Game.Logic.AI;
using Game.Logic.Phy.Object;
using System;

namespace GameServerScript.AI.NPC
{
	public class FiveTerrorFirstNpc : ABrain
	{
		private int m_attackTurn = 0;

		private static string[] AllAttackChat = new string[]
		{
			"要地震喽！！<br/>各位请扶好哦",
			"把你武器震下来！",
			"看你们能还经得起几下！！"
		};

		private static string[] ShootChat = new string[]
		{
			"让你知道什么叫百发百中！",
			"送你一个球~你可要接好啦",
			"你们这群无知的低等庶民"
		};

		private static string[] ShootedChat = new string[]
		{
			"哎呀~~你们为什么要攻击我？<br/>我在干什么？",
			"噢~~好痛!我为什么要战斗？<br/>我必须战斗…"
		};

		private static string[] AddBooldChat = new string[]
		{
			"扭啊扭~<br/>扭啊扭~~",
			"哈利路亚~<br/>路亚路亚~~",
			"呀呀呀，<br/>好舒服啊！"
		};

		private static string[] KillAttackChat = new string[]
		{
			"君临天下！！"
		};

		public override void OnBeginSelfTurn()
		{
			base.OnBeginSelfTurn();
		}

		public override void OnBeginNewTurn()
		{
			base.OnBeginNewTurn();
			this.m_body.CurrentDamagePlus = 1f;
			this.m_body.CurrentShootMinus = 1f;
		}

		public override void OnCreated()
		{
			base.OnCreated();
		}

		public override void OnStartAttacking()
		{
			base.Body.Direction = base.Game.FindlivingbyDir(base.Body);
			bool flag = false;
			int num = 0;
			foreach (Player current in base.Game.GetAllFightPlayers())
			{
				if (current.IsLiving && current.X > 0 && current.X < 0)
				{
					int num2 = (int)base.Body.Distance(current.X, current.Y);
					if (num2 > num)
					{
						num = num2;
					}
					flag = true;
				}
			}
			if (flag)
			{
				this.KillAttack(0, 0);
			}
			else if (this.m_attackTurn == 0)
			{
				this.Walk();
				this.m_attackTurn++;
			}
			else if (this.m_attackTurn == 1)
			{
				this.Walk();
				this.m_attackTurn++;
			}
			else if (this.m_attackTurn == 2)
			{
				this.Walk();
				this.m_attackTurn++;
			}
			else if (this.m_attackTurn == 3)
			{
				this.Walk();
				this.m_attackTurn++;
			}
			else if (this.m_attackTurn == 4)
			{
				this.Ato();
				this.m_attackTurn++;
			}
			else
			{
				this.Stand();
			}
		}

		public override void OnStopAttacking()
		{
			base.OnStopAttacking();
		}

		private void KillAttack(int fx, int tx)
		{
			int num = base.Game.Random.Next(0, FiveTerrorFirstNpc.KillAttackChat.Length);
			base.Body.Say(FiveTerrorFirstNpc.KillAttackChat[num], 1, 1000);
			base.Body.CurrentDamagePlus = 10f;
			base.Body.PlayMovie("beat", 3000, 0);
			base.Body.RangeAttacking(fx, tx, "cry", 5000, null);
		}

		private void Walk()
		{
			base.Body.PlayMovie("walkA", 3000, 1000);
		}

		private void Stand()
		{
			base.Body.PlayMovie("standA", 3000, 1000);
		}

		private void Ato()
		{
			base.Body.PlayMovie("AtoB", 3000, 5000);
			base.Body.CallFuction(new LivingCallBack(this.WalkB), 2000);
		}

		private void WalkB()
		{
			base.Body.PlayMovie("walkB", 3000, 2000);
		}
	}
}
