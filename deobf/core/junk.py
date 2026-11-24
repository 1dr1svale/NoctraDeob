import sys

from localfuncs import _ast

arith = {"Add", "Sub", "Mul", "Div", "FloorDiv", "Mod", "Pow"}
compare = {"CompareEq", "CompareNe", "CompareLt", "CompareLe", "CompareGt", "CompareGe"}
bit32 = {"band", "bor", "bxor", "bnot", "lshift", "rshift", "arshift", "lrotate", "rrotate",
         "countlz", "countrz", "byteswap"}
big = 65536


def _loc(n):
    a, b = n["location"].split(" - ")
    l1, c1 = map(int, a.split(","))
    l2, c2 = map(int, b.split(","))
    return l1, c1, l2, c2


def _key(local):
    return local["location"]


class _Pass:
    def __init__(self, root):
        self.root = root
        self.numeric = set()

    def _bit32_call(self, e):
        if e.get("type") != "AstExprCall":
            return None
        f = e["func"]
        if f.get("type") != "AstExprIndexName" or f.get("index") not in bit32:
            return None
        base = f["expr"]
        if base.get("type") != "AstExprGlobal" or base.get("global") != "bit32":
            return None
        return e["args"]

    def num(self, e):
        t = e.get("type")
        if t == "AstExprConstantNumber":
            return True
        if t == "AstExprGroup":
            return self.num(e["expr"])
        if t == "AstExprLocal":
            return _key(e["local"]) in self.numeric
        if t == "AstExprUnary":
            return e.get("op") == "Minus" and self.num(e["expr"])
        if t == "AstExprBinary":
            return e.get("op") in arith and self.num(e["left"]) and self.num(e["right"])
        args = self._bit32_call(e)
        if args is not None:
            return len(args) > 0 and all(self.num(a) for a in args)
        return False

    def type_probe(self, e):
        if e.get("type") != "AstExprCall" or len(e.get("args", [])) != 1:
            return False
        f = e["func"]
        if f.get("type") != "AstExprGlobal" or f.get("global") not in ("type", "typeof"):
            return False
        return e["args"][0].get("type") in ("AstExprConstantNumber", "AstExprConstantString",
                                            "AstExprConstantBool", "AstExprConstantNil")

    def pure(self, e):
        if self.num(e):
            return True
        t = e.get("type")
        if t == "AstExprGroup":
            return self.pure(e["expr"])
        if t == "AstExprConstantString" or self.type_probe(e):
            return True
        if t == "AstExprBinary" and e.get("op") in compare:
            if self.num(e["left"]) and self.num(e["right"]):
                return True
            return e.get("op") in ("CompareEq", "CompareNe") and self.pure(e["left"]) and self.pure(e["right"])
        return False

    def has_probe(self, e):
        found = []
        _visit(e, lambda n: found.append(n) if n.get("type") == "AstExprCall" and self.type_probe(n) else None)
        return bool(found)

    def has_big(self, e):
        found = []

        def visit(n):
            if n.get("type") == "AstExprConstantNumber" and abs(n.get("value") or 0) >= big:
                found.append(n)
        _visit(e, visit)
        return bool(found)

    def _shape(self, e, refs):
        t = e.get("type")
        if t == "AstExprConstantNumber":
            return True
        if t == "AstExprGroup":
            return self._shape(e["expr"], refs)
        if t == "AstExprLocal":
            refs.add(_key(e["local"]))
            return True
        if t == "AstExprUnary":
            return e.get("op") == "Minus" and self._shape(e["expr"], refs)
        if t == "AstExprBinary":
            return e.get("op") in arith and self._shape(e["left"], refs) and self._shape(e["right"], refs)
        args = self._bit32_call(e)
        if args is not None:
            return len(args) > 0 and all(self._shape(a, refs) for a in args)
        return False

    def run(self):
        decls = {}
        assigns = {}
        expr_stmts = []

        def collect(n):
            t = n.get("type")
            if t == "AstStatLocal":
                vs, xs = n.get("vars", []), n.get("values", [])
                if len(vs) == len(xs):
                    for v, x in zip(vs, xs):
                        decls[_key(v)] = (n, x)
            elif t == "AstStatAssign":
                vs, xs = n.get("vars", []), n.get("values", [])
                for i, v in enumerate(vs):
                    if v.get("type") == "AstExprLocal":
                        x = xs[i] if len(vs) == len(xs) else None
                        assigns.setdefault(_key(v["local"]), []).append((n, x))
            elif t == "AstStatCompoundAssign":
                v = n.get("var")
                if v and v.get("type") == "AstExprLocal":
                    ok = n.get("op") in arith
                    assigns.setdefault(_key(v["local"]), []).append((n, n.get("value") if ok else None))
            elif t == "AstStatExpr":
                expr_stmts.append(n)
        _visit(self.root, collect)

        needs = {}
        users = {}
        out = []
        for k, (_, x) in decls.items():
            refs = set()
            ok = self._shape(x, refs)
            for _, v in assigns.get(k, ()):
                ok = ok and v is not None and self._shape(v, refs)
            needs[k] = refs
            for r in refs:
                users.setdefault(r, set()).add(k)
            if not ok:
                out.append(k)
        self.numeric = set(decls)
        for k, refs in needs.items():
            if k in self.numeric and any(r not in decls for r in refs):
                out.append(k)
        while out:
            k = out.pop()
            if k not in self.numeric:
                continue
            self.numeric.discard(k)
            out.extend(u for u in users.get(k, ()) if u in self.numeric)

        dropped = {id(s): s for s in expr_stmts if self.pure(s["expr"])}

        tests = {k for k, (_, x) in decls.items()
                 if k not in self.numeric and not assigns.get(k) and self.pure(x)
                 and x.get("type") != "AstExprConstantString"}
        pool = self.numeric | tests
        init_refs = {}
        fed_by = {}
        for k in pool:
            refs = set()
            _visit(decls[k][1], lambda n: refs.add(_key(n["local"])) if n.get("type") == "AstExprLocal" else None)
            init_refs[k] = refs
            for r in refs:
                fed_by.setdefault(r, set()).add(k)
        dead = set()
        work = [k for k in pool if self.has_big(decls[k][1]) or self.has_probe(decls[k][1])]
        while work:
            k = work.pop()
            if k in dead:
                continue
            dead.add(k)
            work.extend(u for u in fed_by.get(k, ()) if u in pool and u not in dead)

        def stmt_targets(s):
            t = s.get("type")
            if t == "AstStatLocal":
                return [_key(v) for v in s.get("vars", [])]
            if t == "AstStatAssign":
                return [_key(v["local"]) if v.get("type") == "AstExprLocal" else None for v in s.get("vars", [])]
            if t == "AstStatCompoundAssign":
                v = s.get("var")
                return [_key(v["local"]) if v and v.get("type") == "AstExprLocal" else None]
            return [None]

        writers = {}
        writes_of = {}
        for k in dead:
            for s in [decls[k][0]] + [s for s, _ in assigns.get(k, ())]:
                writers[id(s)] = s
                writes_of.setdefault(k, []).append(id(s))
        targets = {sid: stmt_targets(s) for sid, s in writers.items()}
        reads_in = {sid: set() for sid in writers}
        alive = []

        def scan(n, owner):
            if isinstance(n, list):
                for v in n:
                    scan(v, owner)
                return
            if not isinstance(n, dict):
                return
            if id(n) in dropped:
                owner = "junk"
            elif id(n) in writers:
                owner = id(n)
            if n.get("type") == "AstExprLocal":
                k = _key(n["local"])
                if k in dead:
                    if owner is None:
                        alive.append(k)
                    elif owner != "junk":
                        reads_in[owner].add(k)
            for v in n.values():
                if isinstance(v, (dict, list)):
                    scan(v, owner)
        scan(self.root, None)

        for sid, ts in targets.items():
            if any(t not in dead for t in ts):
                alive.extend(t for t in ts if t in dead)
        revived = set()
        while alive:
            k = alive.pop()
            if k not in dead:
                continue
            dead.discard(k)
            for sid in writes_of.get(k, ()):
                if sid in revived:
                    continue
                revived.add(sid)
                alive.extend(t for t in targets[sid] if t in dead)
                alive.extend(r for r in reads_in[sid] if r in dead)

        victims = dict(dropped)
        for k in dead:
            for sid in writes_of.get(k, ()):
                victims[sid] = writers[sid]
        return list(victims.values())


