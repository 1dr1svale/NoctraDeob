import codegen as cg
import structure as stc
from luasym import Un, Bin, Const

def key(e):
    k = cg.expr_key(e)
    return None if k.startswith("X") else k

def single_assign(stmts):
    if len(stmts) != 1:
        return None
    st = stmts[0]
    if isinstance(st, cg.AssignS) and len(st.targets) == 1 and isinstance(st.targets[0], cg.LocalName) \
            and len(st.values.items) == 1 and st.values.tail is None and not getattr(st, "is_local", False):
        return st.targets[0].name, st.values.items[0]
    return None

def reads(e, name):
    return any(isinstance(x, cg.LocalName) and x.name == name for x in cg.walk(e))

def assign(name, value):
    return cg.AssignS([cg.LocalName(name)], cg.Multi([value]))

def match_if(st):
    t = single_assign(st.then)
    if t is None:
        return None
    name, a = t
    c = st.cond
    neg = isinstance(c, Un) and c.op == "Not"
    base = c.a if neg else c
    op = "Or" if neg else "And"
    if not st.els:
        if isinstance(base, cg.LocalName) and base.name == name:
            return assign(name, Bin(op, cg.LocalName(name), a))

        kb = key(base)
        if kb is not None and key(a) == kb:
            return assign(name, Bin("And" if neg else "Or", base, cg.LocalName(name)))
        return None
    e = single_assign(st.els)
    if e is None or e[0] != name:
        return None
    kb = key(base)
    if kb is not None and key(e[1]) == kb:
        return assign(name, Bin(op, base, a))
    if kb is not None and key(a) == kb:
        return assign(name, Bin("And" if neg else "Or", base, e[1]))
    return None

def and_or(stmts):
    out = stc.SBlock()
    for st in stmts:
        if isinstance(st, stc.SIf):
            st.then = and_or(st.then)
            st.els = and_or(st.els)
            r = match_if(st)
            if r is not None:
                st = r
        elif isinstance(st, stc.SLoop):
            st.body = and_or(st.body)
        prev = single_assign([out[-1]]) if out and isinstance(out[-1], cg.AssignS) else None

        if prev and isinstance(st, stc.SIf) and not st.els:
            t = single_assign(st.then)
            neg = isinstance(st.cond, Un) and st.cond.op == "Not"
            base = st.cond.a if neg else st.cond
            kb = key(base)
            if t and t[0] == prev[0] and kb is not None and key(prev[1]) == kb \
                    and not reads(base, t[0]) and not reads(t[1], t[0]):
                out[-1] = assign(t[0], Bin("Or" if neg else "And", prev[1], t[1]))
                continue

        if prev and isinstance(st, cg.AssignS):
            cur = single_assign([st])
            if cur and cur[0] == prev[0]:
                v = cur[1]
                if isinstance(v, Bin) and v.op in ("And", "Or") and isinstance(v.a, cg.LocalName) \
                        and v.a.name == cur[0] and not reads(v.b, cur[0]):
                    out[-1] = assign(cur[0], Bin(v.op, prev[1], v.b))
                    continue
        out.append(st)
    return out

def _stmt_exprs(st):
    out = []
    if isinstance(st, cg.AssignS):
        out += [t for t in st.targets if not isinstance(t, cg.LocalName)]
        out += list(st.values.items)
        if st.values.tail is not None:
            out.append(cg.TailRef(st.values.tail))
    elif isinstance(st, (cg.CallS, cg.TempDef)):
        out.append(st.call)
    elif isinstance(st, cg.SetListS):
        out.append(st.tbl)
        out += list(st.values.items)
        if st.values.tail is not None:
            out.append(cg.TailRef(st.values.tail))
    elif isinstance(st, cg.ForPrepS):
        out += list(st.exprs)
    elif isinstance(st, stc.SIf):
        out.append(st.cond)
    elif isinstance(st, stc.SLoop):
        if st.cond is not None:
            out.append(st.cond)
        if st.forinfo:
            out += [x for x in st.forinfo[1] if x is not None]
    elif isinstance(st, stc.SReturn) and st.values is not None:
        out += list(st.values.items)
        if st.values.tail is not None:
            out.append(cg.TailRef(st.values.tail))
    return [e for e in out if e is not None]

