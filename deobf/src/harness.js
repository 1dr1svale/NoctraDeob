'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync, spawn } = require('child_process');
const https = require('https');
const http = require('http');
const ui = require('./ui');

const here = __dirname;
const binDir = path.join(here, '..', 'bin');
const luauUrl = 'https://github.com/luau-lang/luau/releases/latest/download/luau-windows.zip';

const proto = JSON.parse(fs.readFileSync(path.join(here, '..', 'protocol.json'), 'utf8'));
const heartbeatSeconds = proto.heartbeat_seconds;
const stallSeconds = proto.stall_seconds;

function protoLua() {
  const ch = proto.chunk_hash;
  return `local protocol = { hash_mult = ${ch.multiplier}, hash_mod = ${ch.modulus}, hash_stride = ${ch.stride}, chunk_min = ${ch.min_len} }`;
}
const protoLineRe = /local protocol = \{[^}]*\}/;

let markNonce = '';
function mark(s) { return '\x00' + markNonce + s; }

function _ensureExec(p) {
  if (process.platform !== 'win32' && fs.existsSync(p)) {
    try { fs.accessSync(p, fs.constants.X_OK); }
    catch (_) { try { fs.chmodSync(p, 0o755); } catch (_2) {} }
  }
  return p;
}

let _luauExe = null;
function findLuau() {
  if (_luauExe) return _ensureExec(_luauExe);
  const exe = process.platform === 'win32' ? 'luau.exe' : 'luau';
  const local = path.join(binDir, exe);
  if (fs.existsSync(local)) { _luauExe = _ensureExec(local); return _luauExe; }
  const pathEnv = process.env.PATH || '';
  for (const d of pathEnv.split(path.delimiter)) {
    const p = path.join(d, exe);
    if (fs.existsSync(p)) { _luauExe = _ensureExec(p); return _luauExe; }
  }
  if (process.platform !== 'win32') {
    throw new Error('luau not found: build it with build_luau.py or put it in ' + binDir);
  }
  process.stderr.write('[*] downloading Luau runtime...\n');
  process.stderr.write('[!] stock Luau lacks Vector3 members: build the patched runtime with build_luau.py\n');
  fs.mkdirSync(binDir, { recursive: true });
  const zipPath = path.join(binDir, 'luau.zip');
  _downloadSync(luauUrl, zipPath);
  _extractZip(zipPath, binDir, ['luau.exe', 'luau-ast.exe']);
  fs.unlinkSync(zipPath);
  _luauExe = local;
  return local;
}

const runtimeProbe = [
  'local okv, frozen = pcall(function() return table.isfrozen(getmetatable(vector.create(0, 0, 0))) end)',
  'local function deep(n) if n == 0 then return 0 end return 1 + deep(n - 1) end',
  'local okd = pcall(deep, 20050)',
  'print("probe " .. tostring(okv and not frozen) .. " " .. tostring(okd))',
  '',
].join('\n');
const runtimeCache = new Map();

function runtimeStatus(luau) {
  if (runtimeCache.has(luau)) return runtimeCache.get(luau);
  const dir = fs.mkdtempSync(path.join(require('os').tmpdir(), 'deobf_probe_'));
  const file = path.join(dir, 'probe.harness.luau');
  let out = '';
  try {
    fs.writeFileSync(file, runtimeProbe, 'latin1');
    out = execFileSync(luau, [file], { encoding: 'utf8', timeout: 30000, stdio: ['ignore', 'pipe', 'ignore'] });
  } catch (e) {
    out = String((e && e.stdout) || '');
  } finally {
    try { fs.rmSync(dir, { recursive: true, force: true }); } catch {}
  }
  const m = /probe (true|false) (true|false)/.exec(out);
  const status = { known: !!m, vector: !!m && m[1] === 'true', depth: !!m && m[2] === 'true', problems: [] };
  if (!m) {
    status.problems.push('it did not answer the runtime check (too old, or not a Luau build)');
  } else {
    if (!status.vector) status.problems.push('its vector metatable is frozen, so Vector3 members (v.Magnitude, v:Dot(w), ...) fail');
    if (!status.depth) status.problems.push('it lacks the stack-depth patch, so stack probes see the sandbox');
  }
  status.patched = status.problems.length === 0;
  runtimeCache.set(luau, status);
  return status;
}

