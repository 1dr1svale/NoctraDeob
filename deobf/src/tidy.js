'use strict';

const keywords = new Set([
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if', 'in',
  'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while', 'continue'
]);

function stripMarkers(text) {
  return text.replace(/^[ \t]*--@[^\n]*(?:\n|$)/gm, '');
}

function stripPreamble(text) {

  const lines = text.split('\n');
  let cut = 0;

  for (let i = 0; i < Math.min(lines.length, 120); i++) {
    const l = lines[i];
    if (/\bPath2D\d*:GetTangentOnCurveArcLength\b|\bScreenGui\d*:Destroy\(\)/.test(l)) {
      cut = i + 1;
    }
  }
  if (cut > 0) {
    return lines.slice(cut).join('\n').replace(/^\n+/, '');
  }
  return text;
}

function space(text) {
  const lines = text.replace(/\r\n?/g, '\n').split('\n');
  const out = [];
  let blankCount = 0;

  for (const line of lines) {
    if (line.trim() === '') {
      blankCount++;
      if (blankCount > 1) continue;
    } else {
      blankCount = 0;
    }

    out.push(line);
  }

  return out.join('\n').trim() + '\n';
}

function stripAnnotations(text) {
  const lines = text.split('\n');
  const clean = [];
  let inUrlList = false;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('-- URLs requested:') ||
        trimmed.startsWith('-- remotes fired/invoked:') ||
        trimmed.startsWith('-- non-standard globals touched:') ||
        trimmed.startsWith('-- run status:') ||
        trimmed.startsWith('-- anti-tamper trap')) {
      inUrlList = true;
      continue;
    }
    if (inUrlList) {
      if (trimmed.startsWith('--   ') || trimmed === '--') continue;
      inUrlList = false;
    }
    if (trimmed.startsWith('-- [envlog]') ||
        trimmed.startsWith('-- isfolder(') ||
        trimmed.startsWith('-- isfile(') ||
        trimmed.startsWith('-- identifyexecutor(') ||
        trimmed.startsWith('-- condition:') ||
        trimmed.startsWith('-- loadstring() of') ||
        /^--\s*\d+\s+statements recorded/.test(trimmed)) {
      continue;
    }
    clean.push(line);
  }
  return clean.join('\n').replace(/^\n+/, '');
}

function tidy(text, options = {}) {
  let res = stripMarkers(text);
  res = stripAnnotations(res);
  if (options.preamble !== false) {
    res = stripPreamble(res);
  }
  return space(res);
}

module.exports = { tidy, stripMarkers, stripPreamble, stripAnnotations, space };
