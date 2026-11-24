import os
import re
import sys
import time

import harness
import traceout as trace
from obfuscators.luraph_v15 import ui

here = os.path.dirname(os.path.abspath(__file__))
max_reruns = 12
spin_checks = 24

def _tail(err, n=300):
    text = " ".join((err or "").split())
    head = text.split(":", 1)[0]
    if head.startswith(("no reply within", "harness process exited")) and len(text) > n:
        return head + ": ..." + text[-n:]
    return text[-n:]

def _is_luau(text):
    try:
        import localfuncs
        localfuncs._ast(text)
        return True
    except Exception:
        return False

def patch_spin(src):
    inj = "__spin.n=__spin.n+1;if __spin.n>=__spin.step then __spin.f()end;"
    out = re.sub(
        r"while true do (?:[A-Za-z_][A-Za-z0-9_]*\[\d+\]=[A-Za-z_][A-Za-z0-9_]*;\s*)?(?:local )?[A-Za-z_][A-Za-z0-9_]*(?:,[A-Za-z_][A-Za-z0-9_]*)*=(?:[A-Za-z_][A-Za-z0-9_]*,)?\(?[A-Za-z_][A-Za-z0-9_]*\[[A-Za-z_][A-Za-z0-9_]*\]\)?;?(?=\s*(?:if|local)\b)",
        lambda m: (m.group(0) if m.group(0).endswith(";") else m.group(0) + ";") + inj,
        src,
    )
    out = re.sub(
        r"repeat (?:[A-Za-z_][A-Za-z0-9_]*\[\d+\]=[A-Za-z_][A-Za-z0-9_]*;\s*)?(?:local )?[A-Za-z_][A-Za-z0-9_]*(?:,[A-Za-z_][A-Za-z0-9_]*)*=(?:[A-Za-z_][A-Za-z0-9_]*,)?\(?[A-Za-z_][A-Za-z0-9_]*\[[A-Za-z_][A-Za-z0-9_]*\]\)?;?(?=\s*(?:if|local)\b)",
        lambda m: (m.group(0) if m.group(0).endswith(";") else m.group(0) + ";") + inj,
        out,
    )
    return out

string_literal = re.compile(r'"[^"\\\n]*(?:\\.[^"\\\n]*)*"')
big_line = 8192
big_literal = 4096

def hoist_repeated_literals(text):
    lines = text.split("\n")
    seen = {}
    order = []
    for i, line in enumerate(lines):
        if len(line) < big_line:
            continue
        for m in string_literal.finditer(line):
            lit = m.group(0)
            if len(lit) >= big_literal:
                if lit not in seen:
                    seen[lit] = []
                    order.append(lit)
                seen[lit].append(i)
    repeated = [lit for lit in order if len(seen[lit]) > 1]
    if not repeated:
        return text
    top_locals = sum(len(m.group(1).split(",")) for m in re.finditer(r"^local ([\w, ]+)", text, re.M))
    if top_locals >= 190:
        return text
    name = "luraphData"
    while re.search(r"\b%s\b" % name, text):
        name += "_"
    for n, lit in enumerate(repeated, 1):
        ref = "%s[%d]" % (name, n)
        for i in set(seen[lit]):
            lines[i] = lines[i].replace(lit, ref)
    decl = ["local %s = {" % name]
    decl += ["\t%s," % lit for lit in repeated]
    decl += ["}", ""]
    return "\n".join(decl + lines)

def cstack_wanted(source):
    from obfuscators.luraph_v15 import header
    m = header.search(source[:4096])
    if not m:
        return False
    major, minor = int(m.group(1)), int(m.group(2) or 0)
    return major > 15 or (major == 15 and minor >= 2)

def patch_chunk(src, tmpdir):
    path = os.path.join(tmpdir, "_chunk_%s.luau" % harness.chunk_key(src))
    with open(path, "w", encoding="latin-1", newline="") as f:
        f.write(src)
    try:
        return patch_entries(src, path)
    except Exception as e:
        print("[!] could not instrument chunk (%s)" % e, file=sys.stderr)
        return src
    finally:
        os.remove(path)

