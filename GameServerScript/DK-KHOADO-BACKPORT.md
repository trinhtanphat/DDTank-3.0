# DDTank 3.0 PvE script backport provenance

Source: `dk-khoado/Gunny-3.0@16e24b119f96b93b34ddb148f9a035f71a234e67` under `Server/Road/scripts`.

Selection: 46 source files absent from the canonical 96-file tree; all 46 compile-gated successfully alongside the canonical scripts against the DDTank 3.0 runtime API.

Of these, 23 classes are directly referenced by the live `Db_Tank_V30` Mission/NPC/PVE script columns as audited on 2026-09-18.

Files:
- `AI\Game\AigaH.cs`
- `AI\Game\AigaN.cs`
- `AI\Game\AigaS.cs`
- `AI\Game\AigaT.cs`
- `AI\Game\BBCopySimpleGame.cs`
- `AI\Game\BolactathanS.cs`
- `AI\Game\DomanhinhS.cs`
- `AI\Game\ExplorationHardGame.cs`
- `AI\Game\ExplorationNormalGame.cs`
- `AI\Game\ExplorationSimpleGame.cs`
- `AI\Game\ExplorationTerrorGame.cs`
- `AI\Game\GCGCHard.cs`
- `AI\Game\GCGCNormal.cs`
- `AI\Game\GCGCSimple.cs`
- `AI\Game\TrainingGame.cs`
- `AI\Messions\Aiga4002.cs`
- `AI\Messions\Aiga4003.cs`
- `AI\Messions\BLTC5001.cs`
- `AI\Messions\DCSM4001.cs`
- `AI\Messions\DCSM4011.cs`
- `AI\Messions\domanhinhS.cs`
- `AI\Messions\GCGC1161.cs`
- `AI\Messions\GCGC1162.cs`
- `AI\Messions\GCGC1261.cs`
- `AI\Messions\GCGC1262.cs`
- `AI\Messions\GCGC1263.cs`
- `AI\Messions\GCGC1361.cs`
- `AI\Messions\GCGC1362.cs`
- `AI\Messions\GCGC1363.cs`
- `AI\Messions\GCGC1364.cs`
- `AI\NPC\NullAi.cs`
- `AI\NPC\SeventhHardCageNpc.cs`
- `AI\NPC\SeventhHardFirstBoss.cs`
- `AI\NPC\SeventhHardHenNPC.cs`
- `AI\NPC\SeventhHardHouseAi.cs`
- `AI\NPC\SeventhHardMaleAi.cs`
- `AI\NPC\SeventhHardNpc.cs`
- `AI\NPC\SeventhHardSecondBoss.cs`
- `AI\NPC\SeventhNormalFirstBoss.cs`
- `AI\NPC\SeventhNormalHenNPC.cs`
- `AI\NPC\SeventhNormalHouseAi.cs`
- `AI\NPC\SeventhNormalMaleAi.cs`
- `AI\NPC\SeventhNormalNpc.cs`
- `AI\NPC\SeventhSimpleFirstBoss.cs`
- `AI\NPC\SeventhSimpleNpc.cs`
- `AI\NPC\ThirdSimpleKingThird.cs`
