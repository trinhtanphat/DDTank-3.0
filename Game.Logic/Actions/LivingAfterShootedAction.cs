using Game.Logic.Phy.Object;

namespace Game.Logic.Actions
{
    public class LivingAfterShootedAction : BaseAction
    {
        private readonly Living m_owner;
        private readonly Living m_target;

        public LivingAfterShootedAction(Living owner, Living target, int delay)
            : base(delay, 0)
        {
            m_owner = owner;
            m_target = target;
        }

        protected override void ExecuteImp(BaseGame game, long tick)
        {
            m_target.OnAfterTakedBomb();
            m_target.OnAfterTakeDamage(m_owner);
            Finish(tick);
        }
    }
}
