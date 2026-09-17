using Game.Logic;
using Game.Server.GameObjects;
using SqlDataProvider.Data;

namespace Game.Server.Quests
{
    public class FightWithPetCondition : BaseCondition
    {
        public FightWithPetCondition(BaseQuest quest, QuestConditionInfo info, int value)
            : base(quest, info, value)
        {
        }

        public override void AddTrigger(GamePlayer player)
        {
            player.GameOver += player_GameOver;
        }

        private void player_GameOver(AbstractGame game, bool isWin, int gainXp)
        {
            // The 3.0 server predates the server-side pet model. When later quest data
            // contains condition 45, keep the battle-completion portion authoritative
            // on the server instead of silently creating an unknown/empty condition.
            if (Value > 0)
            {
                Value--;
            }

            if (Value < 0)
            {
                Value = 0;
            }
        }

        public override void RemoveTrigger(GamePlayer player)
        {
            player.GameOver -= player_GameOver;
        }

        public override bool IsCompleted(GamePlayer player)
        {
            return Value <= 0;
        }
    }
}
