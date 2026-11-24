#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const detectModule = require('./src/detect');
const driver = require('./src/driver');
const layersModule = require('./src/layers');
const ui = require('./src/ui');

const supportedExtensions = ['.lua', '.luau'];

function parseArgs(argv) {
  const args = {
    inputs: [],
    output: null,
    detect: false,
    plugin: null,
    noDevirt: false,
    noHooks: false,
    noFold: false,
    debug: false,
    strings: false,
    keepHarness: false,
    keepPreamble: false,
    timeout: 90,
    budget: 30,
    maxRuns: 12,
    devirtRounds: 200,
    executor: 'Wave',
    inputText: null,
  };

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--detect') { args.detect = true; }
    else if (a === '--plugin') { args.plugin = argv[++i]; }
    else if (a === '--no-devirt') { args.noDevirt = true; }
    else if (a === '--no-hooks') { args.noHooks = true; }
    else if (a === '--no-fold') { args.noFold = true; }
    else if (a === '--debug') { args.debug = true; }
    else if (a === '--strings') { args.strings = true; }
    else if (a === '--keep-harness') { args.keepHarness = true; }
    else if (a === '--keep-preamble') { args.keepPreamble = true; }
    else if (a === '-o' || a === '--output') { args.output = argv[++i]; }
    else if (a === '--timeout') { args.timeout = parseInt(argv[++i], 10); }
    else if (a === '--prelude-file') { args.preludeFile = argv[++i]; }
    else if (a === '--budget') { args.budget = parseInt(argv[++i], 10); }
    else if (a === '--max-runs') { args.maxRuns = parseInt(argv[++i], 10); }
    else if (a === '--devirt-rounds') { args.devirtRounds = parseInt(argv[++i], 10); }
    else if (a === '--executor') { args.executor = argv[++i]; }
    else if (a === '--input-text') { args.inputText = argv[++i]; }
    else if (a === '--cfg-json') {
      let spec = argv[++i];
      if (spec.startsWith('@')) spec = fs.readFileSync(spec.slice(1), 'utf8');
      args.cfgJson = JSON.parse(spec);
    }
    else if (!a.startsWith('-')) { args.inputs.push(a); }
  }

  return args;
}

class Job {
  constructor(inputPath, source, args, tracePath, debug, obfuscator = '') {
    this.input = inputPath;
    this.source = source;
    this.sourcePath = inputPath;
    this.args = args;
    this.tracePath = tracePath;
    this.debug = debug;
    this.obfuscator = obfuscator;
  }

  creditHeader() {
    return '';
  }

  get base() {
    return this.tracePath.replace(/\.(deobf\.luau|luau)$/, '');
  }

  path(suffix) {
    return this.base + suffix;
  }

  wrote(p) {
    if (this.debug) process.stderr.write(`[+] wrote ${p}\n`);
  }

  write(p, text, encoding = 'utf8') {
    fs.writeFileSync(p, text, { encoding });
    this.wrote(p);
    return p;
  }

  get outdir() {
    return path.dirname(path.resolve(this.tracePath));
  }
}

function collectInputFiles(rawPaths) {
  const files = [];
  const seen = new Set();

  for (const raw of rawPaths) {
    const abs = path.resolve(raw);
    if (!fs.existsSync(abs)) {
      process.stderr.write(`[!] path not found, skipping: ${raw}\n`);
      continue;
    }
    const stat = fs.statSync(abs);
    if (stat.isDirectory()) {
      const entries = fs.readdirSync(abs, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isFile() && supportedExtensions.includes(path.extname(entry.name).toLowerCase())) {
          const filePath = path.join(abs, entry.name);
          if (!seen.has(filePath)) {
            seen.add(filePath);
            files.push(filePath);
          }
        }
      }
    } else if (stat.isFile()) {
      const ext = path.extname(abs).toLowerCase();
      if (!supportedExtensions.includes(ext)) {
        process.stderr.write(`[!] unsupported extension for ${raw} (expected ${supportedExtensions.join(', ')})\n`);
        continue;
      }
      if (!seen.has(abs)) {
        seen.add(abs);
        files.push(abs);
      }
    }
  }

  return files;
}

const maxLayers = 4;

function stemOf(p) {
  return path.basename(p).replace(/(\.luau?|\.txt)$/i, '');
}