def _sub_blocks(st):
    if isinstance(st, stc.SIf):
        return [st.then, st.els]
    if isinstance(st, stc.SLoop):
        return [st.body]
    return []

def name_counts(stmts, reads=None, writes=None, text=None):
    import re
    if reads is None:
        reads, writes, text = {}, {}, []
    for st in stmts:
        if isinstance(st, cg.AssignS):
            for t in st.targets:
                if isinstance(t, cg.LocalName):
                    writes[t.name] = writes.get(t.name, 0) + 1
        if isinstance(st, stc.SLoop) and st.forinfo:
            for v in (st.forinfo[0] if isinstance(st.forinfo[0], (list, tuple)) else [st.forinfo[0]]):
                if isinstance(v, cg.LocalName):
                    writes[v.name] = writes.get(v.name, 0) + 2
        for e in _stmt_exprs(st):
            for x in cg.walk(e):
                if isinstance(x, cg.LocalName):
                    reads[x.name] = reads.get(x.name, 0) + 1
                elif isinstance(x, cg.FuncE):
                    text.append("\n".join(x.lines))
        for b in _sub_blocks(st):
            name_counts(b, reads, writes, text)
    if not hasattr(name_counts, "_re"):
        name_counts._re = re
    return reads, writes, text

def _positions(body):
    pos, rsites, wsites = {}, {}, {}
    n = [0]

    def walk(stmts, parent):
        for st in stmts:
            if isinstance(st, (stc.SStateMachine, stc.SGotoState)):
                raise ValueError
            i = n[0]
            n[0] += 1
            info = [i, i, stmts, parent]
            pos[id(st)] = info
            for e in _stmt_exprs(st):
                for x in cg.walk(e):
                    if isinstance(x, cg.LocalName):
                        rsites.setdefault(x.name, []).append(id(st))
            if isinstance(st, cg.AssignS):
                for t in st.targets:
                    if isinstance(t, cg.LocalName):
                        wsites.setdefault(t.name, []).append(st)
            for b in _sub_blocks(st):
                walk(b, st)
            info[1] = n[0] - 1
    try:
        walk(body, None)
    except ValueError:
        return None
    return pos, rsites, wsites

def _same_text(a, b):
    if a is b:
        return True
    r = cg.Renderer()
    return r.expr(a) == r.expr(b)

def _eval_list(st):
    seen = set()
    out = []

    def order(e):
        if e is None:
            return
        kids = cg.children(e)
        if kids and not isinstance(e, cg.ClosureExpr):
            if id(e) in seen:
                return
            seen.add(id(e))
            if isinstance(e, cg.CallE) and isinstance(e.fn, cg.Index) and e.args.items \
                    and type(e.fn.obj) is type(e.args.items[0]) and cg.children(e.fn.obj) \
                    and _same_text(e.fn.obj, e.args.items[0]):
                order(e.fn)
                for c in kids[2:]:
                    order(c)
            elif isinstance(e, cg.NewTableE):
                for k, v in e.items:
                    order(k)
                    order(v)
                if e.tail is not None:
                    order(cg.TailRef(e.tail))
            else:
                for c in kids:
                    order(c)
        out.append(e)
    if isinstance(st, stc.SIf):
        order(st.cond)
    elif isinstance(st, cg.CallS):
        order(st.call)
    elif isinstance(st, cg.AssignS):
        for t in st.targets:
            if isinstance(t, cg.Index):
                order(t.obj)
                order(t.key)
        for x in st.values.items:
            order(x)
        if st.values.tail is not None:
            order(cg.TailRef(st.values.tail))
    elif isinstance(st, stc.SReturn) and st.values is not None:
        for x in st.values.items:
            order(x)
        if st.values.tail is not None:
            order(cg.TailRef(st.values.tail))
    else:
        return None
    return out

