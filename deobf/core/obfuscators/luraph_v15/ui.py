import os
import sys

stream = sys.stderr
enabled = stream.isatty() and not os.environ.get("NO_COLOR") and os.environ.get("TERM") != "dumb"


def _wrap(code):
    def f(s):
        if enabled:
            return "\x1b[%sm%s\x1b[0m" % (code, s)
        return str(s)
    return f


dim = _wrap("2")
bold = _wrap("1")
red = _wrap("31")
green = _wrap("32")
yellow = _wrap("33")
cyan = _wrap("36")
gray = _wrap("90")
bold_cyan = _wrap("1;36")
bold_green = _wrap("1;32")


def line(s=""):
    if enabled:
        stream.write("\r\x1b[K")
    stream.write(s + "\n")
    stream.flush()


def step(msg, tag=None):
    line()
    line("  " + bold_cyan("→ ") + bold(msg) + ("   " + gray(tag) if tag else ""))


def _sub(symbol, color, msg):
    line("     " + color(symbol) + "  " + msg)


def ok(msg):
    _sub("✓", green, msg)


def warn(msg):
    _sub("!", yellow, msg)


def fail(msg):
    _sub("✗", red, msg)


def note(msg):
    _sub("·", gray, gray(msg))


_frames = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"


def progress(done, total, activity, elapsed, frame):
    width = 22
    spin = _frames[frame % len(_frames)]
    mm, ss = int(elapsed) // 60, int(elapsed) % 60
    if total and done <= total:
        frac = done / float(total)
        filled = int(round(frac * width))
        bar = green("█" * filled) + dim("░" * (width - filled))
        pct = "%3d%%" % int(frac * 100)
        count = "%d/%d functions" % (done, total)
    else:
        pos = frame % (width * 2)
        if pos >= width:
            pos = width * 2 - 1 - pos
        cells = ["░"] * width
        for i in range(max(0, pos - 1), min(width, pos + 2)):
            cells[i] = "█"
        bar = green("".join(cells[:pos + 2])) + dim("".join(cells[pos + 2:]))
        pct = "  ··"
        count = "%d functions" % done
    head = ("     %s  ▕%s▏ %s   %s   %dm%02ds"
            % (cyan(spin), bar, pct, count, mm, ss))
    if activity:
        head += "   " + gray("· " + activity)
    if enabled:
        stream.write("\r\x1b[K" + head)
    else:
        stream.write(head + "\n")
    stream.flush()


def progress_clear():
    if enabled:
        stream.write("\r\x1b[K")
        stream.flush()


def is_tty():
    return enabled
