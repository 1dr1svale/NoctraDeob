'use strict';

const luraphHeader = /This file was (?:protected|generated) using Luraph Obfuscator v(\d+)(?:\.(\d+))?/;
const luraphVmShape = /\[\d+\]=(bit32|buffer|string|table|math)\.\w+/;
const vmChunkStart = /[\s\]]*return setmetatable\(\{/;

function luraphVersion(source) {
  const m = luraphHeader.exec(source.slice(0, 4096));
  if (!m) return null;
  return [parseInt(m[1], 10), m[2] === undefined ? 0 : parseInt(m[2], 10)];
}

function hasVmShape(source) {
  const head = source.slice(0, 65536);
  const vm = vmChunkStart.exec(head);
  if (!vm) return false;
  const at = vm.index + vm[0].length - 'return setmetatable({'.length;
  const chunkHead = source.slice(at, at + 200000);
  return luraphVmShape.test(chunkHead) || chunkHead.includes('LPH');
}

function detectLuraph(source) {
  const v = luraphVersion(source);
  if (v) return v[0] === 15 ? 1.0 : (v[0] > 15 ? 0.6 : 0.0);
  return hasVmShape(source) ? 0.8 : 0.0;
}

function detectLuraph14(source) {
  const v = luraphVersion(source);
  return v && v[0] === 14 ? 1.0 : 0.0;
}

function detectLuraphLegacy(source) {
  const v = luraphVersion(source);
  return v && v[0] < 14 ? 1.0 : 0.0;
}

const headerLineRe = /\s*--[ \t]*This file was protected using Luraph Obfuscator v[\d.]+[ \t]*\[https?:\/\/lura\.ph\/?\]/;

function restoreHeaderNewline(source) {
  const m = headerLineRe.exec(source);
  if (m) {
    const end = m.index + m[0].length;
    const next = source[end];
    if (next !== '' && next !== '\n' && next !== '\r') {
      return source.slice(0, end) + '\n' + source.slice(end).replace(/^[ \t]+/, '');
    }
  }
  return source;
}

const luarmorSigs = [
  /luarmor\.net|Luarmor/i,
  /\bluraph_runtime1\s*\(/,
  /GetTutorialState\(\s*"nil\s+nil\s+/,
  /getfenv\(\)\s*\[\s*tbl\w+\s*\]\s*=/,
  /writefile\(\s*"luarmor-error-log\.txt"/,
  /[a-z]{1,3}\d-roblox-auth\.luarmor\.net/,
  /ce_like_loadstring_fn/,
  /Kick\(\s*"\[Luarmor\]/,
];

function detectLuarmor(source) {
  let hits = 0;
  for (const rx of luarmorSigs) {
    if (rx.test(source)) hits += 1;
  }
  if (hits >= 4) return 1.0;
  if (hits >= 3) return 0.9;
  if (hits >= 2) return 0.7;
  return 0.0;
}

const plugins = [
  {
    name: 'luraph_v15',
    label: 'Luraph v15',
    detect: detectLuraph,
    engine: 'luraph_v15',
  },
  {
    name: 'luraph_v14',
    label: 'Luraph v14',
    detect: detectLuraph14,
    engine: null,
    note: 'the v14 lifter is experimental (try it with --plugin luraph_v14): behaviour trace',
  },
  {
    name: 'luraph_legacy',
    label: 'Luraph (v13 or older)',
    detect: detectLuraphLegacy,
    engine: null,
    note: 'no lifter for this Luraph generation: behaviour trace',
  },
  {
    name: 'luarmor_client',
    label: 'Luarmor whitelist client (loader; payload not devirtualizable)',
    detect: detectLuarmor,
  },
];

const generic = { name: 'generic', label: 'unknown obfuscator (behaviour trace only)' };

function describe(plugin, source) {
  const v = luraphVersion(source);
  if (v && /^luraph_/.test(plugin.name)) return `Luraph v${v[0]}.${v[1]}`;
  return plugin.label;
}

function detect(source) {
  let best = { plugin: null, confidence: 0 };
  for (const p of plugins) {
    const c = p.detect(source);
    if (c > best.confidence) best = { plugin: p, confidence: c };
  }
  if (best.confidence < 0.5) {
    return { plugin: generic, confidence: 0 };
  }
  return { plugin: best.plugin, confidence: best.confidence };
}

function byName(name) {
  if (name === 'generic') return generic;
  const p = plugins.find(x => x.name === name);
  if (!p) throw new Error(`Unknown obfuscator '${name}' (known: ${plugins.map(x => x.name).join(', ')})`);
  return p;
}

module.exports = { detect, byName, describe, luraphVersion, restoreHeaderNewline, plugins, generic };