def _conditional(e, acc):
    def mark(x):
        for y in cg.walk(x):
            acc.add(id(y))
    if isinstance(e, Bin) and e.op in ("And", "Or"):
        mark(e.b)
    elif isinstance(e, cg.IfExp):
        mark(e.a)
        mark(e.b)
    for c in cg.children(e):
        _conditional(c, acc)
    return acc

def _fold_table_store(prev_st, st):
    if not (isinstance(prev_st, cg.AssignS) and len(prev_st.targets) == 1
            and isinstance(prev_st.targets[0], cg.LocalName) and len(prev_st.values.items) == 1
            and prev_st.values.tail is None and isinstance(prev_st.values.items[0], cg.NewTableE)):
        return False
    tbl = prev_st.values.items[0]
    name = prev_st.targets[0].name
    if tbl.tail is not None or not (isinstance(st, cg.AssignS) and len(st.targets) == 1
                                    and len(st.values.items) == 1 and st.values.tail is None):
        return False
    t = st.targets[0]
    if not (isinstance(t, cg.Index) and isinstance(t.obj, cg.LocalName) and t.obj.name == name
            and isinstance(t.key, cg.Const)):
        return False
    v = st.values.items[0]
    if reads(v, name):
        return False
    k = t.key.v
    if isinstance(k, (str, bytes)):
        if any(isinstance(kk, cg.Const) and kk.v == k for kk, _ in tbl.items):
            return False
        prev_st.values = cg.Multi([cg.NewTableE(tbl.items + [(t.key, v)])])
        return True
    if isinstance(k, (int, float)) and not isinstance(k, bool) and k == cg.count_array(tbl) + 1 \
            and not any(kk is not None for kk, _ in tbl.items if not (isinstance(kk, cg.Const) and isinstance(kk.v, (str, bytes)))):
        prev_st.values = cg.Multi([cg.NewTableE(tbl.items + [(None, v)])])
        return True
    return False

def _last_value(e, x):
    if isinstance(e, cg.CallE):
        return e.args.tail is None and bool(e.args.items) and e.args.items[-1] is x
    if isinstance(e, cg.NewTableE):
        return e.tail is None and bool(e.items) and e.items[-1][0] is None and e.items[-1][1] is x
    return False

