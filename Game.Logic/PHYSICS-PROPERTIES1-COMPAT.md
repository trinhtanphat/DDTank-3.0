# Physics Properties1 compatibility

Source oracle: `barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa`.

DDTank 3.4 defines `Physics.Properties1` as a process-local integer state slot backed by a private integer field. It has no database binding, no packet serialization, and defaults to `0`.

DDTank 3.0 lacked this state slot. This compatibility change backports only the exact integer field plus getter/setter. It does not add `Properties2`, `Properties3`, or any other DDTank 3.4 engine API.

The purpose is to preserve original AI state semantics for DB-referenced scripts that already compile against every other DDTank 3.0 API.
