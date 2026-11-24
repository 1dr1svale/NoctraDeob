local server = "http://127.0.0.1:8000"

local http = game:GetService("HttpService")

local capture = {
	pid = { n = 0 },
	parg1 = {},
	ent = { n = 0 },
	plast = {},
	skipp = {},
	pa = { n = 0 },
	pf = setmetatable({}, { __mode = "k" }),
	pk = {},
}

local realEnv = getfenv()

local function stub(name, fn)
	if realEnv[name] == nil then
		return fn
	end
	return realEnv[name]
end

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

env.identifyexecutor = stub("identifyexecutor", function() return "Studio", "1.0" end)
env.getexecutorname = stub("getexecutorname", function() return "Studio" end)
env.islclosure = stub("islclosure", function(f) return type(f) == "function" end)
env.iscclosure = stub("iscclosure", function(f) return false end)
env.checkcaller = stub("checkcaller", function() return true end)
env.loadstring = stub("loadstring", loadstring)

local function fetch()
	return http:GetAsync(server .. "/script", true)
end

local function serializeValue(v, depth, seen, out)
	local t = typeof(v)
	if t == "number" then
		out[#out + 1] = tostring(v)
	elseif t == "boolean" then
		out[#out + 1] = v and "true" or "false"
	elseif t == "nil" then
		out[#out + 1] = "null"
	elseif t == "string" then
		out[#out + 1] = http:JSONEncode(v)
	elseif t == "buffer" then
		out[#out + 1] = http:JSONEncode({ __buf = (buffer.tostring(v):gsub(".", function(c)
			return string.format("%02x", string.byte(c))
		end)) })
	elseif t == "table" then
		if depth > 8 or seen[v] then
			out[#out + 1] = "\"<ref>\""
			return
		end
		seen[v] = true
		out[#out + 1] = "{"
		local first = true
		for k, val in pairs(v) do
			if type(k) == "number" or type(k) == "string" then
				if not first then out[#out + 1] = "," end
				first = false
				out[#out + 1] = http:JSONEncode(tostring(k)) .. ":"
				serializeValue(val, depth + 1, seen, out)
			end
		end
		out[#out + 1] = "}"
		seen[v] = nil
	else
		out[#out + 1] = http:JSONEncode({ __type = t, __repr = tostring(v) })
	end
end

local function run()
	print("[studio] fetching instrumented script...")
	local src = fetch()
	print("[studio] got", #src, "bytes; loading...")
	local chunk, err = loadstring(src, "=Script")
	if not chunk then
		warn("[studio] loadstring failed:", err)
		return
	end
	setfenv(chunk, env)
	print("[studio] running (this executes the loader in Studio's real environment)...")
	local ok, runErr = pcall(chunk)
	print("[studio] run finished. ok =", ok, "err =", runErr)

	local protoCount = 0
	for _ in pairs(capture.pa) do protoCount += 1 end
	print("[studio] captured", protoCount - 1, "proto-array sets")

	print("[studio] serializing...")
	local out = { "{\"source_note\":\"instrumented\",\"protos\":" }
	serializeValue(capture.pa, 0, {}, out)
	out[#out + 1] = ",\"pid\":"
	local pidMap = {}
	for proto, id in pairs(capture.pid) do
		if type(proto) == "table" then
			pidMap[tostring(id)] = capture.pa[proto] and true or false
		end
	end
	serializeValue(pidMap, 0, {}, out)
	out[#out + 1] = "}"
	local body = table.concat(out)
	print("[studio] posting", #body, "bytes to server...")
	local resp = http:PostAsync(server .. "/capture", body, Enum.HttpContentType.ApplicationJson)
	print("[studio] server said:")
	print(resp)
end

run()
