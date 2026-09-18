# BaseGunnyII compatibility backport

Source: `trinhtanphat/BaseGunnyII@94df4bc8add1d605a098ae44e291015c453100fe`

This batch adds exactly one DB-referenced NPC AI class, `GameServerScript.AI.NPC.FiveNormalFirstNpc`, that is absent from the 169-script runtime.

Selection result on the current DDTank30 3.0 base: 118 BaseGunnyII candidates intersected the authoritative missing DB-script set; 117 were rejected by the current compiler/API gate and this single class survived. The 170-script combined gate is required before merge. No BaseGunnyII core assemblies or unrelated content are imported.
