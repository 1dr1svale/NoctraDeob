import codegen as cg
import structure as stc
from luasym import Reg, Const, Pseudo, ClosureExpr, LTable, Global

def closure_regs(c):
    out = []
    for e in c.upvals:
        if type(e).__name__ == "MaybeBox":
            out.append(e.reg)
        elif isinstance(e, LTable):
            vals = list(e.h.values())
            if any(type(v).__name__ == "RegFile" for v in vals):
                out += [v for v in vals if isinstance(v, int)][:1]
        elif isinstance(e, Reg):
            out.append(e.n)
    return out + list(getattr(c, "frame_regs", ()))

def closure_ref_regs(c):
    out = []
    for e in c.upvals:
        if type(e).__name__ == "MaybeBox":
            out.append(e.reg)
        elif isinstance(e, LTable):
            vals = list(e.h.values())
            if any(type(v).__name__ == "RegFile" for v in vals):
                out += [v for v in vals if isinstance(v, int)][:1]
    return out + list(getattr(c, "frame_regs", ()))

def expr_reg_occ(e):
    out = []
    for x in cg.walk(e):
        if isinstance(x, Reg):
            out.append(x.n)
        elif isinstance(x, ClosureExpr):
            out += closure_regs(x)
    return out

def stmt_io(st):
    uses, defs = [], []
    if isinstance(st, cg.AssignS):
        for t in st.targets:
            if isinstance(t, Reg):
                defs.append(t.n)
            elif not isinstance(t, Pseudo):
                uses += expr_reg_occ(t)
        for v in st.values.items:
            uses += expr_reg_occ(v)
        if st.values.tail is not None:
            uses += expr_reg_occ(cg.TailRef(st.values.tail))
    elif isinstance(st, (cg.CallS, cg.TempDef)):
        uses += expr_reg_occ(st.call)
    elif isinstance(st, cg.SetListS):
        uses += expr_reg_occ(st.tbl)
        for v in st.values.items:
            uses += expr_reg_occ(v)
        if st.values.tail is not None:
            uses += expr_reg_occ(cg.TailRef(st.values.tail))
    elif isinstance(st, cg.ForPrepS):
        for v in st.exprs:
            uses += expr_reg_occ(v)
    return uses, defs

def term_io(b):
    uses, defs = [], []
    if b.kind == "cond":
        uses += expr_reg_occ(b.cond)
    elif b.kind == "ret" and b.values is not None:
        for v in b.values.items:
            uses += expr_reg_occ(v)
        if b.values.tail is not None:
            uses += expr_reg_occ(cg.TailRef(b.values.tail))
    elif b.kind == "for":
        defs.append(b.values[0])
    elif b.kind == "forin":
        defs += list(b.values[0])
    return uses, defs

class UnionFind:
    def __init__(self):
        self.p = {}

    def find(self, x):
        p = self.p
        p.setdefault(x, x)
        while p[x] != x:
            p[x] = p[p[x]]
            x = p[x]
        return x

    def union(self, a, b):
        a, b = self.find(a), self.find(b)
        if a != b:
            self.p[b] = a

def stmt_caps(st):
    caps, closes = [], []
    if isinstance(st, cg.CloseS):
        closes.append(st.reg)
    else:
        for v in stmt_exprs(st):
            for x in cg.walk(v):
                if isinstance(x, ClosureExpr):
                    caps += closure_ref_regs(x)
    return caps, closes

def stmt_exprs(st):
    out = []
    if isinstance(st, cg.AssignS):
        out += [t for t in st.targets if not isinstance(t, (Reg, Pseudo))]
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
    return out

def term_exprs(b):
    out = []
    if b.kind == "cond":
        out.append(b.cond)
    elif b.kind == "ret" and b.values is not None:
        out += list(b.values.items)
        if b.values.tail is not None:
            out.append(cg.TailRef(b.values.tail))
    return out