def fold_single_use(body):
    import re
    nreads, writes, text = name_counts(body)
    alltext = "\n".join(text)
    text_tokens = set(re.findall(r"(?<![\w.])[A-Za-z_]\w*", alltext)) if alltext else set()
    where = _positions(body)

    def in_text(name):
        return name in text_tokens

    def dead_after(name, prev_st, st, n_in_v):
        others = nreads.get(name, 0) - n_in_v
        if where is None:
            return False
        pos, rsites, wsites = where
        sites = rsites.get(name, [])
        ip = pos[id(prev_st)][0]
        idxs = [pos[s][0] for s in sites if s != id(st)]
        if len(sites) != others + n_in_v:
            return False
        if any(i > ip for i in idxs):
            return False

        chain = []
        cur = prev_st
        loop = None
        while True:
            info = pos.get(id(cur))
            if info is None:
                return False
            chain.append(info[2])
            parent = info[3]
            if parent is None:
                break
            if isinstance(parent, stc.SLoop):
                loop = parent
                break
            cur = parent
        if loop is None:
            return True
        lo, hi = pos[id(loop)][0], pos[id(loop)][1]
        outer = pos[id(loop)][3]
        while outer is not None and not isinstance(outer, stc.SLoop):
            outer = pos[id(outer)][3]
        inside = [i for i in idxs if lo <= i <= hi]
        if len(inside) != len(idxs) and (outer is not None or any(i > lo for i in idxs if i not in inside)):
            return False

        first = min(inside) if inside else None
        for w in wsites.get(name, []):
            info = pos.get(id(w))
            if info is None or not any(info[2] is b for b in chain):
                continue
            iw = info[0]
            if w is prev_st:
                if n_in_v == 0 and (first is None or first > iw):
                    return True
                continue
            if iw < ip and (first is None or first > iw) and \
                    not any(reads(e, name) for e in _stmt_exprs(w)):
                return True
        return False

    def try_fold(prev_st, st):
        prev = single_assign([prev_st])
        if prev is None:
            return False
        name, v = prev
        if in_text(name):
            return False
        if isinstance(v, (cg.FuncE, cg.ClosureExpr)):
            return False
        order = _eval_list(st)
        if order is None:
            return False
        hits = [x for x in order if isinstance(x, cg.LocalName) and x.name == name]
        if not hits:
            return False

        n_self = sum(1 for x in order if isinstance(x, cg.CallE) and isinstance(x.fn, cg.Index)
                     and isinstance(x.fn.obj, cg.LocalName) and x.fn.obj.name == name and x.args.items
                     and isinstance(x.args.items[0], cg.LocalName) and x.args.items[0].name == name)
        if len(hits) - n_self != 1:
            return False
        if cg.expands(v) and any(_last_value(x, hits[0]) for x in order):
            return False
        if isinstance(st, stc.SReturn) and cg.expands(v) and st.values.tail is None \
                and st.values.items and st.values.items[-1] is hits[0]:
            return False
        for x in order:
            if x is hits[0]:
                break
            if isinstance(x, (cg.CallE, cg.ClosureExpr, cg.FuncE)):
                return False
        if cg.has_side_effects(v):
            cond = set()
            for e in _stmt_exprs(st):
                _conditional(e, cond)
            if id(hits[0]) in cond:
                return False
        n_in_v = sum(1 for x in cg.walk(v) if isinstance(x, cg.LocalName) and x.name == name)
        raw_in_st = sum(1 for e in _stmt_exprs(st) for x in cg.walk(e) if isinstance(x, cg.LocalName) and x.name == name)
        simple_case = writes.get(name) == 1 and n_in_v == 0 and nreads.get(name) == raw_in_st
        if not simple_case and not dead_after(name, prev_st, st, n_in_v):
            return False

        def sub(e):
            return cg.map_expr(e, lambda x: v if isinstance(x, cg.LocalName) and x.name == name else None)
        if isinstance(st, stc.SIf):
            st.cond = sub(st.cond)
        elif isinstance(st, cg.CallS):
            st.call = sub(st.call)
        elif isinstance(st, stc.SReturn):
            st.values = cg.map_multi(st.values, lambda x: v if isinstance(x, cg.LocalName)
                                     and x.name == name else None)
        else:
            st.targets = [t if isinstance(t, cg.LocalName) else sub(t) for t in st.targets]
            st.values = cg.map_multi(st.values, lambda x: v if isinstance(x, cg.LocalName)
                                     and x.name == name else None)

        nreads[name] = nreads.get(name, 0) - raw_in_st
        writes[name] = writes.get(name, 0) - 1
        if where is not None:
            pos, rsites, wsites = where
            sites = rsites.get(name, [])
            sites[:] = [s for s in sites if s != id(st)]
            for x in cg.walk(v):
                if isinstance(x, cg.LocalName):
                    lst = rsites.get(x.name, [])
                    lst[:] = [id(st) if s == id(prev_st) else s for s in lst]
            ws = wsites.get(name, [])
            ws[:] = [w for w in ws if w is not prev_st]
        return True

    def try_coalesce(prev_st, st):
        if not (isinstance(prev_st, cg.AssignS) and isinstance(st, cg.AssignS)) \
                or getattr(prev_st, "is_local", False) or getattr(st, "is_local", False):
            return False
        if len(prev_st.targets) < 2 or len(st.targets) != 1 or len(st.values.items) != 1:
            return False
        y, x = st.targets[0], st.values.items[0]
        if not (isinstance(y, cg.LocalName) and isinstance(x, cg.LocalName)) or x.name == y.name:
            return False
        tnames = [t.name for t in prev_st.targets if isinstance(t, cg.LocalName)]
        if len(tnames) != len(prev_st.targets) or tnames.count(x.name) != 1 or y.name in tnames:
            return False
        if in_text(x.name):
            return False
        if any(isinstance(e, cg.LocalName) and e.name in (x.name, y.name)
               for v in prev_st.values.items for e in cg.walk(v)):
            return False
        if not dead_after(x.name, prev_st, st, 0):
            return False
        prev_st.targets[tnames.index(x.name)] = y
        nreads[x.name] = nreads.get(x.name, 0) - 1
        writes[x.name] = writes.get(x.name, 0) - 1
        if where is not None:
            _pos, rsites, wsites = where
            lst = rsites.get(x.name, [])
            lst[:] = [s for s in lst if s != id(st)]
            ws = wsites.get(x.name, [])
            ws[:] = [w for w in ws if w is not prev_st]
            ws = wsites.get(y.name, [])
            ws[:] = [prev_st if w is st else w for w in ws]
        return True

    def run(stmts):
        out = []
        for st in stmts:
            for b in _sub_blocks(st):
                b[:] = run(b)
            if out and try_coalesce(out[-1], st):
                continue

            blanks = []
            if not isinstance(st, cg.CommentS):
                while out and isinstance(out[-1], cg.CommentS) and not out[-1].text:
                    blanks.append(out.pop())
            folded = False
            while out and isinstance(out[-1], cg.AssignS) and not getattr(out[-1], "is_local", False) \
                    and try_fold(out[-1], st):
                out.pop()
                folded = True
            if not folded:
                out += reversed(blanks)

            if out and not (isinstance(st, cg.AssignS) and len(st.targets) == 1
                            and isinstance(st.targets[0], cg.Index)
                            and isinstance(st.targets[0].obj, cg.LocalName)
                            and in_text(st.targets[0].obj.name)
                            and any(cg.has_side_effects(x) for x in st.values.items)) \
                    and _fold_table_store(out[-1], st):
                tname = st.targets[0].obj.name
                nreads[tname] = nreads.get(tname, 0) - 1
                if where is not None:
                    rs = where[1]
                    lst = rs.get(tname, [])
                    if id(st) in lst:
                        lst.remove(id(st))
                    for lst in rs.values():
                        lst[:] = [id(out[-1]) if s == id(st) else s for s in lst]
                continue
            out.append(st)
        return stc.SBlock(out) if isinstance(stmts, stc.SBlock) else out

    return run(body)

