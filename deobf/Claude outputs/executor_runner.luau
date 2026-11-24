-- Executor runner for the Luraph deobfuscator (v3).
-- runs instrumented.luau in the executor's real environment, forces every lazy
-- constant to decode in-memory (the VM has the correct key there), tags stdlib
-- functions/tables by name, and writes the full object graph to capture.json.
--
-- setup: put instrumented.luau in your executor's workspace folder, run this.

local INSTRUMENTED_FILE = "instrumented.luau"
local OUT_FILE = "capture.json"

local readfile = readfile or (getgenv and getgenv().readfile)
local writefile = writefile or (getgenv and getgenv().writefile)
assert(readfile and writefile, "this executor has no readfile/writefile")

local capture = {
	pid = { n = 0 }, parg1 = {}, ent = { n = 0 }, plast = {},
	skipp = {}, pa = { n = 0 }, pf = setmetatable({}, { __mode = "k" }), pk = {},
}

local realEnv = getfenv()
local env = setmetatable({}, { __index = realEnv })
env.__pid = capture.pid
env.__parg1 = capture.parg1
env.__ent = capture.ent
env.__plast = capture.plast
env.__skipp = capture.skipp
env.__pa = capture.pa
env.__pf = capture.pf
env.__pk = capture.pk
env.__spin = { n = 0, step = 1e9, f = function() end }