def webs(entry, blocks):
    events = {}
    for b in blocks.values():
        ev = []
        for i, st in enumerate(b.stmts):
            u, d = stmt_io(st)
            caps, closes = stmt_caps(st)
            for r in caps:
                ev.append((i, "c", r))
            for r in u:
                ev.append((i, "u", r))
            for r in d:
                ev.append((i, "d", r))
            for r in closes:
                ev.append((i, "x", r))
        u, d = term_io(b)
        for v in term_exprs(b):
            for x in cg.walk(v):
                if isinstance(x, ClosureExpr):
                    for r in closure_ref_regs(x):
                        ev.append((len(b.stmts), "c", r))
        for r in u:
            ev.append((len(b.stmts), "u", r))
        for r in d:
            ev.append((len(b.stmts), "d", r))
        events[b.id] = ev
    order = stc.rpo(entry, lambda n: blocks[n].succ)
    preds = {bid: [] for bid in blocks}
    for b in blocks.values():
        for s_ in b.succ:
            if s_ in preds:
                preds[s_].append(b.id)

    def transfer(bid, inn):
        cur = dict(inn)
        for i, k, r in events[bid]:
            if k == "d":
                cur[r] = frozenset([("d", bid, i, r)])
            elif k == "c":
                if not cur.get(r):
                    cur[r] = frozenset([("c", bid, i, r)])
                cur[("o", r)] = cur.get(("o", r), frozenset()) | cur.get(r, frozenset())
            elif k == "x":
                cur.pop(("o", r), None)
        return cur

    reach_in = {bid: {} for bid in blocks}
    reach_out = {bid: {} for bid in blocks}
    changed = True
    while changed:
        changed = False
        for bid in order:
            inn = {}
            for p in preds[bid]:
                for r, ds in reach_out[p].items():
                    cur = inn.get(r)
                    inn[r] = ds if cur is None else (cur | ds)
            reach_in[bid] = inn
            out = transfer(bid, inn)
            if out != reach_out[bid]:
                reach_out[bid] = out
                changed = True
    uf = UnionFind()
    use_web = {}
    def_web = {}
    for bid, ev in events.items():
        cur = dict(reach_in[bid])
        for i, k, r in ev:
            if k == "u":
                ds = cur.get(r)
                key = ("u", bid, i, r)
                if ds:
                    ds = list(ds)
                    for d in ds[1:]:
                        uf.union(ds[0], d)
                    use_web[key] = ds[0]
                else:
                    use_web[key] = None
            elif k == "c":
                if not cur.get(r):
                    syn = ("c", bid, i, r)
                    uf.find(syn)
                    cur[r] = frozenset([syn])
                ds = list(cur.get(r, ()))
                for d in ds[1:]:
                    uf.union(ds[0], d)
                cur[("o", r)] = cur.get(("o", r), frozenset()) | cur.get(r, frozenset())
            elif k == "d":
                d = ("d", bid, i, r)
                uf.find(d)
                for o in cur.get(("o", r), ()):
                    uf.union(o, d)
                cur[r] = frozenset([d])
                def_web[d] = d
            elif k == "x":
                cur.pop(("o", r), None)
    for k, v in use_web.items():
        if v is not None:
            use_web[k] = uf.find(v)
    for k in def_web:
        def_web[k] = uf.find(k)
    return use_web, def_web