def loop_vars(stmts):
    import re
    for st in stmts:
        for b in _sub_blocks(st):
            loop_vars(b)
        if isinstance(st, stc.SLoop) and st.kind == "forin" and st.forinfo and len(st.forinfo[0]) > 1:
            vs, it = st.forinfo
            rd, _, text = name_counts(st.body)
            alltext = "\n".join(text)
            text_tokens = set(re.findall(r"(?<![\w.])[A-Za-z_]\w*", alltext)) if alltext else set()

            def used(v):
                return rd.get(v.name, 0) > 0 or v.name in text_tokens

            vs = list(vs)
            while len(vs) > 1 and isinstance(vs[-1], cg.LocalName) and not used(vs[-1]):
                vs.pop()
            if len(vs) > 1 and isinstance(vs[0], cg.LocalName) and not used(vs[0]):
                vs[0] = cg.LocalName("_")
            st.forinfo = (vs, it)
    return stmts

def _truth(e):
    if isinstance(e, Bin) and e.op in ("And", "Or"):
        a, b = _truth(e.a), _truth(e.b)
        if e.op == "And" and isinstance(b, cg.Const) and b.v is True:
            return a
        if e.op == "Or" and isinstance(b, cg.Const) and b.v is False:
            return a
        return Bin(e.op, a, b)
    if isinstance(e, Un) and e.op == "Not" and isinstance(e.a, Un) and e.a.op == "Not":
        return _truth(e.a.a)
    return e

