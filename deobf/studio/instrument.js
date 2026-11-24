'use strict';
const fs = require('fs');
const path = require('path');

const inPath = process.argv[2];
const outPath = process.argv[3];
const vmmapPath = process.argv[4];

const vmmap = require(path.resolve(vmmapPath));
const src = fs.readFileSync(inPath, 'latin1');
const tmp = outPath + '.in.luau';
fs.writeFileSync(tmp, src, 'latin1');
try {
  const out = vmmap.patchEntries(src, tmp, 'studio');
  fs.writeFileSync(outPath, out, 'latin1');
  console.log('instrumented ' + src.length + ' -> ' + out.length + ' bytes');
} finally {
  try { fs.unlinkSync(tmp); } catch (e) {}
}
