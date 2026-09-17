# DDTank 3.0 Parallel Instance Design

## Goal
Deploy the DDTank-3.0 codebase on VPS 182 as a second Gunny version that can run concurrently with the existing 5-year-anniversary instance without sharing ports, mutable databases, IIS application state, logs, or process lifecycle.

## Isolation contract
- Existing 5-year instance under `C:\Gunny` is read-only for this work.
- DDTank 3.0 source/build/deploy root is `C:\Gunny-DDTank30`.
- Game service listens on `9300`.
- Center service listens on `9302`.
- Fighting service listens on `9308`.
- IIS HTTP binding is `8083`.
- Runtime databases are `Db_Tank_V30`, `Db_Count_V30`, and `Db_7road_V30`.
- GameAdmin keeps its bundled ASPNETDB/App_Data membership database.
- No DDTank30 launcher/request endpoint may point to the old `9200/9202/9208` service ports.

## Source and baseline
The source of truth is `trinhtanphat/DDTank-3.0`, branch `master` at baseline `05eef0a`. A dedicated clone outside `C:\Gunny\Source` is required because that shared source directory is concurrently refreshed by other VPS work.
## Baseline build evidence
`CenterServer.sln` and `FightingServer.sln` build successfully with the installed .NET 4 MSBuild. `GameServer.sln` has pre-existing Game.Test/MSTest targeting-reference failures. `Request.sln` and `AdminGunny.sln` have pre-existing VS2010 WebApplication-target failures on the VPS. These baseline failures are not part of the port-isolation change and must not be hidden or misreported as new regressions.

## Configuration changes
Runtime config changes are limited to the service configs, battle endpoint metadata, request/admin DB targets, and deploy/IIS automation. Test/tool configs may be normalized only when they are used by the verification scripts. Item template IDs that happen to equal 9202 are data and must not be changed.

DDTank30 runtime database connections use Windows Integrated Security and contain no embedded SQL user/password material. Logs and generated deployment files live under `C:\Gunny-DDTank30`, not under `C:\Gunny`.

## Database strategy
The authoritative runtime database source is the external DDTank 3.0 source cache `dk-khoado/Gunny-3.0` pinned by Git commit and backup SHA256. `Server\DB\Tank.bak` restores to isolated `Db_Tank_V30` (Edition 21000; 189 map rows) and `Server\DB\count.bak` restores to isolated `Db_Count_V30`; both are verified before restore and existing `_V30` databases are rollback-backed up before replacement. Combat assets come from the same pinned source (`Server\Fight\map`, 251 files, plus bomb/language payload), so database and server-map lineage stay coherent. Production `Db_Tank`/`Db_Count` are never renamed, detached, overwritten, or used as writable backing stores for v3.0.

## Verification
A PowerShell isolation test parses the runtime config files and fails if reserved ports or old database catalogs remain. Build verification reruns Center/Fighting and the buildable Game.Server project path. Runtime verification checks port ownership, SQL database names, process command paths, IIS binding 8083, HTTP request health, and confirms the old instance processes/ports remain present.