def conditions(stmts):
    for st in stmts:
        if isinstance(st, stc.SIf):
            st.cond = _truth(st.cond)
        elif isinstance(st, stc.SLoop) and st.cond is not None and st.kind in ("whilecond", "repeat"):
            st.cond = _truth(st.cond)
        for b in _sub_blocks(st):
            conditions(b)
    return stmts

def _has_continue(stmts):
    for st in stmts:
        if isinstance(st, stc.SContinue):
            return True
        if isinstance(st, stc.SIf) and (_has_continue(st.then) or _has_continue(st.els)):
            return True
    return False

def _only_break(block):
    real = [x for x in block if not (isinstance(x, cg.CommentS) and not x.text)]
    return len(real) == 1 and isinstance(real[0], stc.SBreak)

def while_cond(stmts):
    for st in stmts:
        if isinstance(st, stc.SIf):
            while_cond(st.then)
            while_cond(st.els)
        elif isinstance(st, stc.SLoop):
            while_cond(st.body)
            if st.kind != "while" or not st.body:
                continue

            body = [x for x in st.body if not (isinstance(x, cg.CommentS) and not x.text)]
            if not body:
                continue
            first = body[0]
            if isinstance(first, stc.SIf):
                first.then[:] = [x for x in first.then if not (isinstance(x, cg.CommentS) and not x.text)] if _only_break(first.then) else first.then
                first.els[:] = [x for x in first.els if not (isinstance(x, cg.CommentS) and not x.text)] if _only_break(first.els) else first.els
            if isinstance(first, stc.SIf) and len(first.then) == 1 and isinstance(first.then[0], stc.SBreak):
                st.kind, st.cond = "whilecond", stc.negate(first.cond)
                st.body = stc.SBlock(list(first.els) + list(body[1:]))
            elif isinstance(first, stc.SIf) and len(first.els) == 1 and isinstance(first.els[0], stc.SBreak):
                st.kind, st.cond = "whilecond", first.cond
                st.body = stc.SBlock(list(first.then) + list(body[1:]))
            elif len(body) == 2 and isinstance(first, stc.SIf) and isinstance(body[1], stc.SBreak) and not first.els and first.then and isinstance(first.then[-1], stc.SContinue):
                st.kind, st.cond = "whilecond", first.cond
                st.body = stc.SBlock(list(first.then[:-1]))
            elif len(body) >= 2 and isinstance(body[-1], stc.SIf) and not body[-1].els and len(body[-1].then) == 1 and isinstance(body[-1].then[0], stc.SBreak) and not _has_continue(body[:-1]):
                st.kind, st.cond = "repeat", body[-1].cond
                st.body = stc.SBlock(list(body[:-1]))
    return stmts

def strip_trailing_continue(stmts):
    def tail(block):
        if block and isinstance(block[-1], stc.SContinue):
            block.pop()
        elif block and isinstance(block[-1], stc.SIf):
            tail(block[-1].then)
            tail(block[-1].els)
    for st in stmts:
        if isinstance(st, stc.SLoop):
            tail(st.body)
        for b in _sub_blocks(st):
            strip_trailing_continue(b)
    return stmts

def strip_trailing_return(body):
    if body and isinstance(body[-1], stc.SReturn) and (
            body[-1].values is None or (not body[-1].values.items and body[-1].values.tail is None)):
        body.pop()
    return body

