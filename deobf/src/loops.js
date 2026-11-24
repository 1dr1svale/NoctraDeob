'use strict';

const { loadAst, walkAst, loc } = require('./vmmap');

const inj = ' __spin.n=__spin.n+1;if __spin.n>=__spin.step then __spin.f()end;';

function patchAllLoops(source, filePath) {
  const root = loadAst(filePath);
  const edits = [];
  walkAst(root, (n) => {
    if ((n.type === 'AstStatWhile' || n.type === 'AstStatRepeat') && n.body && n.body.location) {
      const [l, c] = loc(n.body);
      edits.push([l, c]);
    }
  });
  if (!edits.length) return { source, loops: 0 };
  const lines = source.split('\n');
  edits.sort((a, b) => (b[0] !== a[0] ? b[0] - a[0] : b[1] - a[1]));
  for (const [l, c] of edits) {
    lines[l] = lines[l].slice(0, c) + inj + lines[l].slice(c);
  }
  return { source: lines.join('\n'), loops: edits.length };
}

module.exports = { patchAllLoops };
