import http.server
import json
import os
import queue
import re
import secrets
import subprocess
import sys
import threading
import time
import urllib.request
import zipfile

here = os.path.dirname(os.path.abspath(__file__))
bin_dir = os.path.join(here, "..", "bin") if os.path.exists(os.path.join(here, "..", "bin")) else os.path.join(here, "bin")
runtime_dir = os.path.join(here, "..", "runtime") if os.path.exists(os.path.join(here, "..", "runtime")) else here
luau_url = "https://github.com/luau-lang/luau/releases/latest/download/luau-windows.zip"

with open(os.path.join(here, "..", "protocol.json"), encoding="utf-8") as _pf:
    proto = json.load(_pf)

def proto_lua():
    ch = proto["chunk_hash"]
    return ("local protocol = { hash_mult = %d, hash_mod = %d, hash_stride = %d, chunk_min = %d }"
            % (ch["multiplier"], ch["modulus"], ch["stride"], ch["min_len"]))

proto_line_re = re.compile(r"local protocol = \{[^}]*\}")

def _ensure_exec(p):
    if os.name != "nt" and os.path.exists(p) and not os.access(p, os.X_OK):
        try:
            os.chmod(p, 0o755)
        except OSError:
            pass
    return p

def find_luau():
    exe = "luau.exe" if os.name == "nt" else "luau"
    local = os.path.join(bin_dir, exe)
    if os.path.exists(local):
        return _ensure_exec(local)
    for d in os.environ.get("PATH", "").split(os.pathsep):
        p = os.path.join(d, exe)
        if os.path.exists(p):
            return _ensure_exec(p)
    if os.name != "nt":
        sys.exit("luau not found: build it with `python build_luau.py` (needs git, cmake, a C++ "
                 "compiler) or put one in " + bin_dir)
    print("[*] downloading Luau runtime...", file=sys.stderr)
    print("[!] stock Luau lacks the Vector3 members (v:Dot, v.Magnitude, ...): build the patched "
          "runtime with `python build_luau.py`", file=sys.stderr)
    os.makedirs(bin_dir, exist_ok=True)
    zpath = os.path.join(bin_dir, "luau.zip")
    urllib.request.urlretrieve(luau_url, zpath)
    with zipfile.ZipFile(zpath) as z:
        for name in ("luau.exe", "luau-ast.exe"):
            z.extract(name, bin_dir)
    os.remove(zpath)
    return local

def luau_ast():
    return _ensure_exec(os.path.join(bin_dir, "luau-ast.exe" if os.name == "nt" else "luau-ast"))

ast_timeout = 120

def run_luau_ast(path):
    exe = luau_ast()
    if not os.path.exists(exe):
        for d in os.environ.get("PATH", "").split(os.pathsep):
            cand = os.path.join(d, "luau-ast.exe" if os.name == "nt" else "luau-ast")
            if os.path.exists(cand):
                exe = cand
                break
        else:
            raise RuntimeError("luau-ast not found: build it with `python build_luau.py`"
                               " (needs git, cmake, a C++ compiler) or put it in " + bin_dir)
    try:
        return subprocess.run([exe, path], capture_output=True, timeout=ast_timeout)
    except subprocess.TimeoutExpired:
        raise RuntimeError("luau-ast timed out after %ss on %s (binary hung or machine overloaded)"
                           % (ast_timeout, path))

def long_string(s):
    level = 0
    while ("]" + "=" * level + "]") in s:
        level += 1
    eq = "=" * level

    return "[" + eq + "[\n" + s + "]" + eq + "]"

def lua_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (list, tuple)):
        return "{" + ", ".join(lua_value(x) for x in v) + "}"
    if isinstance(v, dict):
        return "{" + ", ".join("[%s] = %s" % (lua_value(k), lua_value(x)) for k, x in v.items()) + "}"
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n").replace("\r", "\\r") + '"'
    return str(v)

def parse_cfg_value(v):
    if v.startswith("@file:"):
        with open(v[6:], encoding="utf-8") as f:
            v = f.read().strip()
    return True if v in ("", "true") else False if v == "false" else \
        int(v) if re.fullmatch(r"-?\d+", v) else v

def user_cfg(args, cfg):
    for kv in args.cfg:
        k, _, v = kv.partition("=")
        cfg[k] = parse_cfg_value(v)
    return cfg

