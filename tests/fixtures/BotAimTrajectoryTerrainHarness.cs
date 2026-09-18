using System;
using System.Collections.Generic;
using System.Drawing;
using Fighting.Server.GameObjects;

internal static class BotAimTrajectoryTerrainHarness
{
    private static int Main()
    {
        List<Rectangle> target = new List<Rectangle>();
        target.Add(new Rectangle(195, 45, 12, 12));
        Rectangle wall = new Rectangle(80, 35, 12, 30);

        BotTrajectoryProbe blocked = BotAimTrajectory.Probe(
            10, 50, 100, 0, 1, 0, 0, 0,
            target, 20, 400, 200,
            delegate(Rectangle rect) { return !rect.IntersectsWith(wall); },
            delegate(int x, int y) { return 999.0; });
        if (blocked.Outcome != BotTrajectoryOutcome.Terrain || blocked.ImpactX < 70 || blocked.ImpactX > 95)
            return 1;

        BotTrajectoryProbe clear = BotAimTrajectory.Probe(
            10, 50, 100, 0, 1, 0, 0, 0,
            target, 20, 400, 200,
            delegate(Rectangle rect) { return true; },
            delegate(int x, int y) { return 999.0; });
        if (clear.Outcome != BotTrajectoryOutcome.Target)
            return 2;

        BotTrajectoryProbe terrainOnly = BotAimTrajectory.ProbeTerrain(
            10, 50, 100, 0, 1, 0, 0, 0, 400, 200,
            delegate(Rectangle rect) { return !rect.IntersectsWith(wall); });
        if (terrainOnly.Outcome != BotTrajectoryOutcome.Terrain)
            return 3;

        Console.WriteLine("DDT30_BOT_TERRAIN_PROBE=PASS");
        return 0;
    }
}