def patch_entries(source, path):
    from obfuscators.luraph_v15 import vmmap
    root = vmmap.load_ast(path)
    lines = source.split("\n")
    edits = []
    for l1, c1, pv in vmmap.closure_entries(root):
        k = "(%s or __pid)" % pv
        edits.append((l1, c1, ("if not __pid[{k}] then __pid.n=__pid.n+1;__pid[{k}]=__pid.n;end;"
                               "if __parg1 and not __parg1[__pid[{k}]] and type((...))==\"number\" then __parg1[__pid[{k}]]=(...) end;"
                               "__ent.n=__ent.n+1;__ent[__ent.n%64]=__pid[{k}];__plast[__pid[{k}]]=__ent.n;"
                               "if __skipp[__pid[{k}]] then return end;").format(k=k)))

    tag = harness.chunk_key(source)
    for info in vmmap.maker_info(root):
        (l2, c2), var, pv = info["at"], info["var"], info["proto"]
        c3 = info.get("curried3")
        if c3:
            f3, f2, f1 = c3["f3"], c3["f2"], c3.get("f1")
            f3_l0, f3_c0, _, _ = vmmap.loc(f3["body"]["body"][0])
            f3_params = list(dict.fromkeys(
                a["name"] for a in (f3.get("args") or []) if a.get("name") and a["name"] != "..."
            ))
            f3_cap = ",".join("%s=%s" % (nm, nm) for nm in f3_params)
            head_code = ("local __pv={%s};if __pa and __pa.n<8192 then __pa.n=__pa.n+1;"
                         "__pa[__pv]={__seq=__pa.n,__maker=\"%s@%d,%d\",%s} end;"
                         % (f3_cap, tag, l2, c2, f3_cap))
            edits.append((f3_l0, f3_c0, head_code))
            f2_body = (f2.get("body") or {}).get("body") or []
            last_idx = {}
            for i, a in enumerate(f2.get("args") or []):
                if a.get("name") and a["name"] != "...":
                    last_idx[a["name"]] = i
            margs = "".join("__pa[__pv].__m%d=%s;" % (i + 1, nm) for nm, i in last_idx.items())
            if f2_body and margs:
                f2_l0, f2_c0, _, _ = vmmap.loc(f2_body[0])
                edits.append((f2_l0, f2_c0, "if __pa and __pa[__pv] and not __pa[__pv].__mn then __pa[__pv].__mn=%d;%s end;"
                              % (len(f2.get("args") or []), margs)))
            if c3.get("kind") == "named":
                r1_l, r1_c, _, _ = vmmap.loc(c3["retStmt"])
                r2_l, r2_c, _, _ = vmmap.loc(c3["f2Ret"])
                u_name, z_name = c3["uName"], c3["zName"]
                edits.append((r1_l, r1_c, "__pf[%s]=__pv;__pk[__pv]=%s;" % (u_name, u_name)))
                edits.append((r2_l, r2_c, "__pf[%s]=__pv;__pk[__pv]=%s;" % (z_name, z_name)))
            else:
                fn_l1, fn_c1, fn_l2, fn_c2 = vmmap.loc(f2)
                edits.append((fn_l1, fn_c1, "(function(__mk)__pf[__mk]=__pv;__pk[__pv]=__mk;return __mk end)("))
                edits.append((fn_l2, fn_c2, ")"))
                if f1:
                    f1_l1, f1_c1, f1_l2, f1_c2 = vmmap.loc(f1)
                    edits.append((f1_l1, f1_c1, "(function(__fn)__pf[__fn]=__pv;return __fn end)("))
                    edits.append((f1_l2, f1_c2, ")"))
            continue
        code = " __pf[%s]=%s " % (var, info.get("pf_key", pv))

        cap = "".join("__pa[%s].%s=%s;" % (pv, nm, nm) for nm in info["captures"])

        code += ("if __pa and not __pa[%s] then __pa[%s]={};__pa.n=__pa.n+1;__pa[%s].__seq=__pa.n;"
                 "__pa[%s].__maker=\"%s@%d,%d\";__pk[%s]=%s;%s end "
                 % (pv, pv, pv, pv, tag, l2, c2, info.get("pf_key", pv), var, cap))
        edits.append((l2, c2, code))
    for l, c, code in sorted(edits, reverse=True):
        lines[l] = lines[l][:c] + code + lines[l][c:]
    return "\n".join(lines)