def rename(entry, blocks, prefix, captured):
    use_web, def_web = webs(entry, blocks)
    names = {}
    counter = {}

    forwebs = set()
    for b in blocks.values():
        if b.kind in ("for", "forin"):
            regs = [b.values[0]] if b.kind == "for" else list(b.values[0])
            for r in regs:
                d = ("d", b.id, len(b.stmts), r)
                if d in def_web:
                    forwebs.add(def_web[d])

    def name_of(web, reg):
        if reg in captured and web not in forwebs:
            web = ("cap", reg)
        if web is None:
            return None
        n = names.get(web)
        if n is None:
            k = counter.get(reg, 0)
            counter[reg] = k + 1
            n = names[web] = "%s%d" % (prefix, reg) + ("" if k == 0 else "_%d" % k)
        return n

    def ren_use(bid, i):
        def fn(x):
            if isinstance(x, Reg):
                w = use_web.get(("u", bid, i, x.n), "missing")
                if w == "missing":
                    return None
                nm = name_of(w, x.n)
                return Const(None) if nm is None else cg.LocalName(nm)
            if isinstance(x, ClosureExpr):
                x.capnames = {}
                for r in closure_regs(x):
                    w = use_web.get(("u", bid, i, r))
                    x.capnames[r] = name_of(w, r) or "nil"
                return x
            return None
        return fn

    def ren_def(bid, i, reg):
        return cg.LocalName(name_of(def_web[("d", bid, i, reg)], reg))

    used = {w for w in use_web.values() if w is not None}

    def dead(bid, i, reg):
        w = def_web.get(("d", bid, i, reg))
        return w is not None and w not in used and reg not in captured

    for b in blocks.values():
        keep = []
        for i, st in enumerate(b.stmts):
            if isinstance(st, cg.AssignS) and len(st.targets) == 1 and isinstance(st.targets[0], Reg) and dead(b.id, i, st.targets[0].n):
                vals = st.values

                pure_pack = len(vals.items) == 1 and isinstance(vals.items[0], cg.CallE) and \
                    isinstance(vals.items[0].fn, Global) and vals.items[0].fn.name == "table.pack"
                if vals.tail is None and len(vals.items) == 1 and (pure_pack or (
                        not cg.has_side_effects(vals.items[0])
                        and not any(isinstance(x, ClosureExpr) for x in cg.walk(vals.items[0])))):
                    keep.append(None)
                    continue
                if vals.tail is not None and not vals.items and isinstance(vals.tail, cg.InlineTail):
                    keep.append(cg.CallS(vals.tail.call))
                    continue
                if len(vals.items) == 1 and vals.tail is None and isinstance(vals.items[0], cg.CallE):
                    keep.append(cg.CallS(vals.items[0]))
                    continue
            keep.append(st)
        b.stmts = [x if x is not None else cg.CommentS("") for x in keep]
    for b in blocks.values():
        for i, st in enumerate(b.stmts):
            fu = ren_use(b.id, i)
            if isinstance(st, cg.AssignS):
                tg = []
                for t in st.targets:
                    if isinstance(t, Reg):
                        tg.append(ren_def(b.id, i, t.n))
                    elif isinstance(t, Pseudo):
                        tg.append(t)
                    else:
                        tg.append(cg.map_expr(t, fu))
                b.stmts[i] = cg.AssignS(tg, cg.map_multi(st.values, fu))
            else:
                b.stmts[i] = cg.map_stmt(st, lambda e: cg.map_expr(e, fu), lambda m: cg.map_multi(m, fu))
        n = len(b.stmts)
        fu = ren_use(b.id, n)
        if b.kind == "cond":
            b.cond = cg.map_expr(b.cond, fu)
        elif b.kind == "ret" and b.values is not None:
            b.values = cg.map_multi(b.values, fu)
        elif b.kind == "for":
            b.values = (ren_def(b.id, n, b.values[0]), b.values[1])
        elif b.kind == "forin":
            b.values = ([ren_def(b.id, n, v) for v in b.values[0]], b.values[1])
    return names

def names_in_expr(e):
    out = []
    for x in cg.walk(e):
        if isinstance(x, cg.LocalName):
            out.append(x.name)
        elif isinstance(x, cg.FuncE):
            out += list(getattr(x, "captures", ()))
    return out

