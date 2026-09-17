using System;
using System.Collections.Generic;
using System.Text;
using Game.Logic.AI;
using Game.Logic.Phy.Object;
using Game.Logic;


namespace GameServerScript.AI.Messions
{
    class domanhinhS : AMissionControl
    {
        public override void OnPrepareNewSession()
        {
            base.OnPrepareNewSession();

            Game.SetMap(1136);
        }
    }
}
