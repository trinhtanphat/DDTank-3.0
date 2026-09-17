# DDTank 3.0 Parallel Instance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run DDTank-3.0 on VPS 182 beside the existing Gunny 5-year instance with isolated ports, databases, files, IIS state, and process lifecycle.

**Architecture:** Keep the existing `C:\Gunny` stack untouched and stage v3.0 entirely under `C:\Gunny-DDTank30`. Encode isolation as an executable PowerShell contract before changing runtime configs, then build/package, bootstrap isolated SQL databases, create a dedicated IIS binding, and start only binaries from the new deploy root.

**Tech Stack:** .NET Framework 4.x/MSBuild, ASP.NET/IIS, SQL Server Express, PowerShell, Git/GitHub.

**Spec:** `docs/superpowers/specs/2026-09-16-ddtank30-parallel-design.md`

## Global Constraints
- Existing `C:\Gunny` runtime must not be stopped, overwritten, or reconfigured.
- DDTank30 ports are exactly Game `9300`, Center `9302`, Fighting `9308`, HTTP `8083`.
- Runtime DB catalogs are exactly `Db_Tank_V30`, `Db_Count_V30`, `Db_7road_V30`.
- Do not rewrite item/template IDs merely because their numeric value equals an old port.
- Do not commit secrets or generated build artifacts.

---

### Task 1: Executable isolation contract
**Files:** Create `tests/ops/Test-DDTank30Isolation.ps1`; read runtime config files.
- [ ] Write assertions for required ports/catalogs and forbidden legacy runtime endpoints.
- [ ] Run the test and verify RED against untouched source.
- [ ] Commit only test/spec/plan scaffolding after RED evidence is captured.
### Task 2: Isolate service and web database configuration
**Files:** Modify `Center.Service/App.config`, `Fighting.Service/App.config`, `Game.Service/App.config`, `Game.Service/battle.xml`, `GameAdmin/Web.config`, `Tank.Request/Web.config`, `Tank.Request/Tank.Request/Web.config`, and deploy-facing Request config as required.
- [ ] Change only runtime endpoint/catalog values to the v3.0 isolation contract.
- [ ] Run `tests/ops/Test-DDTank30Isolation.ps1` and verify GREEN.
- [ ] Re-run the same test after `git diff --check`.
- [ ] Commit the config isolation change.

### Task 3: SQL bootstrap and validation
**Files:** Create `deploy/Initialize-DDTank30Databases.ps1` and `tests/ops/Test-DDTank30Databases.ps1`.
- [ ] Write DB test first: require all three `_V30` catalogs and reject writes to old catalogs.
- [ ] Run DB test and verify RED before initialization.
- [ ] Copy repository MDF/LDF to `C:\Gunny-DDTank30\data` and attach/copy under new catalog names without touching production files.
- [ ] Establish only the schemas/data actually required by count/road consumers.
- [ ] Run DB test and SQL smoke queries until GREEN.
- [ ] Commit scripts only, never database files or credentials.

### Task 4: Build and package isolated runtime
**Files:** Create `deploy/Build-DDTank30.ps1`; output outside Git to `C:\Gunny-DDTank30\runtime`.
- [ ] Add a packaging test that requires Center/Fighting/Game runtime binaries/configs in the isolated root.
- [ ] Verify packaging test RED before build script execution.
- [ ] Build known-good core solutions/projects while preserving documented baseline failures.
- [ ] Copy runtime files/configs/resources without modifying `C:\Gunny`.
- [ ] Verify package test GREEN and process binary hashes/paths.
- [ ] Commit build/package scripts only.
### Task 5: IIS and service startup isolation
**Files:** Create `deploy/Install-DDTank30IIS.ps1`, `deploy/Start-DDTank30.ps1`, `deploy/Stop-DDTank30.ps1`, and runtime smoke tests.
- [ ] Write smoke test requiring HTTP `8083` plus listeners `9300/9302/9308` owned by executables under `C:\Gunny-DDTank30`.
- [ ] Verify RED before creating/starting the new IIS site and services.
- [ ] Create a dedicated application pool/site on `8083`; do not alter existing bindings.
- [ ] Start Center, Fighting, and Game from the isolated runtime only.
- [ ] Verify smoke test GREEN and confirm legacy 9200/9202/9208 ownership remains unchanged.
- [ ] Commit deploy/start/stop scripts.

### Task 6: End-to-end verification and GitHub handoff
**Files:** Update docs with observed runtime evidence only if needed.
- [ ] Run isolation, database, package, HTTP, process, port, and build verification fresh.
- [ ] Run `git diff --check` and inspect `git status` for secrets/build artifacts.
- [ ] Confirm production Gunny processes and HTTP endpoint remain reachable.
- [ ] Push `agent/ddtank30-parallel-20260916` to GitHub.
- [ ] Create/merge through the normal branch workflow only after fresh verification; never force/bypass checks.