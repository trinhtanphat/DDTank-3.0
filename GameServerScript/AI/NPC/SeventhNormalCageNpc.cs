using Game.Logic.AI;
using System;

namespace GameServerScript.AI.NPC
{
	public class SeventhNormalCageNpc : ABrain
	{
		public override void OnStartAttacking()
		{
			if (base.Body.Blood == 0)
			{
				this.Out();
			}
		}

		private void Out()
		{
			base.Body.PlayMovie("out", 3000, 0);
		}
	}
}
