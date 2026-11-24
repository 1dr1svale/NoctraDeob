'use strict';

const fs = require('fs');
const path = require('path');
const vmmap15 = require('./vmmap');
const vmmap14 = require('./vmmap14');
const harness = require('./harness');
const trace = require('./traceout');
const ui = require('./ui');
const tidy = require('./tidy');
const loops = require('./loops');
const detect = require('./detect');
const path2dProbe = require('./path2dprobe');

const spinChecks = 24;

function spinFor(source) {
  return Math.max(spinChecks, Math.ceil(source.length / 32768));
}

const flavors = {
  luraph_v15: { name: 'luraph_v15', vmmap: vmmap15 },
  luraph_v14: { name: 'luraph_v14', vmmap: vmmap14 },
};

const layerMin = 256;

function writeAudit(job, body) {
  const audit = harness.takeAudit(body);
  if (audit.malformed) ui.note(`skipped ${audit.malformed} malformed audit event(s)`);
  if (audit.dropped) ui.note(`${audit.dropped} audit event(s) over the cap were dropped`);
  if (audit.events.length > 0) job.write(job.path('.events.jsonl'), audit.events.join('\n') + '\n');
  return audit.body;
}

const startupProbeLine = new RegExp('^(?:' + [
  'local connection\\d* = [\\w.]+\\.AncestryChanged:Connect\\(function\\([\\w, ]*\\)',
  'end\\)',
  'connection\\d*:Disconnect\\(\\)',
  'local Folder\\d* = Instance\\.new\\("Folder"(?:, Folder\\d*)?\\)',
  'Folder\\d*:(?:GetChildren|Destroy)\\(\\)',
  'Folder\\d*\\.Name = "\\d+"',
  'Folder\\d*:WaitForChild\\("\\d+"\\)',
  'local (?:HttpService|RunService) = game:GetService\\("(?:HttpService|RunService)"\\)',
].join('|') + ')$');

function ownCodeTraced(body) {
  const plain = tidy.stripAnnotations(tidy.stripMarkers(body));
  const rest = tidy.stripPreamble(plain);
  if (rest === plain) return false;
  return rest.split('\n').some(l => {
    const t = l.trim();
    return t !== '' && !t.startsWith('--') && !t.startsWith('\x00') && !startupProbeLine.test(t);
  });
}