let _runtimeWarned = false;
function warnRuntime(luau) {
  const status = runtimeStatus(luau);
  if (status.patched || _runtimeWarned) return status;
  _runtimeWarned = true;
  process.stderr.write(`[!] ${luau} is not the patched Luau runtime this tool needs:\n`);
  for (const problem of status.problems) process.stderr.write(`[!]   - ${problem}\n`);
  process.stderr.write('[!]   Luraph v15 scripts stop in their startup checks on such a build, before the script itself runs.\n');
  process.stderr.write('[!]   Build the patched runtime with `python build_luau.py` (needs git, cmake and a C++ compiler);\n');
  process.stderr.write('[!]   it writes the patched luau and luau-ast into bin/.\n');
  return status;
}

function luauAst() {
  const exe = process.platform === 'win32' ? 'luau-ast.exe' : 'luau-ast';
  const local = path.join(binDir, exe);
  if (fs.existsSync(local)) return _ensureExec(local);
  const pathEnv = process.env.PATH || '';
  for (const d of pathEnv.split(path.delimiter)) {
    const p = path.join(d, exe);
    if (fs.existsSync(p)) return _ensureExec(p);
  }
  throw new Error('luau-ast not found: build it with `python build_luau.py` (needs git, cmake, a C++ compiler) or put it in ' + binDir);
}

function _downloadSync(url, dest) {
  const out = fs.openSync(dest, 'w');
  const cmd = process.platform === 'win32'
    ? ['powershell', '-Command', `Invoke-WebRequest -Uri '${url}' -OutFile '${dest}'`]
    : ['curl', '-sL', url, '-o', dest];
  execFileSync(cmd[0], cmd.slice(1), { stdio: 'inherit' });
  fs.closeSync(out);
}

function _extractZip(zipPath, destDir, names) {
  if (process.platform === 'win32') {
    const cmd = `Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead('${zipPath}'); foreach($e in $z.Entries){if(${names.map(n => `'${n}'`).join(',')}.Contains($e.Name)){[System.IO.Compression.ZipFileExtensions]::ExtractToFile($e,'${destDir}\\\\'+$e.Name,$true)}};$z.Dispose()`;
    execFileSync('powershell', ['-Command', cmd]);
  } else {
    execFileSync('unzip', ['-o', zipPath, ...names, '-d', destDir]);
  }
}

function longString(s) {
  let level = 0;
  while (s.includes(']' + '='.repeat(level) + ']')) level++;
  const eq = '='.repeat(level);
  return '[' + eq + '[\n' + s + ']' + eq + ']';
}

function luaValue(v) {
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  if (Array.isArray(v)) return '{' + v.map(luaValue).join(', ') + '}';
  if (typeof v === 'string')
    return '"' + v.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '\\r') + '"';
  if (v === null || v === undefined) return 'nil';
  if (typeof v === 'object')
    return '{' + Object.entries(v).map(([k, val]) => `[${luaValue(k)}] = ${luaValue(val)}`).join(', ') + '}';
  return String(v);
}

function chunkKey(src) {
  const bytes = Buffer.from(src, 'latin1');
  let h = 0;
  for (const b of bytes) h = ((h * proto.chunk_hash.multiplier + b) % proto.chunk_hash.modulus);
  return `${bytes.length}_${h}`;
}

const p2dCache = new Map();

function p2dCachePath(inputPath) {
  return inputPath.replace(/\.(luau?|txt)?$/, '.path2d');
}

function loadP2dCache(inputPath) {
  const cp = p2dCachePath(inputPath);
  if (fs.existsSync(cp)) {
    const lines = fs.readFileSync(cp, 'utf8').split('\n');
    for (const line of lines) {
      const m = /(Get[A-Za-z]+(?:\|[^\s|]+)*)\s+([a-z]:\S*)/.exec(line);
      if (m) p2dCache.set(m[1], m[2]);
    }
    process.stderr.write(`[*] replaying ${p2dCache.size} recorded Path2D results from ${cp}\n`);
  }
  return cp;
}

function takeP2d(body) {
  const p2d = [];
  body = body.replace(new RegExp(mark('P2D ') + '([^\\t\\n]+)\\t([^\\n]*)\\n', 'g'), (_, k, v) => {
    p2d.push([k, v]);
    return '';
  });
  const nmodel = p2d.filter(([, v]) => v.endsWith('\tmodel')).length;
  if (nmodel) ui.note(`${nmodel} Path2D curve values supplied by the offline model`);
  return body;
}

function p2dMiss(body, cachePath) {
  if (!body.includes(mark('P2DMISS'))) return body;
  process.stderr.write(`[!] this script derives keys from a Path2D call the offline model does not cover\n    (run it once with --studio if needed; writes ${cachePath})\n`);
  return body.replace(new RegExp(mark('P2DMISS') + '\\n', 'g'), '');
}

