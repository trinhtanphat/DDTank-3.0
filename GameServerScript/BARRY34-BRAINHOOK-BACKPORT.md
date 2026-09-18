# Barry DDTank 3.4 brain-hook backport

Source oracle: barrydevp/ddt3.4server
Pinned commit: 73e189aef774b1f2eead70979c97b53619db07aa

This batch adds exactly five live-DB-referenced NPC brain classes that compile against DDTank30 only after the minimal DDTank 3.4 brain-hook compatibility layer is present.

Imported classes:
- GameServerScript.AI.NPC.EighthPaoNpc (NPC_Info ID 11105)
- GameServerScript.AI.NPC.EighthSmallBat (NPC_Info ID 10102)
- GameServerScript.AI.NPC.SixHardThirdBadNpcAi (NPC_Info ID 6235)
- GameServerScript.AI.NPC.SixNormalThirdBadNpcAi (NPC_Info ID 6135)
- GameServerScript.AI.NPC.SixTerrorThirdBadNpcAi (NPC_Info ID 6335)

All five are standalone ABrain implementations with no dependency on other missing Barry34 script classes. From 128 Barry34 candidates matching remaining DB gaps, these five survived the clean compiler gate and 123 were rejected.

No DDTank 3.4 engine assembly, mission controller, map, config, or rejected script is included.