def devirtualize(job, ppath, dpath, cfg, rerun, chunk_paths=(), live=None, devirt=None):
    if devirt is None:
        from obfuscators.luraph_v15 import devirt
    args = job.args
    requested = set()
    last_bufs = ""
    text = None
    rounds = args.devirt_rounds

    quick = not os.environ.get("DEVIRT_FULL_ROUNDS")
    cache = devirt.WalkCache()
    t0 = time.time()
    last_errors = None
    best = None
    budget = float(os.environ.get("DEVIRT_BUDGET", "1200"))
    patience = int(os.environ.get("DEVIRT_PATIENCE", "4"))
    behind = 0
    for rnd in range(1, rounds + 1):
        t1 = time.time()
        if time.time() - t0 > budget:
            if best is not None:
                ui.note("stopped the constant rounds after %.0fs (DEVIRT_BUDGET): keeping the best lift"
                        % (time.time() - t0))
                break
            quick = False

        if quick and (last_errors == 0 or (rnd == 1 and (live and live()) is not None)):
            full = True
        else:
            full = not quick

        if not full and quick:
            stats, reqs, bufs = devirt.run_big_stack(devirt.collect_requests, job.source_path, ppath, chunk_paths, cache,
                                                     live and live())
            last_errors = stats.get("errors", 0)
            new = reqs - requested
            ui.note("round %d scan: %d functions, %d blocks still raw, %d new constants to decode%s (%.1fs)"
                    % (rnd, stats["functions"], stats["errors"], len(new),
                       ", %d decoded live" % stats["fetched"] if stats.get("fetched") else "",
                       time.time() - t1))
            if os.environ.get("DEVIRT_REQS"):
                for rq in sorted(new):
                    print("[*]     request %s" % rq, file=sys.stderr)
            if (not new and (not (requested | reqs) or devirt.same_patches(last_bufs, bufs))) or rnd == rounds:
                full = True
        if full:
            ui.step("Devirtualizing", "round %d" % rnd)
            t1 = time.time()
            text, stats, reqs, bufs = devirt.run_big_stack(devirt.lift_program, job.source_path, ppath, chunk_paths,
                                                           live and live())
            new = reqs - requested
            devirt.save_count(ppath, stats["functions"])
            ui.ok("%d functions recovered, %d blocks still raw   %s"
                  % (stats["functions"], stats["errors"],
                     ui.gray("%d jumps, %d constants to decode, %.1fs" % (stats["fallbacks"], len(new), time.time() - t1))))
            if text:
                tcats = {}
                for msg in re.findall(r'error\("devirt: (.*?)"\)', text):
                    c = devirt.fail_category(msg)
                    tcats[c] = tcats.get(c, 0) + 1
                if tcats:
                    ui.note("raw blocks by cause: "
                            + ", ".join("%s %d" % (c, n) for c, n in sorted(tcats.items(), key=lambda kv: -kv[1])))
            score = (0 if text and _is_luau(text) else 1, stats["errors"], -stats["functions"])
            if text and (best is None or score <= best[0]):
                best = (score, text, rnd)
                behind = 0
            else:
                behind += 1
            if (not new and (not (requested | reqs) or devirt.same_patches(last_bufs, bufs))) or rnd == rounds:
                break
            if time.time() - t0 > budget:
                ui.note("stopped the constant rounds after %.0fs (DEVIRT_BUDGET): keeping the best lift"
                        % (time.time() - t0))
                break
            if best is not None and behind >= patience:
                ui.note("%d rounds behind the best lift: stopping the constant rounds" % behind)
                break
            if quick:
                ui.note("the full lift needs more constants: continuing with full lifts")
                quick = False
        requested |= reqs
        last_bufs = bufs
        c = dict(cfg)
        c["force_req"] = ";".join(sorted(requested))

        c["force_buf"] = bufs
        t1 = time.time()
        body, err = rerun(c)
        if os.environ.get("DEVIRT_TIMING"):
            print("[*]   constant run %.1fs (total %.0fs)" % (time.time() - t1, time.time() - t0), file=sys.stderr)
        if body is None:
            print("[!] constant request run failed: " + _tail(err, 500), file=sys.stderr)
            break
        m = re.search(re.escape(harness.mark("PROTOS ")) + r"([^\n]*)\n", body)
        if not m or m.group(1).startswith("error:"):
            print("[!] constant request run gave no protos", file=sys.stderr)
            break
        with open(ppath, "w", encoding="utf-8", newline="\n") as f:
            f.write(m.group(1))
    if best is not None and text is not best[1]:
        ui.note("round %d gave the cleanest lift (%d blocks still raw, %d functions): using it"
                % (best[2], best[0][1], -best[0][2]))
        text = best[1]
    header = job.credit_header()
    prefix = (header + "\n") if header else ""
    if text is None:
        sys.exit("[!] no devirtualized output was produced: the constant-request run failed "
                 "before the first full lift (see the error above); re-run with "
                 "DEVIRT_FULL_ROUNDS=1 to lift the first round without extra constant runs")
    job.write(dpath, prefix + hoist_repeated_literals(devirt.finish_text(text)) + "\n")

