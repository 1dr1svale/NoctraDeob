# Luraph v15.2 notes

What was added to this tool for v15.2, what it found, and what is still open.
Two test scripts are in `samples/`:

- `luraph_v15_2_sample.luau`: the v15.2 sample from the luraph-v15.2-deobf repo.
- `luraph_v15_1_script.lua`: your v15.1 script, recovered from `studio/instrumented.luau`
  by removing the hooks (re-instrumenting it reproduces that file byte for byte).

## What changed

| File | Change |
|---|---|
| `src/vmmap.js`, `core/obfuscators/luraph_v15/driver.py` | The instrumentation records the inner maker's arguments (`__m1`..`__mN`, `__mn`) for three-level closure makers. |
| `core/obfuscators/luraph_v15/devirt.py` | `VMModel.maker_args` uses those numbers instead of binding every inner-maker parameter to the upvalue list. Closures that were never created at run time fall back to the numbers at their creation site (`dump.maker_site`). |
| `runtime/envlog.luau` | `cfg.cstack_pcall`: a `pcall`/`ypcall` that refuses to run its function at the C-call limit, like Roblox. `IsA`, `IsDescendantOf`, `IsAncestorOf` answer correctly for `game`, `workspace` and services. |
| `src/driver.js`, `core/obfuscators/luraph_v15/driver.py` | `cstack_pcall` is on for a v15.2+ header. For other scripts it is tried once when an anti-tamper trap is reached, and kept only if the trace gets longer. The "run stopped before the script's own code" note is no longer written when statements follow Luraph's probe block. Byte strings repeated in the lifted output are written once (`luraphData`). |
| `src/optrace.js` | New. Records every VM instruction and prints the last ones before a stall or error. |

`--cfg-json '{"cstack_pcall":false}'` (or `true`) overrides the automatic choice.

## The v15.2 closure maker

```
[83] = function(t, W, m, a, X, V, E, E, c, k, _, R, Y, F)      -- per proto: VM object, frame size W, entry pc m, arrays
    local C, y, A, ... = t[7], t.ZQ, ...
    return function(Z, Z, Z, J, i, U)                          -- per closure: seeds Z (3rd) and J, upvalues i
        local U, S, z, ... = C, y, A, ...
        return function(...)                                   -- the interpreter
            ...
            W, Q, Wh, mh = m, J, Z, E                          -- pc, key state, key state, mode
```

The two seeds feed the handlers that decrypt operands as they run, so without them the
lifter could not follow a single function (`value <UpList> in an expression`). The chunk
has four VMs of this shape (`[125]`, `[22]`, `[56]`, `[83]`); the sample's script runs in
the last one, and its main function (proto 1) contains Luraph's startup checks followed by
the script's own code.

Closures can also be plain Lua functions made by small helpers on the VM object
(`[53]`, `[28]`, `[47]`, `[75]`, `[113]`, ...). They show up as `luraph_runtime<N>` in the output.

## The depth probe (why v15.2 looped forever)

Luraph recurses through an `__index` metamethod. At depth 198 it expects, as in Roblox:

1. `pcall(A)` runs `A`,
2. one more `__index` call inside `A` fails with "C stack overflow",
3. `pcall(function() pcall(B) end)` does not run `B`.

