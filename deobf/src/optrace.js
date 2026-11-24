#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const harness = require('./harness');
const vmmap = require('./vmmap');

const headRe = /while true do (?:local )?([A-Za-z_]+)(?:,[A-Za-z_]+)*=([A-Za-z_]+)\[([A-Za-z_]+)\];/g;

const dumpRuntime = `
local a = ...
local real, env, cfg = a.real, a.env, a.cfg
env.__opdump = function()
	local ring = env.__r
	local stop = cfg.optrace_stop
	local last = #ring
	if stop then
		for i = 1, #ring do
			local e = ring[i]
			if real.type(e) == "number" and math.floor(e / 268435456) == stop then last = i + 40 break end
		end
	end
	last = math.min(last, #ring)
	real.print("[optrace] " .. #ring .. " instructions recorded, showing up to entry " .. last)
	for i = real.max(1, last - (cfg.optrace_last or 3000)), last do
		local e = ring[i]
		if real.type(e) == "number" then
			local pc = e % 65536
			local rest = (e - pc) / 65536
			local op = rest % 256
			rest = (rest - op) / 256
			local loop = rest % 16
			real.print("P" .. (rest - loop) / 16 .. " L" .. loop .. " op" .. op .. " pc" .. pc)
		end
	end
end
`;

function patchHeads(src) {
  let count = 0;
  const out = src.replace(headRe, (m0, op, arr, pc) => {
    count += 1;
    return m0 + `__r[#__r+1]=(((__pid[__pv] or 0)*16+${count % 16})*256+${op}%256)*65536+${pc};`;
  });
  return { source: out, heads: count };
}

function instrument(src, filePath, key) {
  let out = vmmap.patchEntries(src, filePath, key);
  out = vmmap.patchSpin(out);
  return patchHeads(out);
}

function parseArgs(argv) {
  const args = { input: null, last: 3000, stop: null, timeout: 200, cfg: {} };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--last') args.last = parseInt(argv[++i], 10);
    else if (a === '--before-function') args.stop = parseInt(argv[++i], 10);
    else if (a === '--timeout') args.timeout = parseInt(argv[++i], 10);
    else if (a === '--cfg-json') Object.assign(args.cfg, JSON.parse(argv[++i]));
    else if (!a.startsWith('-')) args.input = a;
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.input) {
    console.error('Usage: node src/optrace.js <script.lua> [--last N] [--before-function ID] [--timeout S] [--cfg-json JSON]');
    process.exit(2);
  }
  const input = path.resolve(args.input);
  const source = fs.readFileSync(input, 'latin1');
  const luau = harness.findLuau();
  const main0 = instrument(source, input, harness.chunkKey(source));
  const hpath = input + '.optrace.harness.luau';
  const cfg = Object.assign({
    time_budget: 30, executor: 'Wave', devirt: true, spin: 24, skip_protos: [],
    inline_probe: true, plugin_rt: dumpRuntime, optrace_last: args.last,
  }, args.cfg);
  if (args.stop !== null) cfg.optrace_stop = args.stop;
  const version = require('./detect').luraphVersion(source);
  if (version && (version[0] > 15 || (version[0] === 15 && version[1] >= 2)) && !('cstack_pcall' in cfg)) cfg.cstack_pcall = true;

  const chunks = {};
  let heads = main0.heads;
  let body = null;
  for (let attempt = 1; attempt <= 3; attempt++) {
    const res = await harness.runOnce(luau, main0.source, cfg, hpath, args.timeout, false, chunks);
    body = res.body;
    if (!body) {
      process.stderr.write(`[!] run failed: ${String(res.err || '').trim().split('\n').pop()}\n`);
      break;
    }
    const found = harness.takeChunks(body).chunks;
    let added = 0;
    for (const [key, src] of found) {
      if (chunks[key]) continue;
      const tmp = input + `.optrace.chunk_${key}.luau`;
      fs.writeFileSync(tmp, src, 'latin1');
      try {
        const patched = instrument(src, tmp, key);
        chunks[key] = patched.source;
        heads += patched.heads;
        added += 1;
      } finally {
        try { fs.unlinkSync(tmp); } catch {}
      }
    }
    if (!added) break;
    process.stderr.write(`[*] ${added} loadstring'd VM chunk(s) instrumented; re-running\n`);
  }
  process.stderr.write(`[*] ${heads} dispatch loop heads patched\n`);
  const raw = harness.getLastRaw() || '';
  const status = /-- run status: ([^\r\n]*)/.exec(raw);
  process.stderr.write(`[*] run status: ${status ? status[1] : '?'}\n`);
  let shown = 0;
  for (const line of raw.split('\n')) {
    if (/^\[optrace\] |^P\d+ L\d+ op\d+ pc\d+/.test(line)) {
      process.stdout.write(line.replace(/\r$/, '') + '\n');
      shown += 1;
    }
  }
  if (!shown) process.stderr.write('[!] no instruction trace in the output (the ring is only dumped when the run fails or is aborted)\n');
}

main().catch(err => {
  process.stderr.write('[!] ' + (err.message || err) + '\n');
  process.exit(1);
});
