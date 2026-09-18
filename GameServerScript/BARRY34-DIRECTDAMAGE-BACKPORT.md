# Barry DDTank 3.4 direct-damage backport

Source scripts: barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa
Behavior oracle: nguyenhuuninhneu/ddt3.8@3f5b4866572823dee7bd01c86c5488948ebd7b82

Imported live DB refs:
- FiveNormalSecondNpc - NPC_Info ID 5111
- FiveHardSecondNpc - NPC_Info ID 5211
- FiveTerrorSecondNpc - NPC_Info ID 5311

The compatibility surface is intentionally narrow. Existing RangeAttacking calls keep directDamage=false and retain distance attenuation. The new bool overload forwards the flag. When directDamage=true only the distance attenuation term is skipped, matching DDTank 3.8 LivingRangeAttackingAction.MakeDamage. Existing DDTank30 frost-removal behavior already matches the DDTank 3.8 overload default removeFrost=true.

The source oracle uses a C# 4 named argument. Canonical DDTank30 sources use the equivalent positional true so the runtime .NET 3.5 ScriptMgr compiler can compile them.