def stmt_names(st):
    reads, writes = [], []
    if isinstance(st, cg.AssignS):
        for t in st.targets:
            if isinstance(t, cg.LocalName):
                writes.append(t.name)
            else:
                reads += names_in_expr(t)
        for v in st.values.items:
            reads += names_in_expr(v)
        if st.values.tail is not None:
            reads += names_in_expr(cg.TailRef(st.values.tail))
    elif isinstance(st, (cg.CallS, cg.TempDef)):
        reads += names_in_expr(st.call)
    elif isinstance(st, cg.SetListS):
        reads += names_in_expr(st.tbl)
        for v in st.values.items:
            reads += names_in_expr(v)
        if st.values.tail is not None:
            reads += names_in_expr(cg.TailRef(st.values.tail))
    elif isinstance(st, cg.ForPrepS):
        for v in st.exprs:
            reads += names_in_expr(v)
    elif isinstance(st, stc.SReturn) and st.values is not None:
        for v in st.values.items:
            reads += names_in_expr(v)
        if st.values.tail is not None:
            reads += names_in_expr(cg.TailRef(st.values.tail))
    return reads, writes

def occurrences(stmts, path, occ):
    for i, st in enumerate(stmts):
        here = path + ((id(stmts), i),)
        if isinstance(st, stc.SIf):
            for n in names_in_expr(st.cond):
                occ.setdefault(n, []).append(here)
            occurrences(st.then, here, occ)
            occurrences(st.els, here, occ)
        elif isinstance(st, stc.SLoop):
            if st.kind == "for":
                for e in st.forinfo[1]:
                    for n in names_in_expr(e):
                        occ.setdefault(n, []).append(here)
            elif st.kind == "forin":
                for e in st.forinfo[1]:
                    for n in names_in_expr(e):
                        occ.setdefault(n, []).append(here)
            if st.cond is not None:
                for n in names_in_expr(st.cond):
                    occ.setdefault(n, []).append(here)
            occurrences(st.body, here, occ)
        elif isinstance(st, DoBlock):
            occurrences(st.body, here, occ)
        else:
            r, w = stmt_names(st)
            for n in r + w:
                occ.setdefault(n, []).append(here)

def loop_vars(stmts, out):
    for st in stmts:
        if isinstance(st, stc.SIf):
            loop_vars(st.then, out)
            loop_vars(st.els, out)
        elif isinstance(st, stc.SLoop):
            if st.kind == "for":
                out.add(st.forinfo[0].name)
            elif st.kind == "forin":
                out |= {v.name for v in st.forinfo[0]}
            loop_vars(st.body, out)

def exposed_reads(stmts):
    exposed = set()

    def run(block, assigned):
        a = set(assigned)
        for st in block:
            if isinstance(st, stc.SIf):
                exposed.update(set(names_in_expr(st.cond)) - a)
                t = run(st.then, a)
                e = run(st.els, a)
                a = t & e
            elif isinstance(st, stc.SLoop):
                if st.kind == "for":
                    for x in st.forinfo[1]:
                        exposed.update(set(names_in_expr(x)) - a)
                    run(st.body, a | {st.forinfo[0].name})
                elif st.kind == "forin":
                    for x in st.forinfo[1]:
                        exposed.update(set(names_in_expr(x)) - a)
                    run(st.body, a | {v.name for v in st.forinfo[0]})
                else:
                    run(st.body, a)
            else:
                r, w = stmt_names(st)
                exposed.update(set(r) - a)
                a |= set(w)
        return a
    run(stmts, set())
    return exposed

