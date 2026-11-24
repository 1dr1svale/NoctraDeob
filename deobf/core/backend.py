import os
import sys
import threading

def lower(entry_key, order, irm, link, prefix, upnames, closure):
    import structure as stc
    import codegen as cg
    import loops as lp
    import variables as vr
    import idioms as idi
    from luasym import ClosureExpr, Pseudo
    entry, blocks = stc.build_cfg(entry_key, order, irm, link)
    if not os.environ.get("DEVIRT_NO_MERGE"):
        entry, _ = stc.merge_equivalent(entry, blocks, irm)
    entry = stc.thread_empty(entry, blocks)
    lp.recognize(entry, blocks, irm)

    entry = stc.thread_empty(entry, blocks)
    cg.simplify_blocks(blocks, irm)
    own = set(vr.rename(entry, blocks, prefix, set()).values())
    names = {("up", i): nm for i, nm in (upnames or {}).items()}

    def conv(x):
        return closure(x, names) if isinstance(x, ClosureExpr) else None
    for b in blocks.values():
        for i, s_ in enumerate(b.stmts):
            if isinstance(s_, cg.AssignS):
                s_.values = cg.map_multi(s_.values, conv)
                s_.targets = [t if isinstance(t, (cg.LocalName, Pseudo)) else cg.map_expr(t, conv)
                              for t in s_.targets]
            elif isinstance(s_, (cg.CallS, cg.TempDef, cg.SetListS, cg.ForPrepS)):
                b.stmts[i] = cg.map_stmt(s_, lambda e: cg.map_expr(e, conv), lambda m: cg.map_multi(m, conv))
        if b.kind == "cond":
            b.cond = cg.map_expr(b.cond, conv)
        elif b.kind == "ret" and b.values is not None:
            b.values = cg.map_multi(b.values, conv)

    nerr = sum(1 for b in blocks.values() if b.kind == "error")
    entry, body, sr = stc.structure(entry, blocks, own)
    body = stc.cleanup(body)
    body = idi.drop_blank_branches(body)
    body = idi.and_or(body)
    body = idi.fold_single_use(body)
    body = idi.while_cond(body)
    body = idi.strip_trailing_continue(body)
    body = idi.conditions(body)
    body = idi.while_cond(body)
    body = idi.strip_trailing_continue(body)
    body = idi.loop_vars(body)
    body = idi.strip_trailing_return(body)
    if getattr(irm, "inline_const_locals", False):
        body = idi.inline_const_locals(body)
        body = idi.fold_single_use(body)
    body = vr.declare(body, (), own)
    body = vr.limit_locals(body)
    params = vr.extract_params(body)
    rend = cg.Renderer(names)
    return rend.block(body, ""), params, nerr, sr.fallbacks

def polish(text):
    import codegen
    text = text.replace(codegen.long_nl, "\n")
    if not os.environ.get("DEVIRT_KEEP_JUNK"):
        import junk
        try:
            text = junk.fold_defaults(junk.strip(text))
        except Exception as ex:
            print("[!] key-number clean-up skipped: %s" % ex, file=sys.stderr)
    if not os.environ.get("DEVIRT_NO_NAMES"):
        import names
        try:
            text = names.rename_text(text)
        except Exception as ex:
            print("[!] naming pass failed: %s" % ex, file=sys.stderr)
    import localfuncs
    try:
        text = localfuncs.rewrite(text)
    except Exception as ex:
        print("[!] local function pass failed: %s" % ex, file=sys.stderr)
    return text

def finish_text(text):
    import spacing
    return spacing.space(text)

def run_big_stack(fn, *a):
    sys.setrecursionlimit(200000)
    threading.stack_size(256 * 1024 * 1024 - 4096)
    res = {}

    def target():
        try:
            res["v"] = fn(*a)
        except BaseException as ex:
            res["e"] = ex
    t = threading.Thread(target=target)
    t.start()
    t.join()
    if "e" in res:
        raise res["e"]
    return res.get("v")
