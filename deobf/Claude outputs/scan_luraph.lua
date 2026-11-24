-- read-only diagnostic: finds where a loaded Luraph v15 script keeps its
-- decrypted VM state in memory. does not hook, patch, or write anything.
-- run this AFTER the obfuscated script has loaded and started.

local out = {}
local function log(s)
	out[#out + 1] = s
	print(s)
end

local getgc = getgc or (getreg and function() return getreg() end)
local getupvalues = getupvalues or (debug and debug.getupvalues)
local getupvalue = getupvalue or (debug and debug.getupvalue)
local getinfo = (debug and debug.getinfo) or getinfo

log("== luraph scan ==")
log("getgc: " .. tostring(getgc ~= nil) .. "  getupvalues: " .. tostring(getupvalues ~= nil)
	.. "  getinfo: " .. tostring(getinfo ~= nil))

if not getgc then
	log("this executor has no getgc; tell me which executor you use")
	return
end

local function numericCount(t)
	local n, maxk = 0, 0
	local ok = pcall(function()
		for k, v in pairs(t) do
			if type(k) == "number" and type(v) == "number" then
				n = n + 1
				if k > maxk then maxk = k end
			end
		end
	end)
	if not ok then return 0, 0 end
	return n, maxk
end

local gc = getgc(true)
log("gc objects: " .. tostring(#gc))

local vmFuncs, bigTables, mtTables = 0, 0, 0
local sampleFunc, sampleBig, sampleMt

for _, o in ipairs(gc) do
	local tp = type(o)
	if tp == "function" then
		local ok, info = pcall(getinfo, o)
		if ok and info and type(info.source) == "string" and info.source:find("Luraph") then
			vmFuncs = vmFuncs + 1
			if not sampleFunc then sampleFunc = o end
		end
	elseif tp == "table" then
		local n, maxk = numericCount(o)
		if n >= 50 then
			bigTables = bigTables + 1
			if not sampleBig then sampleBig = { o, n, maxk } end
		end
		local ok, mt = pcall(getmetatable, o)
		if ok and type(mt) == "table" then
			local okf, idx = pcall(rawget, mt, "__index")
			if okf and idx ~= nil then
				mtTables = mtTables + 1
				if not sampleMt then sampleMt = o end
			end
		end
	end
end

log("VM interpreter closures (source contains 'Luraph'): " .. vmFuncs)
log("tables with >=50 numeric array entries (candidate instruction lanes): " .. bigTables)
log("tables with an __index metatable (candidate lazy constant views): " .. mtTables)

if sampleFunc and getupvalues then
	local ok, ups = pcall(getupvalues, sampleFunc)
	if ok and ups then
		local nup, bignum = 0, 0
		for _, u in pairs(ups) do
			nup = nup + 1
			if type(u) == "table" then
				local n = numericCount(u)
				if n >= 20 then bignum = bignum + 1 end
			end
		end
		log("sample VM closure: " .. nup .. " upvalues, " .. bignum .. " of them big numeric tables")
	end
end

if sampleBig then
	local t, n, maxk = sampleBig[1], sampleBig[2], sampleBig[3]
	local head = {}
	for i = 1, math.min(12, maxk) do head[#head + 1] = tostring(rawget(t, i)) end
	log("sample big table: " .. n .. " numeric entries, max index " .. maxk)
	log("  first entries: " .. table.concat(head, ","))
end

log("== end scan ==  copy everything above and send it back")