const shieldStdlib = `{
        string = string, math = math, table = table, os = os, debug = debug,
        coroutine = coroutine, bit32 = bit32, buffer = buffer, utf8 = utf8, vector = vector,
        type = type, typeof = typeof, pairs = pairs, ipairs = ipairs, next = next,
        select = select, rawget = rawget, rawset = rawset, rawequal = rawequal,
        rawlen = rawlen, setmetatable = setmetatable, getmetatable = getmetatable,
        tostring = tostring, tonumber = tonumber, error = error, assert = assert, print = print,
        pcall = pcall, xpcall = xpcall, unpack = table.unpack, newproxy = newproxy,
}`;

function buildHarness(source, cfg, chunks = {}) {
  const runtimeFile = path.join(here, '..', 'runtime', 'envlog.luau');
  let runtime = fs.readFileSync(runtimeFile, 'utf8').replace('--!nocheck', '');

  if (!protoLineRe.test(runtime)) {
    throw new Error("runtime/envlog.luau lost its `local protocol = {...}` line; restore it (see protocol.json)");
  }
  runtime = runtime.replace(protoLineRe, protoLua());

  const unicodeFile = path.join(here, '..', 'runtime', 'unicode_data.luau');
  const robloxFile = path.join(here, '..', 'runtime', 'roblox_api.luau');
  const dtypesFile = path.join(here, '..', 'runtime', 'datatypes.luau');

  const udata = fs.existsSync(unicodeFile) ? fs.readFileSync(unicodeFile, 'ascii').replace('--!nocheck', '') : '';
  const rdata = fs.existsSync(robloxFile) ? fs.readFileSync(robloxFile, 'ascii').replace('--!nocheck', '') : '';
  const dtypes = fs.existsSync(dtypesFile) ? fs.readFileSync(dtypesFile, 'utf8').replace('--!nocheck', '') : '';

  const cfgLua = '{' + Object.entries(cfg).map(([k, v]) => `${k} = ${luaValue(v)}`).join(', ') + '}';
  const p2dLua = '{' + [...p2dCache.entries()].map(([k, v]) => `[${luaValue(k)}] = ${luaValue(v)},\n`).join('') + '}';
  const chunksLua = '{' + Object.entries(chunks).map(([k, v]) => `[${luaValue(k)}] = ${longString(v)},\n`).join('') + '}';

  markNonce = crypto.randomBytes(proto.nonce_hex_bytes).toString('hex');

  return (
    'local __stdlib = ' + shieldStdlib + '\n' +
    'local __shield = setmetatable({}, { __index = __stdlib })\n' +
    'local __unicode = (function()\n' + udata + '\nend)()\n' +
    'local __roblox = (function()\n' + rdata + '\nend)()\n' +
    '__roblox.datatypes = (function()\n' + dtypes + '\nend)()\n' +
    'local __raw = { getfenv = getfenv, setfenv = setfenv, loadstring = loadstring }\n' +
    'local __run = function(__mark, __source, __config, __p2d, __chunks, __unicode, __roblox, __raw)\n' +
    runtime + '\n' +
    'end\n' +
    'setfenv(__run, __shield)\n' +
    'return __run(' + luaValue(markNonce) + ', ' + longString(source) + ', ' + cfgLua + ',\n' +
    '  ' + p2dLua + ', ' + chunksLua + ', __unicode, __roblox, __raw)\n'
  );
}

let lastRaw = '';

async function runOnce(luau, source, cfg, hpath, timeoutSec, keepHarness, chunks = {}) {
  cfg = Object.assign({ heartbeat: heartbeatSeconds }, cfg);
  const harness = buildHarness(source, cfg, chunks);
  fs.writeFileSync(hpath, harness, 'latin1');

  const { body, err } = await _communicate([luau, hpath], timeoutSec * 1000, stallSeconds * 1000);

  if (!keepHarness && fs.existsSync(hpath)) {
    try { fs.unlinkSync(hpath); } catch {}
  }

  let stdout = body.replace(new RegExp(mark('HB') + '\\r?\\n {16384}\\r?\\n', 'g'), '').replace(/\r\n/g, '\n');
  lastRaw = stdout + err;
  const m = new RegExp(mark('ENVLOG-BEGIN') + '\\n([\\s\\S]*?)' + mark('ENVLOG-END')).exec(stdout);
  if (!m) {
    return { body: null, err: stdout.slice(-3000) + '\n' + err.slice(-3000) };
  }
  let result = m[1];
  for (const hp of [hpath, hpath.replace(/\\/g, '/')]) {
    if (result.includes(hp + ':')) {
      result = result.replace(new RegExp(hp.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ':\\d+: ', 'g'), '');
    }
  }
  return { body: result, err: null };
}

