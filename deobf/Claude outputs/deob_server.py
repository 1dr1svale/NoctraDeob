import http.server
import socketserver
import json
import os
import sys
import subprocess

here = os.path.dirname(os.path.abspath(__file__))
instrumented_path = os.path.join(here, "instrumented.luau")
capture_path = os.path.join(here, "capture.json")

# your deobf folder. override with the DEOB_ROOT env var if it ever moves.
default_deob_root = r"C:\Users\temuun\OneDrive\Desktop\tools\luraph-deobfuscator better\deobf"
deob_root = os.environ.get("DEOB_ROOT", "") or default_deob_root

port = int(os.environ.get("PORT", "8000"))


class handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code, body, ctype="text/plain"):
        data = body.encode("utf-8") if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.startswith("/script"):
            try:
                src = self._instrumented()
            except Exception as e:
                import traceback
                traceback.print_exc()
                print("[server] ERROR building script: %s" % e)
                self._send(500, "could not instrument: %s" % e)
                return
            print("[server] sent instrumented script (%d bytes)" % len(src))
            self._send(200, src)
        else:
            self._send(200, "deob server up. Studio runner should GET /script and POST /capture")

    def _instrumented(self):
        raw_in = os.path.join(here, "script.lua")
        if not os.path.exists(raw_in):
            raise RuntimeError("put your obfuscated script next to the server as script.lua")
        vmmap = os.path.join(deob_root, "src", "vmmap.js")
        if not os.path.exists(vmmap):
            raise RuntimeError("can't find %s - fix default_deob_root at the top of this file" % vmmap)
        need = (not os.path.exists(instrumented_path)
                or os.path.getmtime(instrumented_path) < os.path.getmtime(raw_in))
        if need:
            helper = os.path.join(here, "instrument.js")
            print("[server] instrumenting script.lua with %s ..." % vmmap)
            try:
                r = subprocess.run(["node", helper, raw_in, instrumented_path, vmmap],
                                   capture_output=True, text=True, timeout=300)
            except FileNotFoundError:
                raise RuntimeError("node (Node.js) was not found on PATH - open the server from a "
                                   "terminal where `node --version` works")
            if r.returncode != 0 or not os.path.exists(instrumented_path):
                raise RuntimeError("instrument.js failed: " + ((r.stderr or r.stdout) or "")[-800:])
            print("[server] " + (r.stdout or "").strip())
        with open(instrumented_path, "r", encoding="latin-1") as f:
            return f.read()

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length)
        print("[server] received capture: %d bytes" % len(raw))
        with open(capture_path, "wb") as f:
            f.write(raw)
        print("[server] saved to %s" % capture_path)
        summary = self._lift(raw)
        self._send(200, summary)

    def _lift(self, raw):
        try:
            cap = json.loads(raw)
        except Exception as e:
            return "capture was not valid JSON: %s" % e
        nprotos = len(cap.get("protos", {})) if isinstance(cap, dict) else 0
        msg = "saved capture.json (%d protos captured). " % nprotos
        if not deob_root:
            return msg + ("Set DEOB_ROOT to your deobf folder and I will run the lifter automatically; "
                          "for now, send me capture.json.")
        protos_json = self._convert(cap)
        pj = os.path.join(here, "script.protos.json")
        with open(pj, "w", encoding="utf-8") as f:
            json.dump(protos_json, f)
        src_lua = os.path.join(here, "source_for_lift.luau")
        with open(src_lua, "w", encoding="latin-1") as f:
            f.write(cap.get("source", ""))
        out = os.path.join(here, "deobfuscated.luau")
        devirt = os.path.join(deob_root, "core", "obfuscators", "luraph_v15", "devirt.py")
        env = dict(os.environ)
        env["PYTHONPATH"] = os.path.join(deob_root, "core")
        try:
            r = subprocess.run([sys.executable, "-I", devirt, src_lua, pj, "--all", out],
                               env=env, capture_output=True, text=True, timeout=1200)
            return msg + "\nlifter: " + (r.stderr or "")[-1500:] + "\n-> " + out
        except Exception as e:
            return msg + "\nlifter failed to launch: %s" % e

    def _convert(self, cap):
        return cap.get("protos_json") or cap


if __name__ == "__main__":
    os.chdir(here)
    with socketserver.ThreadingTCPServer(("127.0.0.1", port), handler) as httpd:
        print("[server] listening on http://127.0.0.1:%d" % port)
        print("[server] serving: %s" % instrumented_path)
        print("[server] DEOB_ROOT = %s" % (deob_root or "(not set - will only save capture.json)"))
        httpd.serve_forever()
