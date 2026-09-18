# DDTank 3.4 brain-hook compatibility layer

Reference source: `barrydevp/ddt3.4server@73e189aef774b1f2eead70979c97b53619db07aa`.

This compatibility layer backports only the AI callback contract needed by DDTank 3.4-era NPC brains that are otherwise close to the DDTank 3.0 API. It does not import the 3.4 combat engine or any additional PvE script by itself.

Compatibility surface:
- `ABrain.OnDie()`
- `ABrain.OnAfterTakedBomb()`
- `ABrain.OnAfterTakedFrozen()`
- `ABrain.OnAfterTakeDamage(Living)`
- matching `Living` virtual hooks
- `SimpleNpc` / `SimpleBoss` forwarding to their brain
- delayed post-shot callbacks after bomb/freeze animation lifetime

Death dispatch intentionally differs from the 3.4 source. DDTank 3.0 schedules `Die(int delay)` through `LivingDieAction`, which later calls the actual `Die()`. The compatibility layer therefore dispatches `ABrain.OnDie()` only on the real living-to-dead transition inside `Die()`, preventing duplicate death callbacks and duplicate reward/state side effects.

Reference commit: `73e189aef774b1f2eead70979c97b53619db07aa`.