def _visit(n, fn):
    if isinstance(n, dict):
        fn(n)
        for v in n.values():
            if isinstance(v, (dict, list)):
                _visit(v, fn)
    elif isinstance(n, list):
        for v in n:
            _visit(v, fn)


def strip(text, rounds=4):
    original = text
    total = 0
    for _ in range(rounds):
        try:
            root = _ast(text)
        except Exception:
            return original if total == 0 else text
        victims = _Pass(root).run()
        if not victims:
            break
        lines = text.split("\n")
        raw = [ln.encode("utf-8") for ln in lines]
        kill = set()
        for s in victims:
            l1, c1, l2, c2 = _loc(s)
            if l2 >= len(raw):
                continue
            if raw[l1][:c1].strip() or raw[l2][c2:].strip(b" \t;"):
                continue
            kill.update(range(l1, l2 + 1))
        if not kill:
            break
        kept = []
        for i, ln in enumerate(lines):
            if i in kill:
                continue
            if ln.strip() == "" and kept and kept[-1].strip() == "" and (i - 1) in kill:
                continue
            kept.append(ln)
        while kept and kept[0].strip() == "":
            kept.pop(0)
        new = "\n".join(kept)
        try:
            _ast(new)
        except Exception:
            break
        text = new
        total += len(kill)
    if total:
        from obfuscators.luraph_v15 import ui
        ui.note("removed %d line(s) of Luraph key-number noise" % total)
    return text