def run(job):
    args = job.args
    devirt_on = not args.no_devirt
    source = job.source
    try:
        patched = source if args.no_hooks else patch_entries(source, job.source_path)
    except SyntaxError as e:
        sys.exit("[!] the input is %s: the file is damaged (truncated, or mangled by a paste/upload); "
                 "nothing to run" % e)
    cache_path = harness.load_p2d_cache(job.input, args.studio)
    runner = harness.Runner(job)
    bridge = runner.bridge

    skip = []

    spin = not os.environ.get("DEOB_SPIN_LATE")
    if spin:
        patched = patch_spin(patched)
    chunks = {}
    raw_chunks = {}
    body = None
    trapped = None
    cfg = None
    cstack = cstack_wanted(source)
    cstack_fallback = None
    for attempt in range(1, args.max_runs + 1):
        cfg = {"time_budget": args.budget, "dump_strings": args.strings, "executor": args.executor,
               "skip_protos": skip}
        if cstack:
            cfg["cstack_pcall"] = True
        if args.input_text is not None:
            cfg["input_text"] = args.input_text
        if args.no_fold:
            cfg["fold"] = False
        if devirt_on:
            cfg["devirt"] = True
        harness.user_cfg(args, cfg)
        if spin:
            cfg["spin"] = spin_checks
        print("[*] tracing %s (run %d)..." % (job.input, attempt), file=sys.stderr)
        body, err = runner.run(patched, cfg, chunks)
        if body is None and not spin and err.startswith("timed out") and not bridge:
            print("[*] the script never finished; re-running with a spin watchdog", file=sys.stderr)
            spin = True
            patched = patch_spin(patched)
            chunks = {k: patch_spin(v) for k, v in chunks.items()}
            cfg["spin"] = spin_checks
            body, err = runner.run(patched, cfg, chunks)
        if body is None:
            harness.save_raw(args.raw)
            runner.finish()
            sys.exit("[!] " + err)
        body = harness.take_p2d(body, cache_path, bridge is not None)
        found, body = harness.take_chunks(body)
        added = 0
        for key, src in found:
            if key not in chunks and args.no_hooks:
                chunks[key] = src
            elif key not in chunks:
                raw_chunks[key] = src
                chunks[key] = patch_chunk(src, job.outdir)
                if spin:
                    chunks[key] = patch_spin(chunks[key])
                added += 1
        if added:
            print("[*] script loadstring'd %d new VM chunk(s); instrumenting and re-running" % added, file=sys.stderr)
            continue
        trig = re.search(re.escape(harness.mark("TRIGGER ")) + r"(\d+)", body)
        if cstack_fallback is not None:
            before, cstack_fallback = cstack_fallback, None
            if trace.stmt_count(body) <= trace.stmt_count(before[0]):
                print("[*] the C-stack limit on pcall did not get the script further: turning it off again",
                      file=sys.stderr)
                cstack = False
                body, harness.last_raw[0] = before[0], before[1]
                trapped = (before[0], before[1])
                print("[*] anti-tamper trap reached through function #%d; disabling it and re-running" % before[2],
                      file=sys.stderr)
                skip.append(before[2])
                continue
            print("[*] the C-stack limit on pcall got the script past the trap: keeping it on", file=sys.stderr)
        if trig and not cstack and not skip:
            print("[*] anti-tamper trap reached: re-running with the C-stack limit on pcall "
                  "(Luraph v15.2 depth probe)", file=sys.stderr)
            cstack_fallback = (body, harness.last_raw[0], int(trig.group(1)))
            cstack = True
            continue
        if trapped is not None and trace.stmt_count(body) < trace.stmt_count(trapped[0]):
            print("[*] disabling function #%d made the script stop earlier: it is the script's own "
                  "crash check; keeping run %d" % (skip[-1], attempt - 1), file=sys.stderr)
            body, harness.last_raw[0] = trapped
            skip.pop()
            break
        if not trig:
            break
        trapped = (body, harness.last_raw[0])
        pid = int(trig.group(1))
        if pid in skip:
            print("[!] anti-tamper trigger %d fired again; giving up on reruns" % pid, file=sys.stderr)
            break
        print("[*] anti-tamper trap reached through function #%d; disabling it and re-running" % pid,
              file=sys.stderr)
        skip.append(pid)

    run_text = harness.trace_text(body)
    body = harness.p2d_miss(body, cache_path)
    if not devirt_on:
        runner.finish()
    harness.save_raw(args.raw)
    body = re.sub(re.escape(harness.mark("TRIGGER ")) + r"\d+\n?", "", body)
    protos_json, body = trace.take_line(body, "PROTOS")
    force, body = trace.take_line(body, "FORCE")
    if force is not None and devirt_on:
        ui.note("constants decoded on request: " + force)
    unscrambled, body = trace.take_line(body, "UNSCRAMBLED")
    if unscrambled is not None and devirt_on:
        print("[*] %s function(s) scrambled by the script's LPH_CRASH(): dumped as they were "
              "when first created" % unscrambled, file=sys.stderr)
    body, strings = trace.take_strings(body)

    notes = ["anti-tamper trap functions disabled: %s" % ", ".join("#%d" % p for p in skip)] if skip else []
    text = trace.header(job.input, notes) + body

    def write_trace():
        job.write(job.trace_path, trace.render(text, args))

    if not (devirt_on and not job.debug):
        write_trace()
    if strings is not None:
        job.write(job.path(".strings.txt"), strings)
    dpath = job.path(".devirt.luau")
    if protos_json is not None:
        ppath = job.path(".protos.json")
        if protos_json.startswith("error:"):
            print("[!] proto capture failed: " + protos_json, file=sys.stderr)
        else:
            job.write(ppath, protos_json)
            if devirt_on:
                chunk_paths = [job.write(job.path(".chunk_%s.luau" % key), src, encoding="latin-1")
                               for key, src in raw_chunks.items()]
                lift(job, runner, patched, cfg, chunks, run_text, ppath, dpath, chunk_paths)
    runner.finish()
    trace.status_line(body)
    if devirt_on and os.path.exists(dpath):
        with open(dpath, encoding="utf-8", errors="replace") as f:
            lifted = f.read()
        nil_calls = lifted.count("(nil)(")
        if nil_calls < 50 or nil_calls * 100 < lifted.count("\n"):
            return dpath
        print("[!] the devirtualized output is broken (%d calls of nil); writing the behaviour trace "
              "instead" % nil_calls, file=sys.stderr)
        if not job.debug:
            os.remove(dpath)
        write_trace()
        return job.trace_path
    if devirt_on:
        print("[!] devirtualization produced no output; writing the behaviour trace instead", file=sys.stderr)
        if not os.path.exists(job.trace_path):
            write_trace()
    return job.trace_path

