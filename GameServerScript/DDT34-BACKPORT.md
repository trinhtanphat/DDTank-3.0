# DDTank 3.4 compatibility backport

Source oracle: barrydevp/ddt3.4server
Pinned commit: 73e189aef774b1f2eead70979c97b53619db07aa

This batch adds only 12 NPC AI classes directly referenced by live Db_Tank_V30 and compile-clean with the 142 canonical DDTank30 scripts against current 3.0 runtime assemblies.

Selection: 307 DB refs; 206 absent from 142-script runtime; 151 found in 3.4; isolated group gates rejected 139; survivors are 9 EvilTribe + 3 TrainingGame; combined 154-script gate passed first iteration with 12 compatible and 0 rejected.

No 3.4 core assemblies, controllers, maps, configs, or unrelated content are imported.