async function unwrap(inputPath, source, args, ctx) {
  let plugin, confidence;
  if (args.plugin && ctx.depth === 0) {
    plugin = detectModule.byName(args.plugin);
    confidence = 1.0;
  } else {
    ({ plugin, confidence } = detectModule.detect(source));
  }
  const label = detectModule.describe(plugin, source);
  const how = args.plugin && ctx.depth === 0 ? 'forced' : 'detected';
  const pct = `${how}, ${Math.round(confidence * 100)}% confidence`;
  if (ctx.depth) {
    ui.step(`Layer ${ctx.depth}: ${label}`, pct);
  } else {
    ui.banner('Obfuscation detected', label, pct);
    try {
      const bytes = fs.statSync(inputPath).size;
      const kb = bytes < 1024 * 1024 ? `${(bytes / 1024).toFixed(0)} KB` : `${(bytes / 1048576).toFixed(1)} MB`;
      ui.field('file', `${path.basename(inputPath)}   ${ui.paint.gray(kb)}`);
    } catch (e) {}
  }

  const tracePath = path.join(ctx.dir, stemOf(inputPath) + '.deobf.luau');
  let jobSource = source;
  let sourcePath = inputPath;
  const fixed = detectModule.restoreHeaderNewline(source);
  if (fixed !== source) {
    process.stderr.write('[*] header comment ran into the code: split it\n');
    jobSource = fixed;
    sourcePath = path.join(ctx.dir, path.basename(inputPath) + '.src.lua');
    fs.writeFileSync(sourcePath, fixed, 'latin1');
  }

  const job = new Job(inputPath, jobSource, args, tracePath, args.debug, label);
  job.sourcePath = sourcePath;

  if (plugin.name === 'luarmor_client') {
    throw new Error('Luarmor whitelist client detected — devirtualization/tracing not applicable.');
  }
  const forced = !!(args.plugin && ctx.depth === 0);
  const engine = forced ? (driver.flavors[plugin.name] ? plugin.name : null) : (plugin.engine || null);
  if (!engine && plugin.note) process.stderr.write(`[*] ${pad}${plugin.note}\n`);
  if (engine) {
    try {
      const result = await driver.run(job, engine);
      if (job.partial) ctx.extras.push(job.partial);
      return { path: result, raw: false, devirt: !!job.devirtOk, notes: job.notes || [] };
    } catch (e) {
      process.stderr.write(`[!] ${pad}${label} lifter failed (${String(e.message || e).trim().split('\n').pop()}); falling back to the behaviour trace\n`);
    }
  }

  const trace = await driver.runGeneric(job);
  const layers = (job.layers || []).slice(0, 16);
  if (!layers.length || ctx.depth >= maxLayers || /^luraph_/.test(plugin.name)) {
    return { path: trace, raw: false, devirt: false, notes: [] };
  }

  const stem = stemOf(inputPath);
  const saved = layers.map((layer, i) => {
    const p = path.join(ctx.dir, `${stem}.layer${ctx.depth + 1}${layers.length > 1 ? '_' + (i + 1) : ''}.lua`);
    fs.writeFileSync(p, layer.source, 'latin1');
    ctx.extras.push(p);
    return p;
  });
  process.stderr.write(`[*] ${pad}the script loadstring'd ${layers.length} further source(s) (${layers.map(l => l.source.length + ' bytes').join(', ')})\n`);

  for (let i = 0; i < layers.length; i++) {
    const hit = detectModule.detect(layers[i].source);
    if (hit.plugin.name !== 'generic' && hit.plugin.name !== 'luarmor_client') {
      ctx.extras.push(trace);
      const inner = await unwrap(saved[i], layers[i].source, args, Object.assign({}, ctx, { depth: ctx.depth + 1 }));
      inner.notes.unshift(`unpacked from a loader layer (${layers[i].source.length} bytes passed to loadstring)`);
      return inner;
    }
  }

  const last = layers.length - 1;
  const chain = [source, ...layers.slice(0, last).map(l => l.source)];
  if (chain.every(layersModule.isThinWrapper)) {
    const payload = layers[last].source;
    if (layersModule.carriesPayload(chain[chain.length - 1], payload) &&
        layersModule.looksPlain(payload) && layersModule.parses(payload, saved[last] + '.chk')) {
      process.stderr.write(`[+] ${pad}the loader only unpacks a plain script: returning it unchanged (${payload.length} bytes)\n`);
      ctx.extras.push(trace);
      return { path: saved[last], raw: true, devirt: false, notes: [] };
    }
  }
  return { path: trace, raw: false, devirt: false, notes: [] };
}