function _communicate(cmd, timeoutMs, stallMs) {
  return new Promise((resolve) => {
    const proc = spawn(cmd[0], cmd.slice(1), { stdio: ['ignore', 'pipe', 'pipe'] });
    const outBufs = [], errBufs = [];
    let lastOutput = Date.now();
    let done = false;

    function finish() {
      if (done) return;
      done = true;
      clearInterval(watchdog);
      resolve({
        body: Buffer.concat(outBufs).toString('utf8', 0, undefined),
        err: Buffer.concat(errBufs).toString('utf8', 0, undefined),
      });
    }

    proc.stdout.on('data', b => { outBufs.push(b); lastOutput = Date.now(); });
    proc.stderr.on('data', b => { errBufs.push(b); lastOutput = Date.now(); });
    proc.on('close', finish);
    proc.on('error', err => { errBufs.push(Buffer.from(err.message)); finish(); });

    const start = Date.now();
    const watchdog = setInterval(() => {
      const now = Date.now();
      if (now - start > timeoutMs || (stallMs && now - lastOutput > stallMs)) {
        proc.kill('SIGKILL');
        errBufs.push(Buffer.from(`\ntimed out after ${Math.round((now - start) / 1000)}s`));
        finish();
      }
    }, 200);
  });
}

function takeChunks(body) {
  const found = [];
  body = body.replace(new RegExp(mark('CHUNK ') + '(\\S+)\\n([0-9a-f]*)\\n', 'g'), (_, k, hx) => {
    found.push([k, Buffer.from(hx, 'hex').toString('latin1')]);
    return '';
  });
  return { chunks: found, body };
}

function takeAudit(body) {
  const auditPrefix = mark('AUDIT ');
  const droppedPrefix = mark('AUDIT-DROPPED ');
  const events = [];
  const keep = [];
  let dropped = 0;
  let malformed = 0;
  for (const line of body.split('\n')) {
    if (line.startsWith(droppedPrefix)) {
      dropped = parseInt(line.slice(droppedPrefix.length), 10) || 0;
    } else if (line.startsWith(auditPrefix)) {
      try {
        events.push(JSON.stringify(JSON.parse(line.slice(auditPrefix.length))));
      } catch {
        malformed++;
      }
    } else {
      keep.push(line);
    }
  }
  return { events, dropped, malformed, body: keep.join('\n') };
}

