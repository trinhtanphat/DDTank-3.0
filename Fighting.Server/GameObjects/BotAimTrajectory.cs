using System;
using System.Collections.Generic;
using System.Drawing;

namespace Fighting.Server.GameObjects
{
    internal enum BotTrajectoryOutcome
    {
        None = 0,
        Target = 1,
        Terrain = 2,
        OutOfMap = 3
    }

    internal struct BotTrajectoryProbe
    {
        public BotTrajectoryOutcome Outcome;
        public int ImpactX;
        public int ImpactY;

        public BotTrajectoryProbe(BotTrajectoryOutcome outcome, int impactX, int impactY)
        {
            Outcome = outcome;
            ImpactX = impactX;
            ImpactY = impactY;
        }
    }

    internal static class BotAimTrajectory
    {
        private const float Step = 0.04f;
        private const float MaxLife = 6.0f;

        public static bool IsViable(float startX, float startY, int force, int angle,
            float mass, float airResistance, float gravity, float wind,
            IList<Rectangle> targetBounds, int blastRadius, int mapWidth, int mapHeight,
            Func<Rectangle, bool> isRectangleEmpty, Func<int, int, double> targetDamageDistance)
        {
            BotTrajectoryProbe probe = Probe(startX, startY, force, angle, mass, airResistance,
                gravity, wind, targetBounds, blastRadius, mapWidth, mapHeight,
                isRectangleEmpty, targetDamageDistance);
            return probe.Outcome == BotTrajectoryOutcome.Target;
        }

        public static BotTrajectoryProbe Probe(float startX, float startY, int force, int angle,
            float mass, float airResistance, float gravity, float wind,
            IList<Rectangle> targetBounds, int blastRadius, int mapWidth, int mapHeight,
            Func<Rectangle, bool> isRectangleEmpty, Func<int, int, double> targetDamageDistance)
        {
            if (force <= 0 || mass <= 0 || isRectangleEmpty == null || targetDamageDistance == null ||
                targetBounds == null || targetBounds.Count == 0)
                return new BotTrajectoryProbe(BotTrajectoryOutcome.None, (int)startX, (int)startY);

            return ProbeCore(startX, startY, force, angle, mass, airResistance, gravity, wind,
                targetBounds, blastRadius, mapWidth, mapHeight, isRectangleEmpty,
                targetDamageDistance, true);
        }

        public static BotTrajectoryProbe ProbeTerrain(float startX, float startY, int force, int angle,
            float mass, float airResistance, float gravity, float wind,
            int mapWidth, int mapHeight, Func<Rectangle, bool> isRectangleEmpty)
        {
            if (force <= 0 || mass <= 0 || isRectangleEmpty == null)
                return new BotTrajectoryProbe(BotTrajectoryOutcome.None, (int)startX, (int)startY);

            return ProbeCore(startX, startY, force, angle, mass, airResistance, gravity, wind,
                null, 0, mapWidth, mapHeight, isRectangleEmpty, null, false);
        }

        private static BotTrajectoryProbe ProbeCore(float startX, float startY, int force, int angle,
            float mass, float airResistance, float gravity, float wind,
            IList<Rectangle> targetBounds, int blastRadius, int mapWidth, int mapHeight,
            Func<Rectangle, bool> isRectangleEmpty, Func<int, int, double> targetDamageDistance,
            bool detectTarget)
        {
            double radians = angle / 180.0 * Math.PI;
            float vx = (int)(force * Math.Cos(radians));
            float vy = (int)(force * Math.Sin(radians));
            float x = startX;
            float y = startY;
            int previousX = (int)x;
            int previousY = (int)y;

            for (float life = 0; life <= MaxLife; life += Step)
            {
                float ax = (wind - airResistance * vx) / mass;
                float ay = (gravity - airResistance * vy) / mass;
                vx += ax * Step;
                vy += ay * Step;
                x += vx * Step;
                y += vy * Step;

                int px = (int)x;
                int py = (int)y;
                BotTrajectoryProbe segment = TraceSegment(previousX, previousY, px, py,
                    targetBounds, blastRadius, mapWidth, mapHeight, isRectangleEmpty,
                    targetDamageDistance, detectTarget);
                if (segment.Outcome != BotTrajectoryOutcome.None)
                    return segment;
                previousX = px;
                previousY = py;
            }

            return new BotTrajectoryProbe(BotTrajectoryOutcome.None, previousX, previousY);
        }

        private static BotTrajectoryProbe TraceSegment(int x1, int y1, int x2, int y2,
            IList<Rectangle> targetBounds, int blastRadius, int mapWidth, int mapHeight,
            Func<Rectangle, bool> isRectangleEmpty, Func<int, int, double> targetDamageDistance,
            bool detectTarget)
        {
            int dx = x2 - x1;
            int dy = y2 - y1;
            int count = Math.Max(Math.Abs(dx), Math.Abs(dy));
            if (count == 0)
                return new BotTrajectoryProbe(BotTrajectoryOutcome.None, x2, y2);

            bool useX = Math.Abs(dx) > Math.Abs(dy);
            int direction = useX ? dx / count : dy / count;
            for (int i = 1; i <= count; i += 3)
            {
                int px;
                int py;
                if (useX)
                {
                    px = x1 + i * direction;
                    py = x2 == x1 ? y1 : (px - x1) * (y2 - y1) / (x2 - x1) + y1;
                }
                else
                {
                    py = y1 + i * direction;
                    px = y2 == y1 ? x1 : (py - y1) * (x2 - x1) / (y2 - y1) + x1;
                }

                Rectangle projectile = new Rectangle(px - 3, py - 3, 6, 6);
                if (detectTarget && IntersectsAny(projectile, targetBounds))
                    return new BotTrajectoryProbe(BotTrajectoryOutcome.Target, px, py);

                if (!isRectangleEmpty(projectile))
                {
                    if (detectTarget && targetDamageDistance(px, py) < blastRadius)
                        return new BotTrajectoryProbe(BotTrajectoryOutcome.Target, px, py);
                    return new BotTrajectoryProbe(BotTrajectoryOutcome.Terrain, px, py);
                }

                if (px < 0 || px >= mapWidth || py >= mapHeight)
                    return new BotTrajectoryProbe(BotTrajectoryOutcome.OutOfMap, px, py);
            }

            return new BotTrajectoryProbe(BotTrajectoryOutcome.None, x2, y2);
        }

        private static bool IntersectsAny(Rectangle projectile, IList<Rectangle> targetBounds)
        {
            if (targetBounds == null)
                return false;

            foreach (Rectangle rect in targetBounds)
            {
                if (projectile.IntersectsWith(rect))
                    return true;
            }
            return false;
        }
    }
}
