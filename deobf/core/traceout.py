import os
import re
import sys

def stmt_count(body):
    m = re.search(r"-- (\d+) statements recorded", body)
    return int(m.group(1)) if m else 0

def take_line(body, name):
    import harness
    m = re.search(re.escape(harness.mark(name + " ")) + r"([^\n]*)\n", body)
    if not m:
        return None, body
    return m.group(1), body[:m.start()] + body[m.end():]

def take_strings(body):
    import harness
    s = harness.mark("ENVLOG-STRINGS\n")
    if s in body:
        body, strings = body.split(s, 1)
        return body, strings
    return body, None

def header(input_path, notes=()):
    return "".join("-- %s\n" % n for n in notes)

def render(text, args, preamble=True):
    if os.environ.get("DEOB_PRETIDY"):
        with open(os.environ["DEOB_PRETIDY"], "w", encoding="utf-8", newline="\n") as f:
            f.write(text)
    if not args.no_tidy:
        import tidy
        import spacing
        t = tidy.tidy(text, preamble=preamble and not args.keep_preamble, fold_code=not args.no_fold)
        return spacing.space(t)
    import fold
    return fold.strip_markers(text)

def status_line(body):
    status = body.splitlines()[0] if body else ""
    print("[*] " + status.lstrip("- "), file=sys.stderr)
