# Barry DDTank 3.4 DarkCastle Properties1 backport

Source oracle: `barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa`.

This batch adds exactly six live-DB-referenced DarkCastle NPC brains unlocked by the exact `Physics.Properties1` compatibility slot:

- `GameServerScript.AI.NPC.FourNormalCycLoneNpc` — NPC ID 4102
- `GameServerScript.AI.NPC.FourNormalFireNpc` — NPC ID 4107
- `GameServerScript.AI.NPC.FourHardCycLoneNpc` — NPC ID 4202
- `GameServerScript.AI.NPC.FourHardFireNpc` — NPC ID 4207
- `GameServerScript.AI.NPC.FourTerrorCycLoneNpc` — NPC ID 4302
- `GameServerScript.AI.NPC.FourTerrorFireNpc` — NPC ID 4307

Each candidate had exactly one compiler gap before this backport: `Living.Properties1`. The six files compile together with the DDTank 3.0 runtime-compatible .NET 3.5 C# compiler after adding the exact DDTank 3.4 state slot. No movement, damage, pathfinding, mission-controller, or packet API is emulated.