def fold_defaults(text):
    try:
        root = _ast(text)
    except Exception:
        return text
    lines = text.split("\n")
    raw = [ln.encode("utf-8") for ln in lines]
    edits = []

    def src(n):
        l1, c1, l2, c2 = _loc(n)
        return raw[l1][c1:c2].decode("utf-8") if l1 == l2 else None

    def single_assign(block, key):
        body = (block or {}).get("body") or []
        if len(body) != 1 or body[0].get("type") != "AstStatAssign":
            return None
        st = body[0]
        if len(st["vars"]) != 1 or len(st["values"]) != 1:
            return None
        v = st["vars"][0]
        if v.get("type") != "AstExprLocal" or _key(v["local"]) != key:
            return None
        return st["values"][0]

    def whole_lines(n):
        l1, c1, l2, c2 = _loc(n)
        return not (raw[l1][:c1].strip() or raw[l2][c2:].strip(b" \t;"))

    def block(n):
        if n.get("type") != "AstStatBlock":
            return
        body = n.get("body") or []
        for i, (a, b) in enumerate(zip(body, body[1:])):
            if a.get("type") != "AstStatLocal" or len(a.get("vars", [])) != 1 or a.get("values"):
                continue
            if b.get("type") != "AstStatIf" or (b.get("elsebody") or {}).get("type") != "AstStatBlock":
                continue
            cond = b["condition"]
            if cond.get("type") != "AstExprLocal":
                continue
            x, ck = _key(a["vars"][0]), _key(cond["local"])
            t, e = single_assign(b["thenbody"], x), single_assign(b["elsebody"], x)
            if t is None or e is None or x == ck:
                continue

            def is_cond(v):
                return v.get("type") == "AstExprLocal" and _key(v["local"]) == ck
            if is_cond(t) and not is_cond(e):
                op, other = "or", e
            elif is_cond(e) and not is_cond(t):
                op, other = "and", t
            else:
                continue
            text_other = src(other)
            if text_other is None:
                continue
            if op == "and" and other.get("type") == "AstExprBinary" and other.get("op") == "Or":
                text_other = "(" + text_other + ")"
            al1, ac1, al2, ac2 = _loc(a)
            bl1, bc1, bl2, bc2 = _loc(b)
            if raw[al1][:ac1].strip() or raw[al2][ac2:].strip(b" \t;") or raw[bl1][:bc1].strip() \
                    or raw[bl2][bc2:].strip(b" \t;"):
                continue
            if any(raw[i].strip() for i in range(al2 + 1, bl1)):
                continue
            indent = raw[al1][:ac1].decode("utf-8")
            first, left = al1, cond["local"]["name"]
            prev = body[i - 1] if i > 0 else None
            if prev is not None and prev.get("type") == "AstStatLocal" and len(prev.get("vars", [])) == 1 \
                    and len(prev.get("values", [])) == 1 and _key(prev["vars"][0]) == ck \
                    and uses.get(ck, 0) == 2 and whole_lines(prev):
                value = prev["values"][0]
                text_value = src(value)
                pl1, _pc1, pl2, _pc2 = _loc(prev)
                if text_value is not None and pl1 == pl2 and not any(raw[j].strip() for j in range(pl2 + 1, al1)):
                    vt = value.get("type")
                    if vt == "AstExprIfElse" or (op == "and" and vt == "AstExprBinary" and value.get("op") == "Or"):
                        text_value = "(" + text_value + ")"
                    first, left = pl1, text_value
            edits.append((first, bl2, "%slocal %s = %s %s %s" % (
                indent, a["vars"][0]["name"], left, op, text_other)))

    uses = {}

    def count(n):
        if n.get("type") == "AstExprLocal":
            k = _key(n["local"])
            uses[k] = uses.get(k, 0) + 1
    _visit(root, count)
    _visit(root, block)
    if not edits:
        return text
    for l1, l2, new in sorted(edits, reverse=True):
        lines[l1:l2 + 1] = [new]
    out = "\n".join(lines)
    try:
        _ast(out)
    except Exception:
        return text
    return out


if __name__ == "__main__":
    p = sys.argv[1]
    with open(p, encoding="utf-8") as f:
        t = f.read()
    sys.stdout.write(fold_defaults(strip(t)))