def lift(job, runner, patched, cfg, chunks, run_text, ppath, dpath, chunk_paths, devirt=None):
    args = job.args
    bridge = runner.bridge
    server = [None]
    synced = [False]
    if not bridge and not os.environ.get("DEOB_NO_SERVE"):
        hs = harness.HarnessServer(runner.luau, patched, cfg, chunks)
        server[0] = hs
        first, err = hs.reply(args.timeout)
        server.append(True)
        if first is not None and harness.same_trace(harness.trace_text(first), run_text):
            synced[0] = True
            m = re.search(re.escape(harness.mark("PROTOS ")) + r"([^\n]*)\n", first)
            if m and not m.group(1).startswith("error:"):
                with open(ppath, "w", encoding="utf-8", newline="\n") as f:
                    f.write(m.group(1))
        else:
            if first is None:
                print("[!] the long-lived harness failed: %s; running the script once per round instead" % _tail(err), file=sys.stderr)
            hs.close()
            server[0] = None

    def live():
        hs = server[0]
        if hs is None or not synced[0] or os.environ.get("DEOB_NO_FETCH"):
            return None
        return lambda paths, bufs: hs.fetch(paths, bufs, args.timeout)

    def rerun(c):
        synced[0] = False
        if bridge:
            return runner.run(patched, c, chunks)
        hs = server[0]
        if hs is not None and not server[1]:
            server[1] = True
            first, err = hs.reply(args.timeout)
            if os.environ.get("DEOB_SERVE_DIFF") and first is not None:
                for nm, tx in (("run", run_text), ("served", harness.trace_text(first))):
                    with open(job.path(".serve_%s.txt" % nm), "w", encoding="utf-8") as f:
                        f.write(tx)
            if first is None or not harness.same_trace(harness.trace_text(first), run_text):
                print("[!] the long-lived harness %s; running the script once per round instead"
                      % ("failed: " + _tail(err) if first is None else "traced differently"),
                      file=sys.stderr)
                hs.close()
                hs = server[0] = None
        if hs is not None:
            res = hs.request(c, args.timeout)
            if res[0] is not None:
                synced[0] = True
                return res
            print("[!] the long-lived harness failed: %s; running the script once per round "
                  "instead" % _tail(res[1]), file=sys.stderr)
            hs.close()
            server[0] = None
        return runner.run(patched, c, chunks)
    try:
        devirtualize(job, ppath, dpath, cfg, rerun, chunk_paths, live, devirt)
    except Exception as e:
        print("[!] devirtualization failed: %s: %s" % (type(e).__name__, e), file=sys.stderr)
        if os.environ.get("DEVIRT_TB"):
            import traceback
            traceback.print_exc()
    finally:
        if server[0] is not None:
            server[0].close()
