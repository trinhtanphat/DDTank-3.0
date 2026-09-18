using Game.Logic.Phy.Object;

namespace Game.Logic
{
    public interface IBotGamePlayer
    {
        bool IsBot { get; }
        void TakeTurn(PVPGame game, Player player);
    }
}
