'use strict';

const created = /^local ((?:ScreenGui|Frame|Path2D)\d*) = Instance\.new\("(?:ScreenGui|Frame|Path2D)"\)$/;
const property = /^(?:Frame|Path2D)\d*\.(?:Size|Position|AnchorPoint|Parent) = .+$/;
const method = /^(Path2D\d*):(\w+)\((.*)\)$/;
const destroyed = /^ScreenGui\d*:Destroy\(\)$/;
const measured = /^Get(?:Length|PositionOnCurve|PositionOnCurveArcLength|TangentOnCurve|TangentOnCurveArcLength)$/;

const prelude = `local lines = {}
local function num(x)
	return string.format("%.17g", x)
end
local function key(name, ...)
	local parts = { name }
	for i = 1, select("#", ...) do
		local a = select(i, ...)
		parts[#parts + 1] = type(a) == "number" and num(a) or typeof(a)
	end
	return table.concat(parts, "|")
end
local function enc(v)
	local t = typeof(v)
	if t == "number" then
		return "n:" .. num(v)
	elseif t == "UDim2" then
		return "u:" .. num(v.X.Scale) .. "," .. num(v.X.Offset) .. "," .. num(v.Y.Scale) .. "," .. num(v.Y.Offset)
	elseif t == "Vector2" then
		return "v:" .. num(v.X) .. "," .. num(v.Y)
	end
	return nil
end
local function rec(name, value, ...)
	local e = enc(value)
	if e then
		lines[#lines + 1] = key(name, ...) .. "\\t" .. e
	end
end
`;

function build(body, cacheName) {
  const out = [];
  const known = new Set();
  let queries = 0;
  for (const raw of String(body || '').split('\n')) {
    const line = raw.trim();
    if (!line || line.startsWith('--') || line.charCodeAt(0) === 0) continue;
    const made = created.exec(line);
    if (made) {
      known.add(made[1]);
      out.push(line);
      continue;
    }
    if (property.test(line)) {
      const owner = line.slice(0, line.indexOf('.'));
      if (known.has(owner)) out.push(`pcall(function() ${line} end)`);
      continue;
    }
    if (destroyed.test(line)) {
      const owner = line.slice(0, line.indexOf(':'));
      if (known.has(owner)) out.push(`pcall(function() ${line} end)`);
      continue;
    }
    const call = method.exec(line);
    if (!call || !known.has(call[1])) continue;
    const [, owner, name, args] = call;
    if (measured.test(name)) {
      queries += 1;
      const tail = args.trim() ? `, ${args}` : '';
      out.push(`pcall(function() rec("${name}", ${owner}:${name}(${args})${tail}) end)`);
    } else {
      out.push(`pcall(function() ${line} end)`);
    }
  }
  if (!queries) return null;
  const tailCode = `local text = table.concat(lines, "\\n") .. "\\n"
if writefile then
	pcall(writefile, ${JSON.stringify(cacheName)}, text)
end
if setclipboard then
	pcall(setclipboard, text)
end
print(text)
print(#lines .. " Path2D answers recorded")
`;
  return { text: prelude + out.join('\n') + '\n' + tailCode, queries };
}

module.exports = { build };
