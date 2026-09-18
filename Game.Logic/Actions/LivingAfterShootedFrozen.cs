using Game.Logic.Phy.Object;

namespace Game.Logic.Actions
{
    public class LivingAfterShootedFrozen : BaseAction
    {
        private readonly Living m_target;

        public LivingAfterShootedFrozen(Living target, int delay)
            : base(delay, 0)
        {
            m_target = target;
        }

        protected override void ExecuteImp(BaseGame game, long tick)
        {
            m_target.OnAfterTakedFrozen();
            Finish(tick);
        }
    }
}