function devirtProblem(lifted, dpath) {
  if (!lifted.trim()) return 'it is empty';
  const count = re => (lifted.match(re) || []).length;
  const lines = lifted.split('\n');
  const nilCalls = count(/\(nil\)\(/g);
  if (nilCalls >= 50 && nilCalls * 100 >= lines.length) return `${nilCalls} calls of nil`;
  const holes = count(/\(nil(?: --\[\[[^\]]*\]\])?\)\[/g) + count(/--\[\[\?NewTable\]\]/g);
  if (holes >= 10 && holes * 10 >= lines.length) return `${holes} unresolved values`;
  const unlifted = count(/error\("devirt: /g);
  const real = lines.filter(l => {
    const t = l.trim();
    return t && !t.startsWith('--') && !/^local [\w, ]+(?: = nil)?$/.test(t) &&
      !/^error\("devirt: /.test(t) && !/^(?:do|end)$/.test(t);
  }).length;
  if (unlifted && real < 5) return 'the script body was not lifted';
  if (/^error\("devirt: /m.test(lifted) && real < 40) return 'the script body was cut off at an unlifted block';
  try {
    vmmap15.loadAst(dpath);
  } catch (e) {
    return 'it is not valid Luau';
  }
  return null;
}

function patchChunk(vmmap, src, tmpdir, chunkTag) {
  const p = path.join(tmpdir, `_chunk_${harness.chunkKey(src)}.luau`);
  fs.writeFileSync(p, src, 'latin1');
  try {
    return vmmap.patchEntries(src, p, chunkTag);
  } catch (e) {
    ui.warn(`could not instrument chunk (${e.message})`);
    return src;
  } finally {
    try { fs.unlinkSync(p); } catch {}
  }
}

async function run(job, flavorName = 'luraph_v15') {
  const flavor = flavors[flavorName];
  if (!flavor) throw new Error(`no Luraph engine named '${flavorName}'`);
  const vmmap = flavor.vmmap;
  const { args } = job;
  const devirtOn = !args.noDevirt;
  let source = job.source;
  job.devirtOk = false;

  let patched;
  try {
    patched = args.noHooks ? source : vmmap.patchEntries(source, job.sourcePath, harness.chunkKey(source));
  } catch (e) {
    ui.warn(`AST parse failed: ${e.message}`);
    throw e;
  }

  let spin = true;
  if (spin) patched = vmmap.patchSpin(patched);

  const cachePath = harness.loadP2dCache(job.input);
  const runner = new harness.Runner(job);
  const runtime = harness.warnRuntime(runner.luau);

  const skip = [];
  const chunks = {};
  const rawChunks = {};
  let body = null;
  let trapped = null;
  let cfg = null;
  const version = detect.luraphVersion(source);
  let cstack = !!(version && (version[0] > 15 || (version[0] === 15 && version[1] >= 2)));
  let cstackFallback = null;

  for (let attempt = 1; attempt <= args.maxRuns; attempt++) {
    cfg = {
      time_budget: args.budget,
      dump_strings: args.strings,
      executor: args.executor,
      skip_protos: skip,
      devirt: devirtOn,
      audit: true,
      audit_max_events: 10000,
      audit_max_value: 512,
      skip_spin: !args.noSkipSpin,
    };
    if (args.inputText) cfg.input_text = args.inputText;
    if (args.preludeFile) cfg.prelude = require('fs').readFileSync(args.preludeFile, 'latin1');
    if (args.noFold) cfg.fold = false;
    if (spin) cfg.spin = spinFor(source);
    if (cstack) cfg.cstack_pcall = true;
    if (args.cfgJson) Object.assign(cfg, args.cfgJson);

    ui.step('Tracing the script in a sandbox', `pass ${attempt}`);
    const res = await runner.run(patched, cfg, chunks);
    body = res.body;

    if (!body) {
      runner.finish();
      throw new Error(res.err || 'Trace failed without output');
    }

    body = harness.takeP2d(body);

    const { chunks: found, body: cleanBody } = harness.takeChunks(body);
    body = writeAudit(job, cleanBody);

    let added = 0;
    for (const [key, src] of found) {
      if (!chunks[key]) {
        rawChunks[key] = src;
        chunks[key] = patchChunk(vmmap, src, job.outdir, key);
        if (spin) chunks[key] = vmmap.patchSpin(chunks[key]);
        added++;
      }
    }
    if (added > 0) {
      ui.note(`the script loadstring'd ${added} more VM chunk(s); instrumenting and re-running`);
      continue;
    }

    const trig = new RegExp(harness.mark('TRIGGER ') + '(\\d+)').exec(body);
    if (cstackFallback !== null) {
      const before = cstackFallback;
      cstackFallback = null;
      if (trace.stmtCount(body) <= trace.stmtCount(before[0])) {
        ui.note('the C-stack limit did not help here: turning it off again');
        cstack = false;
        body = before[0];
        trapped = before;
        const pid0 = parseInt(before[2], 10);
        ui.warn(`anti-tamper trap through function #${pid0}; disabling it and re-running`);
        skip.push(pid0);
        continue;
      }
      ui.ok('cleared the anti-tamper trap (C-stack limit on pcall)');
    }
    if (trig && !cstack && !skip.length && !(args.cfgJson && 'cstack_pcall' in args.cfgJson)) {
      ui.warn('anti-tamper trap hit — re-running with the Luraph v15.2 C-stack depth probe');
      cstackFallback = [body, harness.getLastRaw(), trig[1]];
      cstack = true;
      continue;
    }
    if (trapped !== null && trace.stmtCount(body) < trace.stmtCount(trapped[0])) {
      ui.note(`disabling function #${skip[skip.length - 1]} made the script stop earlier: keeping pass ${attempt - 1}`);
      body = trapped[0];
      skip.pop();
      break;
    }
    if (!trig) break;

    trapped = [body, harness.getLastRaw()];
    const pid = parseInt(trig[1], 10);
    if (skip.includes(pid)) {
      ui.warn(`anti-tamper trigger ${pid} fired again; giving up on re-runs`);
      break;
    }
    ui.warn(`anti-tamper trap through function #${pid}; disabling it and re-running`);
    skip.push(pid);
  }

  const runText = harness.traceText(body);
  body = harness.p2dMiss(body, cachePath);
  body = body.replace(new RegExp(harness.mark('TRIGGER ') + '\\d+\\n?', 'g'), '');

  const [protosJson, b1] = trace.takeLine(body, 'PROTOS');
  body = b1;
  const rootSeen = protosJson ? /^\{"root_callee":(null|-?\d+)/.exec(protosJson) : null;
  const payloadReached = !rootSeen || rootSeen[1] !== 'null' || ownCodeTraced(body);
  if (!payloadReached && !fs.existsSync(cachePath)) {
    const probe = path2dProbe.build(body, path.basename(cachePath));
    if (probe) {
      const probePath = cachePath.replace(/\.path2d$/, '.path2d_probe.lua');
      fs.writeFileSync(probePath, probe.text, 'utf8');
      job.probe = { path: probePath, cache: cachePath, queries: probe.queries };
    }
  }
  const [force, b2] = trace.takeLine(body, 'FORCE');
  body = b2;
  if (force && devirtOn) ui.note(`constants decoded on request: ${force}`);

  const [unscrambled, b3] = trace.takeLine(body, 'UNSCRAMBLED');
  body = b3;
  if (unscrambled && devirtOn)
    ui.note(`${unscrambled} function(s) scrambled by LPH_CRASH(): dumped as created`);

  const [b4, strings] = trace.takeStrings(body);
  body = b4;

  const notes = skip.length ? [`anti-tamper trap functions disabled: ${skip.map(p => '#' + p).join(', ')}`] : [];
  const text = trace.header(job.input, notes) + body;

  function writeTrace() {
    job.write(job.tracePath, tidy.tidy(text, { preamble: !args.keepPreamble }));
  }

  if (!devirtOn) {
    writeTrace();
  }

  if (strings) job.write(job.path('.strings.txt'), strings);

  const dpath = job.path('.devirt.luau');
  if (protosJson) {
    const ppath = job.path('.protos.json');
    if (protosJson.startsWith('error:')) {
      ui.warn(`proto capture failed: ${protosJson}`);
    } else {
      job.write(ppath, protosJson);
      if (devirtOn) {
        const chunkPaths = Object.entries(rawChunks).map(([k, src]) =>
          job.write(job.path(`.chunk_${k}.luau`), src, 'latin1')
        );

        const cfgData = {
          plugin: flavor.name,
          input: job.input,
          source: job.source,
          source_path: job.sourcePath,
          trace_path: job.tracePath,
          debug: job.debug,
          obfuscator: job.obfuscator,
          luau_exe: runner.luau,
          patched: patched,
          cfg: cfg,
          chunks: chunks,
          run_text: runText,
          ppath: ppath,
          dpath: dpath,
          chunk_paths: chunkPaths,
          args: {
            budget: args.budget,
            timeout: args.timeout,
            devirt_rounds: args.devirtRounds || 200,
            studio: false,
            no_fold: args.noFold || false,
            strings: args.strings || false,
            executor: args.executor || 'Wave',
          },
        };
        const cfgPath = job.path('.cfg.json');
        fs.writeFileSync(cfgPath, JSON.stringify(cfgData), 'utf8');

        const { execFileSync } = require('child_process');
        const { getPythonBin } = require('./pyenv');
        const pythonBin = getPythonBin();
        const bridgePy = path.join(__dirname, 'devirt_bridge.py');
        const coreDir = path.join(__dirname, '..', 'core');
        try {
          execFileSync(pythonBin, [bridgePy, 'pipeline', cfgPath], {
            env: Object.assign({}, process.env, { PYTHONPATH: coreDir }),
            stdio: 'inherit',
          });
        } finally {
          try { fs.unlinkSync(cfgPath); } catch {}
        }
      }
    }
  }

  runner.finish();
  trace.statusLine(body);
  if (job.probe && runtime.patched) {
    ui.warn(`the run stopped inside Luraph's loader: its key uses ${job.probe.queries} Path2D values, supplied here by the offline model`);
    ui.note(`to use the real ones: run ${job.probe.path} once in Roblox, save its output as ${job.probe.cache}, and run this again`);
  }

  if (devirtOn && fs.existsSync(dpath)) {
    const lifted = fs.readFileSync(dpath, 'utf8');
    const why = devirtProblem(lifted, dpath);
    if (!why) {
      job.devirtOk = true;
      if (!payloadReached) {
        const status = ((body || '').split('\n')[0] || '').replace(/^--\s*run status:\s*/, '').slice(0, 160);
        ui.warn("the run stopped before the script's own code started: the result is Luraph's startup and anti-tamper code, not the script");
        job.notes = [
          `NOTE: the sandbox run stopped before the protected script's own code started (${status}).`,
          "What follows is Luraph's startup and anti-tamper code, not the script itself.",
        ];
        if (!runtime.patched) {
          ui.note('likely cause: the Luau runtime is not the patched build (run `python build_luau.py`)');
          job.notes.push('The Luau runtime used for this run is not the patched build (see build_luau.py): that is the likely cause.');
        } else if (job.probe) {
          job.notes.push(`Its decryption key includes ${job.probe.queries} Path2D answers that came from the offline model. Run ${path.basename(job.probe.path)} once in Roblox and save its output as ${path.basename(job.probe.cache)} next to the script to use the real ones.`);
        }
      }
      return dpath;
    }
    ui.warn(`the devirtualized output is not usable (${why}); writing the behaviour trace instead`);
    if (lifted.trim()) job.partial = dpath;
    else if (!job.debug) { try { fs.unlinkSync(dpath); } catch {} }
    writeTrace();
    return job.tracePath;
  }

  if (devirtOn) {
    ui.warn('devirtualization produced no output; writing the behaviour trace');
    if (!fs.existsSync(job.tracePath)) writeTrace();
  }
  return job.tracePath;
}

async function runGeneric(job) {
  const { args } = job;
  const cachePath = harness.loadP2dCache(job.input);
  const runner = new harness.Runner(job);
  harness.warnRuntime(runner.luau);
  const cfg = {
    time_budget: args.budget,
    executor: args.executor,
    dump_strings: args.strings,
    chunk_min: layerMin,
  };
  if (args.inputText) cfg.input_text = args.inputText;
  if (args.preludeFile) cfg.prelude = fs.readFileSync(args.preludeFile, 'latin1');
  if (args.noFold) cfg.fold = false;
  if (args.cfgJson) Object.assign(cfg, args.cfgJson);

  ui.step('Tracing the script in a sandbox');
  let res = await runner.run(job.source, cfg);
  if (!res.body && /timed out/.test(res.err || '')) {
    try {
      const patched = loops.patchAllLoops(job.source, job.sourcePath);
      if (patched.loops) {
        ui.warn(`the script never returned (${args.timeout}s): watching its ${patched.loops} loops and re-running`);
        res = await runner.run(patched.source, Object.assign({}, cfg, { spin: spinChecks }));
      }
    } catch (e) {
      ui.warn(`could not instrument the loops (${e.message})`);
    }
  }
  if (!res.body) {
    runner.finish();
    throw new Error((res.err || 'Trace failed without output').trim().split('\n').pop());
  }
  runner.finish();
  let body = harness.takeP2d(res.body);
  body = harness.p2dMiss(body, cachePath);
  const { chunks: layers, body: cleanBody } = harness.takeChunks(body);
  job.layers = layers.map(([key, src]) => ({ key, source: src }));
  body = writeAudit(job, cleanBody);
  const [b2, strings] = trace.takeStrings(body);
  body = b2;

  const text = trace.header(job.input) + body;
  job.write(job.tracePath, tidy.tidy(text, { preamble: false }));
  if (strings) job.write(job.path('.strings.txt'), strings);
  trace.statusLine(body);
  return job.tracePath;
}

module.exports = { run, runGeneric, flavors };