p2d_cache = {}

def p2d_cache_path(input_path):
    return re.sub(r"(\.luau?|\.txt)?$", ".path2d", input_path, count=1)

def load_p2d_cache(input_path, studio=False):
    cache_path = p2d_cache_path(input_path)
    if os.path.exists(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            for line in f:
                k, _, v = line.rstrip("\n").partition("\t")
                if k:
                    p2d_cache[k] = v
        if not studio:
            print("[*] replaying %d recorded Path2D results from %s" % (len(p2d_cache), cache_path), file=sys.stderr)
    return cache_path

def take_p2d(body, cache_path, studio):
    rec = re.findall(mark("P2D ") + r"([^\t\n]+)\t([^\n]*)\n", body)
    body = re.sub(mark("P2D ") + r"[^\n]*\n", "", body)
    nmodel = sum(1 for k, v in rec if v.endswith("\tmodel"))
    if nmodel:
        print("[*] %d Path2D answers computed by the offline engine model" % nmodel, file=sys.stderr)
    rec = [(k, v) for k, v in rec if not v.endswith("\tmodel")]
    if rec and studio:
        for k, v in rec:
            p2d_cache[k] = v
        with open(cache_path, "w", encoding="utf-8", newline="\n") as f:
            f.write("".join("%s\t%s\n" % kv for kv in p2d_cache.items()))
    return body

def p2d_miss(body, cache_path):
    if mark("P2DMISS") not in body:
        return body
    print("[!] this script derives keys from a Path2D call the offline model does not cover\n"
          "    (e.g. a Frame sized with Scale); run it once with --studio (writes %s)" % cache_path,
          file=sys.stderr)
    return body.replace(mark("P2DMISS") + "\n", "")

shield_stdlib = """{
        string = string, math = math, table = table, os = os, debug = debug,
        coroutine = coroutine, bit32 = bit32, buffer = buffer, utf8 = utf8, vector = vector,
        type = type, typeof = typeof, pairs = pairs, ipairs = ipairs, next = next,
        select = select, rawget = rawget, rawset = rawset, rawequal = rawequal,
        rawlen = rawlen, setmetatable = setmetatable, getmetatable = getmetatable,
        tostring = tostring, tonumber = tonumber, error = error, assert = assert, print = print,
        pcall = pcall, xpcall = xpcall, unpack = table.unpack, newproxy = newproxy,
}"""

def build_harness(source, cfg, chunks=None):
    with open(os.path.join(runtime_dir, "envlog.luau"), encoding="utf-8") as f:
        runtime = f.read()
    cfg_lua = "{" + ", ".join("%s = %s" % (k, lua_value(v)) for k, v in cfg.items()) + "}"

    runtime = runtime.replace("--!nocheck", "", 1)
    if not proto_line_re.search(runtime):
        raise RuntimeError("runtime/envlog.luau lost its `local protocol = {...}` line; "
                           "restore it (see protocol.json)")
    runtime = proto_line_re.sub(proto_lua(), runtime, count=1)
    with open(os.path.join(runtime_dir, "unicode_data.luau"), encoding="ascii") as f:
        udata = f.read()
    with open(os.path.join(runtime_dir, "roblox_api.luau"), encoding="ascii") as f:
        rdata = f.read()
    with open(os.path.join(runtime_dir, "datatypes.luau"), encoding="utf-8") as f:
        dtypes = f.read().replace("--!nocheck", "", 1)
    last_mark[0] = secrets.token_hex(proto["nonce_hex_bytes"])
    return ("local __stdlib = " + shield_stdlib + "\n"
            "local __shield = setmetatable({}, { __index = __stdlib })\n"
            "local __unicode = (function()\n" + udata + "\nend)()\n"
            "local __roblox = (function()\n" + rdata + "\nend)()\n"
            "__roblox.datatypes = (function()\n" + dtypes + "\nend)()\n"
            "local __raw = { getfenv = getfenv, setfenv = setfenv, loadstring = loadstring }\n"
            "local __run = function(__mark, __source, __config, __p2d, __chunks, __unicode, __roblox, __raw)\n"
            + runtime + "\n"
            "end\n"
            "setfenv(__run, __shield)\n"
            "return __run(" + lua_value(last_mark[0]) + ", " + long_string(source) + ", " + cfg_lua + ",\n"
            "  {" + "".join("[%s] = %s,\n" % (lua_value(k), lua_value(v))
                             for k, v in p2d_cache.items()) + "},\n"
            "  {" + "".join("[%s] = %s,\n" % (lua_value(k), long_string(v))
                             for k, v in (chunks or {}).items()) + "}, __unicode, __roblox, __raw)\n")

def chunk_key(src):
    h = 0
    for b in src.encode("latin-1"):
        h = (h * proto["chunk_hash"]["multiplier"] + b) % proto["chunk_hash"]["modulus"]
    return "%d_%d" % (len(src), h)

def take_chunks(body):
    found = re.findall(mark("CHUNK ") + r"(\S+)\n([0-9a-f]*)\n", body)
    body = re.sub(mark("CHUNK ") + r"\S+\n[0-9a-f]*\n", "", body)
    return [(k, bytes.fromhex(hx).decode("latin-1")) for k, hx in found], body

last_raw = [""]

last_mark = [""]

def mark(s):
    return "\x00" + last_mark[0] + s

heartbeat_seconds = proto["heartbeat_seconds"]
stall_seconds = proto["stall_seconds"]

def _communicate(cmd, timeout, stall):
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    parts = {1: [], 2: []}
    last = [time.time()]

    def pump(stream, key):
        while True:
            b = stream.read1(65536) if hasattr(stream, "read1") else stream.read(65536)
            if not b:
                return
            parts[key].append(b)
            last[0] = time.time()
    threads = [threading.Thread(target=pump, args=(proc.stdout, 1), daemon=True),
               threading.Thread(target=pump, args=(proc.stderr, 2), daemon=True)]
    for t in threads:
        t.start()
    t0 = time.time()
    try:
        while proc.poll() is None:
            now = time.time()
            if now - t0 > timeout or (stall and now - last[0] > stall):
                proc.kill()
                proc.wait()
                raise subprocess.TimeoutExpired(cmd, now - t0)
            time.sleep(0.1)
    finally:
        for t in threads:
            t.join(5)
    return b"".join(parts[1]), b"".join(parts[2])

def run_once(luau, source, cfg, hpath, timeout, keep, chunks=None):
    cfg = dict(cfg, heartbeat=heartbeat_seconds) if "heartbeat" not in cfg else cfg
    with open(hpath, "w", encoding="latin-1", newline="\n") as f:
        f.write(build_harness(source, cfg, chunks))
    try:
        out, errb = _communicate([luau, hpath], timeout, stall_seconds if cfg.get("heartbeat") else None)
    except subprocess.TimeoutExpired as e:
        return None, "timed out after %ds (script is stuck in a loop the tracer cannot see)" % e.timeout
    finally:
        if not keep and os.path.exists(hpath):
            os.remove(hpath)
    stdout = re.sub(mark("HB") + r"\r?\n {16384}\r?\n", "", out.decode("utf-8", "replace")).replace("\r\n", "\n")
    last_raw[0] = stdout + errb.decode("utf-8", "replace")
    m = re.search(mark("ENVLOG-BEGIN") + r"\n(.*?)" + mark("ENVLOG-END"), stdout, re.S)
    if not m:
        return None, stdout[-3000:] + "\n" + errb.decode("utf-8", "replace")[-3000:]

    body = m.group(1)
    for hp in {hpath, hpath.replace("\\", "/")}:
        if hp + ":" in body:
            body = re.sub(re.escape(hp) + r":\d+: ", "", body)
    return body, None

def save_raw(path):
    if path:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(last_raw[0])

class HarnessServer:
    def __init__(self, luau, source, cfg, chunks):
        import tempfile
        _ensure_exec(luau)
        self.dir = tempfile.mkdtemp(prefix="deobf_serve_")
        with open(os.path.join(self.dir, "harness.luau"), "w", encoding="latin-1", newline="\n") as f:
            f.write(build_harness(source, dict(cfg, serve=True), chunks))
        self.end_mark = mark("ENVLOG-END").encode()
        self.proc = subprocess.Popen([luau], cwd=self.dir, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT)
        self.buf = b""
        self.eof = False
        self.nreq = 0

        self.deadline = None
        self.timed_out = False
        threading.Thread(target=self._watchdog, daemon=True).start()

        self._send(b'__s = require("./harness")\n__s("", "", "start")\n')

    def _watchdog(self):
        while self.proc.poll() is None:
            d = self.deadline
            if d is not None and time.time() > d:
                self.timed_out = True
                self.proc.kill()
                return
            time.sleep(0.25)

    def _send(self, line):
        try:
            self.proc.stdin.write(line)
            self.proc.stdin.flush()
        except OSError:
            pass

    def reply(self, timeout):
        self.deadline = time.time() + timeout
        try:
            start = 0
            while self.end_mark not in self.buf[start:]:
                start = max(0, len(self.buf) - len(self.end_mark))
                b = b"" if self.eof else self.proc.stdout.read1(1 << 20)
                if not b:
                    self.eof = True
                    out = self.buf.decode("utf-8", "replace")
                    self.close()
                    return None, ("no reply within %ds" % timeout if self.timed_out else
                                  "harness process exited") + ": " + out[-3000:]
                self.buf += b
        finally:
            self.deadline = None
        i = self.buf.index(self.end_mark) + len(self.end_mark)
        out, self.buf = self.buf[:i], self.buf[i:]
        out = out.decode("utf-8", "replace").replace("\r\n", "\n")
        last_raw[0] = out
        m = re.search(mark("ENVLOG-BEGIN") + r"\n(.*?)" + mark("ENVLOG-END"), out, re.S)
        if not m:
            return None, out[-3000:]
        return m.group(1), None

    def request(self, cfg, timeout, mode="dump"):
        req, buf = cfg.get("force_req") or "", cfg.get("force_buf") or ""
        if len(req) + len(buf) < 2000 and re.fullmatch(r"[\w,@.;=+/:*\-]*", req + buf):
            self._send(('__s("%s", "%s", "%s")\n' % (req, buf, mode)).encode())
            return self.reply(timeout)
        self.nreq += 1
        name = "req_%d" % self.nreq
        with open(os.path.join(self.dir, name + ".luau"), "w", encoding="utf-8", newline="\n") as f:
            f.write("return {%s, %s, %s}\n" % (long_string(cfg.get("force_req") or ""),
                                              long_string(cfg.get("force_buf") or ""), long_string(mode)))
        self._send(b'__s(table.unpack(require("./%s")))\n' % name.encode())
        return self.reply(timeout)

    def fetch(self, paths, bufs, timeout):
        body, err = self.request({"force_req": ";".join(paths), "force_buf": bufs}, timeout, "fetch")
        if body is None:
            raise RuntimeError("harness fetch failed: " + err[-300:])
        m = re.search(mark("FETCH ") + r"([^\n]*)\n", body)
        if not m or m.group(1).startswith("error:"):
            raise RuntimeError("harness fetch failed: " + (m.group(1)[:300] if m else body[-300:]))
        return m.group(1)

    def close(self):
        if self.proc.poll() is None:
            self.proc.kill()
            self.proc.wait()
        import shutil
        shutil.rmtree(self.dir, ignore_errors=True)

def trace_text(body):
    body = re.sub(r"\x00[0-9a-f]{8,32}CHUNK \S+\n[0-9a-f]*\n", "", body)
    body = re.sub(r"\x00[0-9a-f]{8,32}(PROTOS|FORCE|P2D|TRIGGER|AUDIT|UNSCRAMBLED)[^\n]*\n?", "", body)

    body = re.sub(r"(?<=[ \t])(?=\S)(?:[A-Za-z]:)?[^:\n]*?\.luau:", "harness:", body)
    body = re.sub(r"harness:\d+: ", "", body)
    body = re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', body)
    return re.sub(r"\d+(?:\.\d+)?(?:e[-+]?\d+)?", "0", body)

def same_trace(a, b):
    if a == b:
        return True
    wa, wb = set(re.findall(r"\w+", a)), set(re.findall(r"\w+", b))
    only = (wa ^ wb)
    mask = lambda t: re.sub(r"\w+", lambda m: "_" if m.group(0) in only else m.group(0), t)
    ma, mb = mask(a), mask(b)
    if ma == mb:
        return True

    decl = r"\blocal\s+([\w ,]+)|\bfor\s+([\w ,]+)\bin\b|\bfunction\s*\w*\s*\(([\w ,.]*)\)"
    names = set()
    for m in re.finditer(decl, a + "\n" + b):
        names.update(re.findall(r"\w+", "".join(g or "" for g in m.groups())))
    anon = lambda t: sorted(re.sub(r"\w+", lambda m: "_" if m.group(0) in names else m.group(0), t)
                            .splitlines())
    return anon(ma) == anon(mb)

studio_loader = r"""local httpService = game:GetService("HttpService")
local base = "http://127.0.0.1:%d"
local was = httpService.HttpEnabled
httpService.HttpEnabled = true
local ok0, err0 = pcall(function()
        while true do
                local src = httpService:GetAsync(base .. "/harness", true)
                if src == "" then break end
                httpService.HttpEnabled = false
                local f, err = loadstring(src, "=harness")
                local ok, out = false, err
                if f then ok, out = pcall(f) end
                httpService.HttpEnabled = true
                out = ok and tostring(out) or ("\0ENVLOG-FAIL\n" .. tostring(out))
                local n = math.max(1, math.ceil(#out / 900000))
                for i = 1, n do
                        httpService:PostAsync(base .. "/result?part=" .. i .. "&of=" .. n, string.sub(out, (i - 1) * 900000 + 1, i * 900000),
                                Enum.HttpContentType.TextPlain)
                end
        end
end)
httpService.HttpEnabled = was
return ok0 and "deobf: done" or ("deobf loader error: " .. tostring(err0))
"""

class StudioBridge:
    def __init__(self, port):
        self.jobs = queue.Queue()
        self.results = queue.Queue()
        self.parts = []
        bridge = self

        class Handler(http.server.BaseHTTPRequestHandler):
            def log_message(self, *a):
                pass

            def do_GET(self):
                if self.path != "/harness":
                    self.send_error(404)
                    return
                body = bridge.jobs.get()
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def do_POST(self):
                data = self.rfile.read(int(self.headers.get("Content-Length", 0)))
                self.send_response(200)
                self.send_header("Content-Length", "0")
                self.end_headers()
                m = re.search(r"part=(\d+)&of=(\d+)", self.path)
                part, of = (int(m.group(1)), int(m.group(2))) if m else (1, 1)
                bridge.parts.append(data)
                if part == of:
                    bridge.results.put(b"".join(bridge.parts))
                    bridge.parts = []

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", port), Handler)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()

    def run(self, harness, timeout):
        self.jobs.put(harness.encode("latin-1"))
        try:
            return self.results.get(timeout=timeout).decode("utf-8", "replace")
        except queue.Empty:
            return None

    def finish(self):
        self.jobs.put(b"")
        time.sleep(1)

def run_once_studio(bridge, source, cfg, timeout, chunks=None):
    out = bridge.run(build_harness(source, dict(cfg, native=True), chunks), timeout)
    if out is None:
        return None, "no result from Studio within %ds (is the loader running?)" % timeout
    out = out.replace("\r\n", "\n")
    last_raw[0] = out
    if out.startswith("\x00ENVLOG-FAIL"):
        return None, "harness failed in Studio: " + out[len("\x00ENVLOG-FAIL\n"):]
    m = re.search(mark("ENVLOG-BEGIN") + r"\n(.*?)" + mark("ENVLOG-END"), out, re.S)
    if not m:
        return None, out[-3000:]
    return m.group(1), None

class Runner:
    def __init__(self, job):
        self.job = job
        args = job.args
        self.bridge = None
        self.luau = None
        self.hpath = job.trace_path + ".harness.luau"
        if args.studio:
            self.bridge = StudioBridge(args.port)
            lpath = re.sub(r"\.luau$", "", job.trace_path) + ".studio_loader.luau"
            with open(lpath, "w", encoding="utf-8", newline="\n") as f:
                f.write(studio_loader % args.port)
            print("[*] Studio mode: run %s in the Studio command bar (Edit mode)" % lpath, file=sys.stderr)
        else:
            self.luau = find_luau()

    def run(self, source, cfg, chunks=None):
        a = self.job.args
        if self.bridge:
            return run_once_studio(self.bridge, source, cfg, a.studio_wait, chunks)
        return run_once(self.luau, source, cfg, self.hpath, a.timeout, a.keep_harness, chunks)

    def finish(self):
        if self.bridge:
            self.bridge.finish()
            self.bridge = None