print("[exec] reading " .. INSTRUMENTED_FILE .. " ...")
local src = readfile(INSTRUMENTED_FILE)
print("[exec] got " .. #src .. " bytes; loading...")
local chunk, err = loadstring(src, "=Script")
if not chunk then warn("[exec] loadstring failed: " .. tostring(err)); return end
setfenv(chunk, env)
print("[exec] running in the executor's real environment...")
local ok, runErr = pcall(chunk)
print("[exec] run finished. ok = " .. tostring(ok) .. "  err = " .. tostring(runErr))

-- stdlib identity maps, so the lifter can see string.format / Vector3 / etc.
local fname, gname = {}, {}
local function mapLib(name, t)
	if type(t) ~= "table" then return end
	gname[t] = name
	for k, v in pairs(t) do
		if type(v) == "function" then fname[v] = name .. "." .. tostring(k) end
	end
end
for _, g in ipairs({ "string", "table", "math", "bit32", "buffer", "coroutine", "utf8", "os", "task", "debug" }) do
	mapLib(g, realEnv[g])
end
for _, g in ipairs({ "print", "warn", "assert", "error", "pcall", "xpcall", "select", "type", "typeof",
	"next", "pairs", "ipairs", "rawget", "rawset", "rawequal", "rawlen", "setmetatable", "getmetatable",
	"tostring", "tonumber", "unpack", "getfenv", "setfenv", "loadstring", "newproxy", "require" }) do
	if type(realEnv[g]) == "function" then fname[realEnv[g]] = g end
end
for _, g in ipairs({ "Vector3", "Vector2", "CFrame", "Color3", "UDim", "UDim2", "Rect", "Random",
	"Instance", "Enum", "Ray", "Region3", "BrickColor", "NumberRange", "NumberSequence",
	"ColorSequence", "Path2DControlPoint", "task", "vector" }) do
	local t = realEnv[g]
	if type(t) == "table" or type(t) == "userdata" then
		gname[t] = g
		if type(t) == "table" then
			for k, v in pairs(t) do
				if type(v) == "function" then fname[v] = g .. "." .. tostring(k) end
			end
		end
	end
end
gname[realEnv] = "ENV"
if realEnv.game then gname[realEnv.game] = "game" end
if realEnv.workspace then gname[realEnv.workspace] = "workspace" end

-- force every lazy constant view to decode, in-memory, with the real key.
local decoded = {}
local decodeCount = 0
local function forceDecode(t, seen)
	if type(t) ~= "table" or seen[t] then return end
	seen[t] = true
	local lane = rawget(t, -1)
	if type(lane) == "table" then
		local vals = {}
		for k in pairs(lane) do
			if type(k) == "number" and k >= 1 then
				local ok2, v = pcall(function() return t[k] end)
				if ok2 and v ~= nil then
					vals[k] = v
					decodeCount += 1
				end
			end
		end
		decoded[t] = vals
	end
	for k, v in pairs(t) do
		if type(k) == "table" then forceDecode(k, seen) end
		if type(v) == "table" then forceDecode(v, seen) end
	end
	local d = decoded[t]
	if d then for _, v in pairs(d) do if type(v) == "table" then forceDecode(v, seen) end end end
end
print("[exec] forcing constants to decode...")
pcall(function() forceDecode(capture.pa, {}) end)
print("[exec] decoded " .. decodeCount .. " constant slots")

-- object-graph serializer (stdlib tagged, decoded views included)
local idOf, nodes, nNodes = {}, {}, 0
local MAX_NODES = 2000000
local function ref(o)
	local id = idOf[o]
	if not id then nNodes += 1; id = nNodes; idOf[o] = id; nodes[id] = o end
	return id
end
local function jstr(s)
	return "\"" .. s:gsub('[%z\1-\31\\"]', function(c)
		local m = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
		return m[c] or string.format("\\u%04x", string.byte(c))
	end) .. "\""
end
local function hexbuf(b)
	return (buffer.tostring(b):gsub(".", function(c) return string.format("%02x", string.byte(c)) end))
end
local function encVal(v, out)
	local t = typeof(v)
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then out[#out + 1] = jstr("#" .. tostring(v))
		else out[#out + 1] = string.format("%.17g", v) end
	elseif t == "boolean" then out[#out + 1] = v and "true" or "false"
	elseif t == "nil" then out[#out + 1] = "null"
	elseif t == "string" then out[#out + 1] = jstr(v)
	elseif t == "function" then
		if fname[v] then out[#out + 1] = "{\"f\":" .. jstr(fname[v]) .. "}"
		else out[#out + 1] = "{\"r\":" .. ref(v) .. "}" end
	elseif t == "table" then
		if gname[v] then out[#out + 1] = "{\"g\":" .. jstr(gname[v]) .. "}"
		else out[#out + 1] = "{\"r\":" .. ref(v) .. "}" end
	elseif t == "buffer" then out[#out + 1] = "{\"buf\":\"" .. hexbuf(v) .. "\"}"
	elseif t == "vector" then out[#out + 1] = "{\"vec\":[" .. string.format("%.17g,%.17g,%.17g", v.x, v.y, v.z) .. "]}"
	else out[#out + 1] = "{\"u\":" .. jstr(t) .. ",\"s\":" .. jstr(tostring(v)) .. "}" end
end

local roots = { pa = capture.pa, pid = capture.pid, pk = capture.pk,
	parg1 = capture.parg1, plast = capture.plast, ent = capture.ent }
local rootIds = {}
for name, t in pairs(roots) do rootIds[name] = ref(t) end

local out = { "{\"roots\":{" }
local fr = true
for name, id in pairs(rootIds) do
	if not fr then out[#out + 1] = "," end
	fr = false
	out[#out + 1] = jstr(name) .. ":" .. id
end
out[#out + 1] = "},\"nodes\":{"

local cur, fn = 0, true
while cur < nNodes and cur < MAX_NODES do
	cur += 1
	local o = nodes[cur]
	if not fn then out[#out + 1] = "," end
	fn = false
	out[#out + 1] = "\"" .. cur .. "\":"
	if type(o) == "function" then
		out[#out + 1] = "{\"fn\":1}"
	else
		out[#out + 1] = "{\"h\":["
		local fp = true
		for k, v in pairs(o) do
			if not fp then out[#out + 1] = "," end
			fp = false
			out[#out + 1] = "["
			encVal(k, out)
			out[#out + 1] = ","
			encVal(v, out)
			out[#out + 1] = "]"
		end
		out[#out + 1] = "]"
		local d = decoded[o]
		if d then
			out[#out + 1] = ",\"dec\":["
			local fd = true
			for k, v in pairs(d) do
				if not fd then out[#out + 1] = "," end
				fd = false
				out[#out + 1] = "[" .. tostring(k) .. ","
				encVal(v, out)
				out[#out + 1] = "]"
			end
			out[#out + 1] = "]"
		end
		out[#out + 1] = "}"
	end
end
out[#out + 1] = "}}"

local body = table.concat(out)
writefile(OUT_FILE, body)
print("[exec] wrote " .. OUT_FILE .. " (" .. #body .. " bytes, " .. nNodes .. " nodes). send me that file.")
