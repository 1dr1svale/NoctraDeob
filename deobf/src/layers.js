'use strict';

const fs = require('fs');
const { loadAst } = require('./vmmap');

function measure(source) {
  const n = source.length;
  let code = 0;
  let data = 0;
  let i = 0;

  function longOpen(at) {
    if (source[at] !== '[') return 0;
    let j = at + 1;
    while (source[j] === '=') j++;
    return source[j] === '[' ? j - at + 1 : 0;
  }
  function skipLong(at, open) {
    const close = ']' + '='.repeat(open - 2) + ']';
    const end = source.indexOf(close, at + open);
    return end === -1 ? n : end + close.length;
  }

  while (i < n) {
    const c = source[i];
    if (c === '-' && source[i + 1] === '-') {
      const open = longOpen(i + 2);
      if (open) {
        i = skipLong(i + 2, open);
      } else {
        const nl = source.indexOf('\n', i);
        i = nl === -1 ? n : nl;
      }
      continue;
    }
    if (c === '"' || c === "'" || c === '`') {
      let j = i + 1;
      while (j < n && source[j] !== c) {
        if (source[j] === '\\') j++;
        else if (source[j] === '\n' && c !== '`') break;
        j++;
      }
      data += Math.max(0, j - i - 1);
      code += 2;
      i = j + 1;
      continue;
    }
    if (c === '[') {
      const open = longOpen(i);
      if (open) {
        const end = skipLong(i, open);
        data += Math.max(0, end - i - 2 * open);
        code += 2;
        i = end;
        continue;
      }
    }
    if (c !== ' ' && c !== '\t' && c !== '\r' && c !== '\n') code++;
    i++;
  }
  return { code, data };
}

function codeSize(source) {
  return measure(source).code;
}

function isThinWrapper(source) {
  const { code } = measure(source);
  return code <= 16384 && code <= Math.max(4096, source.length * 0.15);
}

function carriesPayload(wrapper, payload) {
  const { data } = measure(wrapper);
  return payload.length * 8 >= data;
}

function looksPlain(source) {
  const lines = source.split('\n');
  if (lines.length < 5) return false;
  const lens = lines.map(l => l.length).sort((a, b) => a - b);
  const median = lens[lens.length >> 1];
  let longChars = 0;
  for (const len of lens) if (len > 400) longChars += len;
  if (median > 120 || longChars > source.length * 0.2) return false;
  const escapes = (source.match(/\\(?:x[0-9a-fA-F]{2}|\d{1,3})/g) || []).length;
  return escapes * 12 < source.length;
}

function parses(source, tmpPath) {
  fs.writeFileSync(tmpPath, source, 'latin1');
  try {
    loadAst(tmpPath);
    return true;
  } catch {
    return false;
  } finally {
    try { fs.unlinkSync(tmpPath); } catch {}
  }
}

module.exports = { measure, codeSize, isThinWrapper, carriesPayload, looksPlain, parses };
