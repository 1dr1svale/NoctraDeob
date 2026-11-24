'use strict';

const stream = process.stderr;
const enabled = !!stream.isTTY && !process.env.NO_COLOR && process.env.TERM !== 'dumb';

function wrap(code) {
  return function (s) {
    return enabled ? '\x1b[' + code + 'm' + s + '\x1b[0m' : String(s);
  };
}

const paint = {
  dim: wrap('2'),
  bold: wrap('1'),
  red: wrap('31'),
  green: wrap('32'),
  yellow: wrap('33'),
  cyan: wrap('36'),
  gray: wrap('90'),
  boldCyan: wrap('1;36'),
  boldGreen: wrap('1;32'),
  boldRed: wrap('1;31'),
  boldYellow: wrap('1;33'),
};

function line(s) {
  stream.write((s === undefined ? '' : s) + '\n');
}

function rule(n) {
  return paint.gray('━'.repeat(n));
}

function banner(title, value, tail) {
  const label = '  ' + title + '   ';
  const body = label + paint.boldCyan(value) + (tail ? '   ' + paint.gray(tail) : '');
  const width = Math.max(44, label.length + value.length + (tail ? tail.length + 3 : 0));
  line('');
  line('  ' + rule(width));
  line(body);
  line('  ' + rule(width));
}

function field(label, value) {
  const w = 14;
  const l = (label + ' '.repeat(w)).slice(0, w);
  line('  ' + paint.gray(l) + value);
}

function step(msg, tag) {
  line('');
  line('  ' + paint.boldCyan('→ ') + paint.bold(msg) + (tag ? '   ' + paint.gray(tag) : ''));
}

function sub(symbol, color, msg) {
  line('     ' + color(symbol) + '  ' + msg);
}

function ok(msg) { sub('✓', paint.green, msg); }
function warn(msg) { sub('!', paint.yellow, msg); }
function fail(msg) { sub('✗', paint.red, msg); }
function note(msg) { sub('·', paint.gray, paint.gray(msg)); }

function done(msg, detail) {
  line('');
  line('  ' + paint.boldGreen('✓ ' + msg) + (detail ? '   ' + paint.gray(detail) : ''));
}

function fatal(msg) {
  line('');
  line('  ' + paint.boldRed('✗ ' + msg));
}

function explainStatus(status) {
  const s = String(status || '').toLowerCase();
  const map = [
    ['buffer access out of bounds', 'the decryption key is wrong (an environment value did not match Roblox)'],
    ['size out of range', 'the decryption key is wrong (an environment value did not match Roblox)'],
    ['attempt to call a number value', 'the decrypted script called something that is not a function (likely an executor API the sandbox does not emulate)'],
    ['attempt to call a nil value', 'the decrypted script called a missing function (an API the sandbox does not provide)'],
    ['arithmetic (mod) on instance', 'the script did math on a Roblox object the sandbox returned as a placeholder'],
    ['arithmetic', 'the script did math on a value the sandbox returned as a placeholder, not a number'],
    ['attempt to index nil', 'the script read a field the sandbox does not provide'],
    ['get length of a number', 'the script used # on a value the sandbox returned as a number instead of a table or string'],
    ['get length of a nil', 'the script used # on a value the sandbox returned as nil'],
    ['endless loop', 'the script never returned (likely an anti-tamper loop or a missing environment value)'],
    ['never finished', 'the script never returned in the time allowed'],
    ['stack overflow', 'the script recursed too deep (often an anti-tamper depth probe)'],
  ];
  for (const [needle, plain] of map) {
    if (s.indexOf(needle) !== -1) return plain;
  }
  return null;
}

module.exports = {
  paint, line, banner, field, step, ok, warn, fail, note, done, fatal, explainStatus, enabled,
};
