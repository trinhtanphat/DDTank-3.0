# Gunny92 compatibility backport

Source: trinhtanphat/Gunny92-001-code-backup
Pinned commit: e53c3950f40a938fb0013be33230325e99397860

This batch adds four DB-referenced NPC AI classes that were already identified as compile-compatible in the Gunny92 additive analysis and were re-gated against the current 154-script DDTank30 base.

Added: ThirdHardBloomNpcS, ThirdNormalBloomNpcS, ThirdTerrorBloomNpcS, ThirdSimpleKingFirst.

Current-base gate: 158 total scripts, PASS first iteration, 4 compatible / 0 rejected. No Gunny92 core assemblies or incompatible 9.2 API hooks are imported.
