# Agent policy: Gunny endpoint/IP changes

This repository participates in the Gunny runtime managed by **trinhtanphat/Gunny-Infrastructure**.

For any task involving the server public IP/host (including migrations such as old-IP -> new-IP, IIS bindings, `Server_List`, launcher/web endpoints, or game/center/fight config endpoints):

- **Do not** manually search/replace the public IP in this repository as the migration procedure.
- **Do not** treat an IP literal in this repository as the canonical server address.
- The production authority is `C:\Gunny-Infra\server-instance.json` on **DESKTOP-603JII9**, field `publicHost`.
- Change the public IP through:
  `C:\Gunny-Infra\Set-GunnyPublicHost.ps1 -PublicHost <NEW_IP>`
- If this repository contains an endpoint that the infra tool does not update, fix **Gunny-Infrastructure** apply/test coverage first, then re-apply from the manifest. Do not leave a one-off drift patch here.
- DESKTOP-PHA1S90 is source-data/client-test only for Gunny; builds/deployments/runtime belong on DESKTOP-603JII9.

Read the root `AGENTS.md` in **trinhtanphat/Gunny-Infrastructure** for the full endpoint ownership contract.


## Project scope isolation

- A Gunny task may touch only Gunny/DDTank infrastructure, source, runtime, resources, launcher/client-test artifacts, and explicitly named supporting repos.
- Do not mutate unrelated projects such as QS3D, robot-boxing, ping-booster, invoice tooling, or other repositories merely because their worktrees/processes are visible on the same machine.
- In a Gunny conversation, `continue all` means continue all pending work **inside the current Gunny scope** unless the user explicitly names another project.
- Stale/background processes belonging to another project are unrelated machine state; ignore or leave them alone unless they directly block the Gunny task.