async function processFile(absInput, args) {
  const source = fs.readFileSync(absInput, 'latin1');

  const outdir = path.join(path.dirname(absInput), 'output');
  fs.mkdirSync(outdir, { recursive: true });

  const os = require('os');
  const workdir = args.debug ? null : fs.mkdtempSync(path.join(os.tmpdir(), 'deobf_node_'));
  const final = (args.output && args.inputs.length === 1)
    ? args.output
    : path.join(outdir, path.basename(absInput));

  fs.mkdirSync(path.dirname(path.resolve(final)), { recursive: true });

  try {
    const ctx = { dir: workdir || outdir, depth: 0, extras: [] };
    const result = await unwrap(absInput, source, args, ctx);

    if (final && result && result.path && fs.existsSync(result.path)) {
      if (result.raw) {
        fs.copyFileSync(result.path, final);
      } else {
        let content = fs.readFileSync(result.path, 'utf8');
        content = content.replace(/^(\s*--(?:[ \t]*(?:Deobfuscated by|Detected obfuscation|Local names are inferred|source:|NOTE: reconstructed|during the trace)[^\n]*\n?|\s*\n))+/, '');
        if (result.notes.length) content = result.notes.map(n => `-- ${n}\n`).join('') + content;
        fs.writeFileSync(final, content, 'utf8');
      }
      const finalStem = final.replace(/(\.luau?|\.txt)$/i, '');
      for (const extra of ctx.extras) {
        if (!fs.existsSync(extra) || path.resolve(extra) === path.resolve(result.path)) continue;
        if (!fs.readFileSync(extra, 'latin1').trim()) continue;
        const m = /\.(layer\d+(?:_\d+)?)\.lua$/.exec(extra);
        const dest = m ? `${finalStem}.${m[1]}.lua`
          : /\.devirt\.luau$/.test(extra) ? `${finalStem}.partial.lua`
          : `${finalStem}.trace.lua`;
        if (path.resolve(dest) === path.resolve(extra) || path.resolve(dest) === path.resolve(final)) continue;
        fs.copyFileSync(extra, dest);
        ui.note(`also wrote ${dest}`);
      }
      ui.done('Done', final);
      return final;
    }
    ui.fail(`no result for ${path.basename(absInput)}`);
    return null;
  } finally {
    if (workdir && fs.existsSync(workdir)) {
      try { fs.rmSync(workdir, { recursive: true, force: true }); } catch {}
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (args.inputs.length === 0) {
    console.error('Usage: node deob.js <input.lua | folder> [more_files_or_folders...] [-o <output.lua>] [--plugin <name>] [--no-devirt] [--debug] [--detect]');
    process.exit(2);
  }

  const files = collectInputFiles(args.inputs);
  if (files.length === 0) {
    console.error('[!] no valid .lua / .luau input files found');
    process.exit(1);
  }

  if (args.detect) {
    for (const file of files) {
      const source = fs.readFileSync(file, 'latin1');
      let plugin, confidence;
      if (args.plugin) { plugin = detectModule.byName(args.plugin); confidence = 1.0; }
      else ({ plugin, confidence } = detectModule.detect(source));
      console.log(`${path.basename(file)}\t${plugin.name}\t${confidence.toFixed(2)}\t${detectModule.describe(plugin, source)}`);
    }
    return;
  }

  if (files.length > 1 && args.output) {
    process.stderr.write('[!] --output is ignored for multiple inputs (each file goes into its own output/ folder)\n');
  }

  let succeeded = 0;
  let failed = 0;

  for (const file of files) {
    if (files.length > 1) ui.step(`Processing ${path.basename(file)}`);
    try {
      const res = await processFile(file, args);
      if (res) succeeded++;
      else failed++;
    } catch (err) {
      ui.fail(`failed on ${path.basename(file)}: ${err.message || err}`);
      failed++;
    }
  }

  if (files.length > 1) ui.done(`${succeeded} succeeded, ${failed} failed`, `${files.length} files`);
  if (failed > 0 && succeeded === 0) process.exit(1);
}

main().catch(err => {
  ui.fatal('Fatal error: ' + (err.message || err));
  process.exit(1);
});