class HarnessServer {
  constructor(luau, source, cfg, chunks = {}) {
    const os = require('os');
    this.dir = fs.mkdtempSync(path.join(os.tmpdir(), 'deobf_serve_'));
    const harnessContent = buildHarness(source, Object.assign({}, cfg, { serve: true }), chunks);
    fs.writeFileSync(path.join(this.dir, 'harness.luau'), harnessContent, 'latin1');
    this.proc = spawn(luau, [], {
      cwd: this.dir,
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    this.buf = Buffer.alloc(0);
    this.nreq = 0;
    this.deadline = null;
    this.timedOut = false;
    this._startWatchdog();
    this._send('__s = require("./harness")\n__s("", "", "start")\n');
  }

  _startWatchdog() {
    this._wd = setInterval(() => {
      if (this.deadline !== null && Date.now() > this.deadline) {
        this.timedOut = true;
        this.proc.kill('SIGKILL');
      }
    }, 250);
  }

  _send(data) {
    try { this.proc.stdin.write(data); } catch {}
  }

  async reply(timeoutMs) {
    this.deadline = Date.now() + timeoutMs;
    try {
      return await this._readUntilEnd(timeoutMs);
    } finally {
      this.deadline = null;
    }
  }

  _readUntilEnd(timeoutMs) {
    const endMark = Buffer.from(mark('ENVLOG-END'));
    return new Promise((resolve) => {
      const accum = [];
      const onData = (chunk) => {
        accum.push(chunk);
        const all = Buffer.concat(accum);
        const idx = all.indexOf(endMark);
        if (idx !== -1) {
          this.proc.stdout.off('data', onData);
          this.proc.stdout.off('end', onEnd);
          clearTimeout(timer);
          const out = all.slice(0, idx + endMark.length).toString('utf8');
          lastRaw = out;
          const m = new RegExp(mark('ENVLOG-BEGIN') + '\\n([\\s\\S]*?)' + mark('ENVLOG-END')).exec(out);
          if (!m) return resolve({ body: null, err: out.slice(-3000) });
          return resolve({ body: m[1], err: null });
        }
      };
      const onEnd = () => {
        clearTimeout(timer);
        const out = Buffer.concat(accum).toString('utf8');
        resolve({ body: null, err: (this.timedOut ? 'timed out' : 'harness exited') + ': ' + out.slice(-3000) });
      };
      const timer = setTimeout(() => {
        this.proc.stdout.off('data', onData);
        this.proc.stdout.off('end', onEnd);
        this.proc.kill('SIGKILL');
        const out = Buffer.concat(accum).toString('utf8');
        resolve({ body: null, err: 'timed out: ' + out.slice(-3000) });
      }, timeoutMs);
      this.proc.stdout.on('data', onData);
      this.proc.stdout.once('end', onEnd);
    });
  }

  async request(cfg, timeoutMs, mode = 'dump') {
    const req = cfg.force_req || '';
    const buf = cfg.force_buf || '';
    if (req.length + buf.length < 2000 && /^[\w,@.;=+/:*\-]*$/.test(req + buf)) {
      this._send(`__s("${req}", "${buf}", "${mode}")\n`);
    } else {
      this.nreq++;
      const name = `req_${this.nreq}`;
      const content = `return {${longString(req)}, ${longString(buf)}, ${longString(mode)}}\n`;
      fs.writeFileSync(path.join(this.dir, name + '.luau'), content, 'utf8');
      this._send(`__s(table.unpack(require("./${name}")))\n`);
    }
    return this.reply(timeoutMs);
  }

  async fetch(paths, bufs, timeoutMs) {
    const { body, err } = await this.request({ force_req: paths.join(';'), force_buf: bufs }, timeoutMs, 'fetch');
    if (!body) throw new Error('harness fetch failed: ' + err.slice(-300));
    const m = new RegExp(mark('FETCH ') + '([^\\n]*)\\n').exec(body);
    if (!m || m[1].startsWith('error:')) throw new Error('harness fetch failed: ' + (m ? m[1].slice(0, 300) : body.slice(-300)));
    return m[1];
  }

  close() {
    clearInterval(this._wd);
    if (this.proc.exitCode === null) { try { this.proc.kill('SIGKILL'); } catch {} }
    try { require('fs').rmSync(this.dir, { recursive: true, force: true }); } catch {}
  }
}

function traceText(body) {
  body = body.replace(/\x00[0-9a-f]{8,32}CHUNK \S+\n[0-9a-f]*\n/g, '');
  body = body.replace(/\x00[0-9a-f]{8,32}(PROTOS|FORCE|P2D|TRIGGER|AUDIT|UNSCRAMBLED)[^\n]*\n?/g, '');
  body = body.replace(/(?<=[ \t])(?=\S)(?:[A-Za-z]:)?[^:\n]*?\.luau:/g, 'harness:');
  body = body.replace(/harness:\d+: /g, '');
  body = body.replace(/"(?:[^"\\\n]|\\.)*"/g, '""');
  return body.replace(/\d+(?:\.\d+)?(?:e[-+]?\d+)?/g, '0');
}

function sameTrace(a, b) {
  if (a === b) return true;
  const wa = new Set(a.match(/\w+/g) || []);
  const wb = new Set(b.match(/\w+/g) || []);
  const only = new Set([...wa, ...wb].filter(w => wa.has(w) !== wb.has(w)));
  const mask = t => t.replace(/\w+/g, m => only.has(m) ? '_' : m);
  return mask(a) === mask(b);
}

class Runner {
  constructor(job, luau) {
    this.job = job;
    this.luau = luau || findLuau();
    this.hpath = job.tracePath + '.harness.luau';
  }

  async run(source, cfg, chunks = {}) {
    return runOnce(this.luau, source, cfg, this.hpath, this.job.args.timeout, this.job.args.keepHarness, chunks);
  }

  finish() {}
}

module.exports = {
  findLuau, luauAst, runtimeStatus, warnRuntime, chunkKey, longString, luaValue,
  buildHarness, runOnce, takeChunks, takeAudit, takeP2d, p2dMiss,
  loadP2dCache, p2dCachePath, traceText, sameTrace,
  HarnessServer, Runner,
  getLastRaw: () => lastRaw,
  getMark: () => markNonce,
  mark,
  heartbeatSeconds, stallSeconds,
};