The bundled Luau never limits nested `pcall`, so `B` ran, the check failed and the script
entered its crash routine (function #6: scrambles its bytecode buffer in an endless loop).
The old behaviour of disabling that function only hid the failure.
Your v15.1 script has the same probe: its traps #8 and #7 are the same thing.

`cstack_pcall` checks the limit with two nested coroutine resumes, which fail exactly when
one more C call is not allowed. `xpcall` is not changed: no script tested its behaviour there.

## Finding the next divergence

```
node src/optrace.js <script> --last 400                       # last 400 VM instructions before the failure
node src/optrace.js <script> --before-function 6 --last 3000  # what ran before function #6 was first entered
```

Lines are `P<function> L<loop> op<opcode> pc<pc>`. Match them with
`python core/obfuscators/luraph_v15/devirt.py <script> <protos.json> --chunk <chunk> --raw <function>`
(set `PYTHONPATH=core`), or read the lifted function with `--lift <function>`.
`--cfg-json '{"ptrace":true}'` on `deob.js` prints proxy-level events.

## Status (bundled Linux Luau, same results as the Windows build for the old tool)

| Script | Before | Now |
|---|---|---|
| v15.2 sample | endless loop after the first Path2D block; 1 function, nothing lifted | passes Luraph's startup and the script's own PC-R01 and PC-R02 checks; stops at `PC-E01`; 38 functions lifted, 24 unlifted blocks |
| v15.1 script | traps #8 and #7 disabled, run "finished" without reaching the script; 35 functions, 7 unlifted blocks | passes the probe without disabling anything; stops later with a decode error (`Script:3: buffer access out of bounds`); 35 functions, 5 unlifted blocks |

## Update: scripts that hung at "devirtualizing (round 1)"

Tested with a 1.6 MB v15.1 script (loader main function: about 9,000 instructions, 61,000 blocks after state duplication).

| File | Change |
|---|---|
| `core/structure.py` | `merge_equivalent` used a refinement loop that split one class per pass (quadratic: hours on this script). It now refines incrementally (`Partition`); the result is the same partition. `dominates` is constant-time. State machines with more than 800 states are written as a two-level ladder, because one `elseif` chain that long is not valid Luau (parser nesting limit). |
| `core/obfuscators/luraph_v15/devirt.py` | Prints a progress line every 30 s while lifting (`DEVIRT_HEARTBEAT=<seconds>`, `0` turns it off). |
| `src/path2dprobe.js`, `src/driver.js` | When the run stops inside Luraph's loader, a probe script is written next to the input (`<name>.path2d_probe.lua`). The idle-loop allowance grows with the script size (24 checks, plus one per 32 KB above 768 KB). |
| `src/harness.js` | The `<name>.path2d` reader accepts lines copied from a console (spaces instead of a tab, a timestamp in front). |

Checked: every function of that script lifts to the same text as before the change, and the v15.2 sample lifts to the same 12 MB text from the same capture. The whole run now takes about 4.5 minutes instead of not finishing.

## The Path2D key: zero-tangent control points (fixed)

The loader feeds about 200 environment answers into a byte array (`r98`/`r99` in the lifted main function), derives an RC4 key from the first 256 bytes and decrypts the real script with it. A wrong answer does not fail a check: it gives a wrong key, the decrypted data is garbage, and the run ends with `buffer.create` / `buffer access out of bounds` errors. Until that key is right there are no script constants to decode, which is why the constant counters stay at 0.

Compared with the v15.2 sample (which decrypts correctly here), everything in the key was the same kind of answer except one: both failing v15.1 scripts give Path2D a control point whose tangent is exactly zero. A Path2D segment is a cubic Bezier whose two inner control points are `position + tangent`; a zero tangent just puts that control point on the anchor, so the segment is still a cubic. The old model mistook a zero tangent for a lower-degree curve (a line or a quadratic), which changes the position, tangent and arc length along the whole segment, so every answer taken from it was slightly wrong and the key was wrong.

`runtime/envlog.luau` `p2dModel.segments` now always builds the four-point cubic `{ P0, P0+rightTangent, P2+leftTangent, P3 }`. Checks:

- The v15.2 sample has no zero tangents, so its segments were already cubics; its answers and its whole lifted output are byte-for-byte unchanged (it still decrypts correctly).
- For the v15.1 scripts the key now derives correctly: the `buffer access out of bounds` / `size out of range` errors (the signature of a garbage decrypt) are gone, and the run gets past the loader into the decrypted script, where it stops at an environment gap instead (`attempt to call a number value`, `attempt to perform arithmetic on Instance`). Those are the next thing to work on, not a key problem.
- The fixed segment was checked against a cubic Bezier worked out by hand: at the midpoint the model gives `(27.8750005, -8.46874961)` and the hand value is `(27.875, -8.46875)`, equal at float32. The same cubic code decrypts the v15.2 sample, so it matches the engine bit for bit.

The parameter-based answers (`GetPositionOnCurve`, `GetTangentOnCurve`) are now exact. `GetLength` and the arc-length answers (`...ArcLength`) are still numerical approximations (adaptive length, RK4 inversion); they are good enough that the v15.2 sample decrypts, but a script that feeds all 32 bits of an arc-length answer into the key could still need the real numbers. To get them, run `<name>.path2d_probe.lua` once in Roblox (it only creates a ScreenGui, Frame and Path2D, repeats the script's Path2D calls and prints the results), save the printed lines as `<name>.path2d` next to the script, and run the tool again. For a large script add `--budget 120 --timeout 300 --cfg-json "{\"spin\":400}"` so the long decode loop is not taken for a hang.

## Open

- **`PC-E01` / `PC-E02` (the v15.2 sample's own executor check).** It calls
  `getrawmetatable(setmetatable({}, { __metatable = "locked" }))` and `setrawmetatable`. The
  runtime cannot read a protected metatable: Luau has no raw `getmetatable`, and wrapping
  `setmetatable` to remember metatables is the kind of wrapper the depth probes punish.
  The clean fix is a raw-metatable function added in `build_luau.py`.
- **v15.1 script, after the instance-tree probe.** The last thing it does is `debug.info(f, "sl")`
  on about 100 of its functions (answer: `Script`, `3`), then a buffer is created with a bad
  size: a wrong key from an earlier answer. Not found yet.
- **Lifter, v15.2.** 74 "symbolic value store into proto array" (handlers that decrypt
  operands with a key that depends on run-time values) and 49 "symbolic next pc/mode"
  (computed jumps of the flattened control flow). Where constants are not decoded the VM's
  own decrypt code is inlined into the output, which is why it is large (5 MB) and noisy.
  The new numeric `for` state tables (`{ index, step, limit, previous, ... }`) are not
  turned back into loops.
- **Upvalues of closures made by the v15.2 closure instruction** (descriptor triples in
  `ah[-2]`) are not bound to the parent's registers: they print as `upv<N>`.
- The repo's line that strips a leading `getgenv().SCRIPT_KEY = ...` was not ported: this
  tool runs the script with the line in place, which keeps the key visible to the script.
