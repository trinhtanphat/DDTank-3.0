# Yutikeyux DDTank 3.4 compatibility backport

Source: `yutikeyux/ddt-34-csharp@b90215e199ae079c05eb290ed1cbf2a2fb4bdf5e`

This batch adds 11 NPC AI classes directly referenced by live `Db_Tank_V30` and absent from the 158-script runtime. An alternate implementation set was tested because representative yutikeyux sources differ materially from the previously rejected barrydevp variants.

Candidate sieve: 158 DB-missing classes found; 147 rejected by the current 3.0 API/compiler; 11 survived together with the 158 canonical base. No yutikeyux core assemblies or unrelated content are imported.