def declare(body, params=(), own=None):
    occ = {}
    occurrences(body, (), occ)
    fvars = set()
    loop_vars(body, fvars)
    blocks_by_id = {}
    carried = {}

    def index(stmts):
        blocks_by_id[id(stmts)] = stmts
        for st in stmts:
            if isinstance(st, stc.SIf):
                index(st.then)
                index(st.els)
            elif isinstance(st, stc.SLoop):
                carried[id(st.body)] = exposed_reads(st.body)
                index(st.body)
    index(body)
    decls = {}
    assigned = set()
    assigned_names(body, assigned)
    for name, paths in occ.items():
        if (name in fvars and name not in assigned) or name in params or (own is not None and name not in own):
            continue
        common = list(paths[0])
        for p in paths[1:]:
            k = 0
            while k < len(common) and k < len(p) and common[k] == p[k]:
                k += 1
            del common[k:]

        blk = id(body)
        at = None
        depth = 0
        while True:
            nxt = {p[depth] for p in paths if len(p) > depth}
            nb = {bid for bid, _ in nxt}
            if len(nb) != 1 or any(len(p) <= depth for p in paths):
                break
            bid = nb.pop()
            if bid != blk:
                if bid in carried and name in carried[bid]:
                    break
                blk = bid
            at = (blk, min(i for b_, i in nxt))
            if depth < len(common):
                depth += 1
                continue
            break
        if at is None:
            at = (id(body), min(p[0][1] for p in paths))
        decls.setdefault(at[0], []).append((at[1], name))
    for bid, lst in decls.items():
        stmts = blocks_by_id[bid]
        at = {}
        for idx, name in lst:
            at.setdefault(idx, []).append(name)

        for idx in sorted(at, reverse=True):
            names = at[idx]
            st = stmts[idx] if idx < len(stmts) else None
            if isinstance(st, cg.AssignS) and not getattr(st, "is_local", False) and all(isinstance(t, cg.LocalName) for t in st.targets) and sorted(t.name for t in st.targets) == sorted(names) and len(set(names)) == len(names) and not set(names) & set(stmt_names_values(st)):
                st.is_local = True
                continue
            if isinstance(st, cg.AssignS) and not getattr(st, "is_local", False) and len(st.targets) == 1 and isinstance(st.targets[0], cg.LocalName) and st.targets[0].name in names and st.targets[0].name not in stmt_names_values(st):
                st.is_local = True
                names = [n for n in names if n != st.targets[0].name]
            if names:
                stmts.insert(idx, cg.LocalS(names, None))
    return body

def stmt_names_values(st):
    return stmt_names(st)[0]

class DoBlock:
    def __init__(self, body):
        self.body = body

def assigned_names(stmts, out, bound=frozenset()):
    for st in stmts:
        if isinstance(st, stc.SIf):
            assigned_names(st.then, out, bound)
            assigned_names(st.els, out, bound)
        elif isinstance(st, stc.SLoop):
            b = set(bound)
            if st.kind == "for":
                b.add(st.forinfo[0].name)
            elif st.kind == "forin":
                b |= {v.name for v in st.forinfo[0]}
            assigned_names(st.body, out, b)
        elif isinstance(st, DoBlock):
            assigned_names(st.body, out, bound)
        elif isinstance(st, cg.AssignS):
            out.update(t.name for t in st.targets if isinstance(t, cg.LocalName) and t.name not in bound)

def declared_here(st):
    if isinstance(st, cg.LocalS):
        return list(st.names)
    if isinstance(st, cg.AssignS) and getattr(st, "is_local", False):
        return [t.name for t in st.targets if isinstance(t, cg.LocalName)]
    return []

def names_anywhere(st):
    occ = {}
    occurrences(st.body if isinstance(st, DoBlock) else [st], (), occ)
    return set(occ)

def limit_locals(stmts, outer=0, budget=180):
    total = sum(len(declared_here(s)) for s in stmts)
    if outer + total > budget:
        stmts = fit_locals(stmts, budget - outer)

    active = outer
    for st in stmts:
        if isinstance(st, stc.SIf):
            st.then[:] = limit_locals(st.then, active, budget)
            st.els[:] = limit_locals(st.els, active, budget)
        elif isinstance(st, stc.SLoop):
            extra = 1 if st.kind == "for" else len(st.forinfo[0]) if st.kind == "forin" else 0
            st.body[:] = limit_locals(st.body, active + extra, budget)
        elif isinstance(st, DoBlock):
            st.body[:] = limit_locals(st.body, active, budget)
        active += len(declared_here(st))
    return stmts

def _hoistable(st):
    if isinstance(st, cg.LocalS) and st.values is None:
        return list(st.names)
    if isinstance(st, cg.AssignS) and getattr(st, "is_local", False):
        return [t.name for t in st.targets if isinstance(t, cg.LocalName)]
    return []