def _map_stmt_exprs(st, fn):
    if isinstance(st, cg.AssignS):
        st.targets = [t if isinstance(t, cg.LocalName) else cg.map_expr(t, fn) for t in st.targets]
        st.values = cg.map_multi(st.values, fn)
    elif isinstance(st, cg.CallS):
        st.call = cg.map_expr(st.call, fn)
    elif isinstance(st, cg.TempDef):
        st.call = cg.map_expr(st.call, fn)
    elif isinstance(st, cg.SetListS):
        st.tbl = cg.map_expr(st.tbl, fn)
        st.values = cg.map_multi(st.values, fn)
    elif isinstance(st, cg.ForPrepS):
        st.exprs[:] = [cg.map_expr(x, fn) for x in st.exprs]
    elif isinstance(st, stc.SIf):
        st.cond = cg.map_expr(st.cond, fn)
    elif isinstance(st, stc.SLoop):
        if st.cond is not None:
            st.cond = cg.map_expr(st.cond, fn)
        if st.forinfo:
            lst = st.forinfo[1]
            lst[:] = [cg.map_expr(x, fn) if x is not None else None for x in lst]
    elif isinstance(st, stc.SReturn) and st.values is not None:
        st.values = cg.map_multi(st.values, fn)

def _map_body(stmts, fn):
    for st in stmts:
        _map_stmt_exprs(st, fn)
        for b in _sub_blocks(st):
            _map_body(b, fn)

def inline_const_locals(body, params=()):
    reads, writes, text = name_counts(body)
    nested = "\n".join(text)
    import re

    def candidates(stmts):
        out = []
        for i, st in enumerate(stmts):
            if isinstance(st, cg.AssignS) and len(st.targets) == 1 and isinstance(st.targets[0], cg.LocalName) \
                    and len(st.values.items) == 1 and st.values.tail is None \
                    and isinstance(st.values.items[0], Const):
                v = st.values.items[0].v
                nm = st.targets[0].name
                ok = isinstance(v, bool) or (isinstance(v, (int, float)) and v == v and abs(v) != float("inf")) \
                    or (isinstance(v, bytes) and (len(v) <= 40 or reads.get(nm, 0) <= 1))
                if ok and writes.get(nm) == 1 and nm not in params \
                        and not re.search(r"\b%s\b" % re.escape(nm), nested):
                    after, _, _ = name_counts(stmts[i + 1:])
                    if after.get(nm, 0) == reads.get(nm, 0):
                        out.append((stmts, i, nm, v))
            for b in _sub_blocks(st):
                out += candidates(b)
        return out

    for _ in range(8):
        cands = candidates(body)
        if not cands:
            break
        for stmts, i, nm, v in reversed(cands):
            def fn(x, nm=nm, v=v):
                return Const(v) if isinstance(x, cg.LocalName) and x.name == nm else None
            _map_body(stmts[i + 1:], fn)
            del stmts[i]

        reads, writes, text = name_counts(body)
        nested = "\n".join(text)
    return body

def _blank(block):
    return all(isinstance(x, cg.CommentS) and not x.text for x in block)

def drop_blank_branches(stmts):
    for st in stmts:
        if isinstance(st, stc.SIf):
            drop_blank_branches(st.then)
            drop_blank_branches(st.els)
            for b in (st.then, st.els):
                while b and isinstance(b[-1], cg.CommentS) and not b[-1].text and not _blank(b):
                    b.pop()
                if not _blank(b) and sum(1 for x in b if not isinstance(x, cg.CommentS)) <= 2:
                    b[:] = [x for x in b if not (isinstance(x, cg.CommentS) and not x.text)]
            if st.els and _blank(st.els):
                st.els[:] = []
            if st.then and _blank(st.then) and st.els:
                st.cond = stc.negate(st.cond)
                st.then[:], st.els[:] = list(st.els), []
        elif isinstance(st, stc.SLoop):
            drop_blank_branches(st.body)
    return stmts