def _unlocalize(stmts, hoisted):
    out = []
    for st in stmts:
        if isinstance(st, cg.LocalS) and st.values is None:
            names = [x for x in st.names if x not in hoisted]
            if names:
                out.append(cg.LocalS(names, None))
            continue
        if isinstance(st, cg.AssignS) and getattr(st, "is_local", False) and \
                any(isinstance(t, cg.LocalName) and t.name in hoisted for t in st.targets):
            keep = [t.name for t in st.targets if isinstance(t, cg.LocalName) and t.name not in hoisted]
            if keep:
                out.append(cg.LocalS(keep, None))
            st.is_local = False
        out.append(st)
    return out

def fit_locals(stmts, room):
    if sum(len(declared_here(s)) for s in stmts) <= room:
        return stmts
    if wrap_segments(stmts, room, dry=True) > room:
        got = split_block(stmts, room)
        if got is not None:
            return got
    return wrap_segments(stmts, room)

def split_block(stmts, room):
    n = len(stmts)
    decl_at = [declared_here(s) for s in stmts]
    total = sum(len(d) for d in decl_at)
    if total <= room:
        return stmts
    last, first, hoistable = {}, {}, set()
    for i, s in enumerate(stmts):
        for nm in names_anywhere(s):
            last[nm] = i
        for nm in decl_at[i]:
            first.setdefault(nm, i)
        hoistable.update(_hoistable(s))

    cross_d = [0] * (n + 2)
    bad_d = [0] * (n + 2)
    for nm, f in first.items():
        lst = last.get(nm, f)
        if lst > f:
            cross_d[f + 1] += 1
            cross_d[lst + 1] -= 1
            if nm not in hoistable:
                bad_d[f + 1] += 1
                bad_d[lst + 1] -= 1
    best = None
    cross = bad = left = 0
    for k in range(1, n):
        cross += cross_d[k]
        bad += bad_d[k]
        left += len(decl_at[k - 1])
        if bad or left <= cross:
            continue
        peak = max(left, cross + total - left)
        if best is None or (peak, cross) < best[0]:
            best = ((peak, cross), k)
    if best is None or best[0][0] >= total:
        return None
    k = best[1]
    hoisted = {nm for nm, f in first.items() if f < k <= last.get(nm, f)}
    room2 = room - len(hoisted)
    pre = sorted(hoisted, key=lambda nm: first[nm])
    out = [cg.LocalS(pre[j:j + 10], None) for j in range(0, len(pre), 10)]
    out.append(DoBlock(fit_locals(_unlocalize(stmts[:k], hoisted), room2)))
    return out + fit_locals(stmts[k:], room2)

def _segments(stmts, decl_at, last, hoisted):
    segs = []
    start, cnt, reach = 0, 0, -1
    for i in range(len(stmts)):
        for n in decl_at[i]:
            if n in hoisted:
                continue
            cnt += 1
            reach = max(reach, last.get(n, i))
        if i >= reach:
            segs.append((start, i + 1, cnt))
            start, cnt, reach = i + 1, 0, -1
    if start < len(stmts):
        segs.append((start, len(stmts), cnt))
    return segs

def wrap_segments(stmts, room, chunk=None, dry=False):
    n = len(stmts)
    last = {}
    decl_at = []
    for i, s_ in enumerate(stmts):
        for nm in names_anywhere(s_):
            last[nm] = i
        decl_at.append(declared_here(s_))
    life = []
    for i, names in enumerate(decl_at):
        for nm in names:
            life.append((last.get(nm, i) - i, nm))
    life.sort(reverse=True)
    if chunk is None:
        chunk = max(20, min(80, room // 3))
    hoisted = set()
    k = 0
    while True:
        segs = _segments(stmts, decl_at, last, hoisted)
        worst = max((c for _, _, c in segs), default=0)
        if worst <= chunk or k >= len(life) or len(hoisted) + chunk >= room:
            break

        for _ in range(max(1, len(life) // 50)):
            if k < len(life):
                hoisted.add(life[k][1])
                k += 1
    if dry:
        def wraps(a, b, c):
            return c >= 1 and 1 < b - a < n
        inner = [c for a, b, c in segs if wraps(a, b, c)]
        return len(hoisted) + sum(c for a, b, c in segs if not wraps(a, b, c)) + max(inner, default=0)
    rest = {}
    if hoisted:
        for st in stmts:
            if isinstance(st, cg.LocalS):
                st.names = [x for x in st.names if x not in hoisted]
            elif isinstance(st, cg.AssignS) and getattr(st, "is_local", False) and \
                    any(isinstance(t, cg.LocalName) and t.name in hoisted for t in st.targets):
                st.is_local = False
                keep = [t.name for t in st.targets if isinstance(t, cg.LocalName) and t.name not in hoisted]
                if keep:
                    rest[id(st)] = keep
    for min_cnt in (2, 1):
        out = []
        for a, b, cnt in segs:
            seg = []
            for st in stmts[a:b]:
                if isinstance(st, cg.LocalS) and not st.names:
                    continue
                if id(st) in rest:
                    seg.append(cg.LocalS(rest[id(st)], None))
                seg.append(st)
            pre = [nm for i in range(a, b) for nm in decl_at[i] if nm in hoisted]
            for j in range(0, len(pre), 10):
                out.append(cg.LocalS(pre[j:j + 10], None))
            if cnt >= min_cnt and 1 < len(seg) and (b - a) < n:
                out.append(DoBlock(seg))
            else:
                out += seg
        if sum(len(declared_here(s_)) for s_ in out) <= room - 10:
            break
    return out

def extract_params(body):
    from luasym import Vararg, VarargTail
    lead = {}
    i = 0
    while i < len(body):
        st = body[i]
        if isinstance(st, cg.AssignS) and getattr(st, "is_local", False) and len(st.targets) == 1 and len(st.values.items) == 1 and st.values.tail is None and isinstance(st.values.items[0], Vararg) and st.values.items[0].i not in lead and st.targets[0].name not in lead.values():
            lead[st.values.items[0].i] = st.targets[0].name
            i += 1
            continue
        if isinstance(st, cg.CommentS) and not st.text:
            i += 1
            continue
        break

    idx, tails = [], []
    vararg_uses(body[i:], idx, tails)
    top = max(list(lead) + idx + [0])
    if tails:
        top = min(top, min(tails) - 1)
    lead = {k: nm for k, nm in lead.items() if k <= top}
    n = top
    names = []
    used = set(lead.values())
    for j in range(1, n + 1):
        nm = lead.get(j)
        if nm is None:
            nm = "arg%d" % j
            while nm in used:
                nm += "_"
            used.add(nm)
        names.append(nm)
    keep = [st for st in body[:i] if not (isinstance(st, cg.AssignS) and len(st.values.items) == 1
                                         and isinstance(st.values.items[0], Vararg)
                                         and st.values.items[0].i in lead)]
    body[:i] = keep

    def fn(x):
        if isinstance(x, Vararg):
            return cg.LocalName(names[x.i - 1]) if x.i <= n else Vararg(x.i - n)
        if isinstance(x, cg.TailRef) and isinstance(x.tail, VarargTail):
            return cg.TailRef(VarargTail(x.tail.start - n))
        if isinstance(x, cg.TailCount) and isinstance(x.tail, VarargTail):
            return cg.TailCount(VarargTail(x.tail.start - n))
        return None
    if n:
        map_body(body, fn, set())
    params = names
    if uses_varargs(body):
        params = params + ["..."]
    return params

def written_names(stmts, out):
    for st in stmts:
        if isinstance(st, stc.SIf):
            written_names(st.then, out)
            written_names(st.els, out)
        elif isinstance(st, stc.SLoop):
            written_names(st.body, out)
            if st.kind == "for":
                out.add(st.forinfo[0].name)
            elif st.kind == "forin":
                out |= {v.name for v in st.forinfo[0]}
        elif isinstance(st, DoBlock):
            written_names(st.body, out)
        else:
            out |= set(stmt_names(st)[1])

def vararg_uses(stmts, idx, tails):
    from luasym import Vararg, VarargTail

    def f(x):
        if isinstance(x, Vararg):
            idx.append(x.i)
        elif isinstance(x, cg.TailRef) and isinstance(x.tail, VarargTail):
            tails.append(x.tail.start)
        elif isinstance(x, cg.TailCount) and isinstance(x.tail, VarargTail):
            tails.append(x.tail.start)
        return None
    map_body(stmts, f, set(), inspect_only=True)

def map_body(stmts, fn, done, inspect_only=False):
    def me(e):
        if e is None:
            return None
        if inspect_only:
            for x in cg.walk(e):
                fn(x)
            return e
        return cg.map_expr(e, fn)

    def mm(m):
        if m is None:
            return None
        if inspect_only:
            for x in m.items:
                me(x)
            if m.tail is not None:
                me(cg.TailRef(m.tail))
            return m
        return cg.map_multi(m, fn)

    def lst(exprs):
        if id(exprs) in done:
            return
        done.add(id(exprs))
        exprs[:] = [me(x) for x in exprs]
    for k, st in enumerate(stmts):
        if isinstance(st, stc.SIf):
            st.cond = me(st.cond)
            map_body(st.then, fn, done, inspect_only)
            map_body(st.els, fn, done, inspect_only)
        elif isinstance(st, stc.SLoop):
            st.cond = me(st.cond)
            if st.kind in ("for", "forin"):
                lst(st.forinfo[1])
            map_body(st.body, fn, done, inspect_only)
        elif isinstance(st, DoBlock):
            map_body(st.body, fn, done, inspect_only)
        elif isinstance(st, stc.SReturn):
            st.values = mm(st.values)
        elif isinstance(st, cg.ForPrepS):
            lst(st.exprs)
        elif isinstance(st, cg.LocalS):
            st.values = mm(st.values)
        elif isinstance(st, cg.AssignS):
            st.targets = [t if isinstance(t, (cg.LocalName, Pseudo)) else me(t) for t in st.targets]
            st.values = mm(st.values)
        elif isinstance(st, (cg.CallS, cg.TempDef)):
            st.call = me(st.call)
        elif isinstance(st, cg.SetListS):
            st.tbl = me(st.tbl)
            st.values = mm(st.values)

def uses_varargs(stmts):
    from luasym import Vararg, VarargTail
    found = [False]

    def ex(e):
        for x in cg.walk(e):
            if isinstance(x, Vararg) or isinstance(x, cg.TailCount) \
                    or (isinstance(x, cg.TailRef) and isinstance(x.tail, VarargTail)):
                found[0] = True

    def multi(m):
        if m is None:
            return
        for x in m.items:
            ex(x)
        if m.tail is not None:
            ex(cg.TailRef(m.tail))

    def blk(stmts):
        for st in stmts:
            if isinstance(st, cg.AssignS):
                for t in st.targets:
                    ex(t)
                multi(st.values)
            elif isinstance(st, (cg.CallS, cg.TempDef)):
                ex(st.call)
            elif isinstance(st, cg.SetListS):
                ex(st.tbl)
                multi(st.values)
            elif isinstance(st, stc.SIf):
                ex(st.cond)
                blk(st.then)
                blk(st.els)
            elif isinstance(st, stc.SLoop):
                blk(st.body)
                if st.kind == "for":
                    for x in st.forinfo[1]:
                        ex(x)
                elif st.kind == "forin":
                    for x in st.forinfo[1]:
                        ex(x)
            elif isinstance(st, stc.SReturn):
                multi(st.values)
            elif isinstance(st, DoBlock):
                blk(st.body)
    blk(stmts)
    return found[0]
