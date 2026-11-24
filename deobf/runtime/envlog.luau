local cfg = __config or {}
local maxStmts = cfg.max_stmts or 250000
local maxBlock = cfg.max_block or 25000
local maxWaits = cfg.max_waits or 50
local maxDepth = cfg.max_depth or 24
local timeBudget = cfg.time_budget or 30

local real = {
        type = type, typeof = typeof, tostring = tostring, tonumber = tonumber,
        pairs = pairs, ipairs = ipairs, next = next, select = select,
        rawget = rawget, rawset = rawset, rawequal = rawequal, rawlen = rawlen,
        setmetatable = setmetatable, getmetatable = getmetatable,
        pcall = pcall, xpcall = xpcall, error = error,
        getfenv = __raw.getfenv, setfenv = __raw.setfenv, loadstring = __raw.loadstring,
        newproxy = newproxy, print = print, clock = os.clock,
        unpack = table.unpack, insert = table.insert, concat = table.concat,
        remove = table.remove, fmt = string.format, rep = string.rep,
        gsub = string.gsub, match = string.match, byte = string.byte,
        sub = string.sub, find = string.find, sort = table.sort,
        lower = string.lower,
        floor = math.floor, huge = math.huge, max = math.max,
}
real.json = (function()
        local jsonEsc = {['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['\b'] = '\\b', ['\f'] = '\\f'}
        local function encodeString(s)
                return '"' .. string.gsub(s, '[%c"\\]', function(c)
                        return jsonEsc[c] or string.format("\\u%04x", string.byte(c))
                end) .. '"'
        end
        local function encode(v, seen)
                local t = type(v)
                if v == nil then return "null" end
                if t == "boolean" then return v and "true" or "false" end
                if t == "number" then
                        if v ~= v or v == math.huge or v == -math.huge then return "null" end
                        if v == math.floor(v) and math.abs(v) < 2 ^ 53 then
                                return string.format("%d", v)
                        end
                        return tostring(v)
                end
                if t == "string" then return encodeString(v) end
                if t == "table" then
                        if seen[v] then error("cannot encode recursive table", 2) end
                        seen[v] = true
                        local n = 0
                        local isArr = true
                        for k in pairs(v) do
                                if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
                                        isArr = false
                                else
                                        n = n + 1
                                end
                        end
                        local parts = {}
                        if isArr and n > 0 then
                                for i = 1, n do
                                        parts[i] = encode(v[i], seen)
                                end
                                seen[v] = nil
                                return "[" .. table.concat(parts, ",") .. "]"
                        end
                        local keys = {}
                        for k in pairs(v) do
                                if type(k) == "string" or type(k) == "number" then
                                        keys[#keys + 1] = k
                                end
                        end
                        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
                        for i, k in ipairs(keys) do
                                parts[i] = encodeString(tostring(k)) .. ":" .. encode(v[k], seen)
                        end
                        seen[v] = nil
                        return "{" .. table.concat(parts, ",") .. "}"
                end
                error("cannot encode value of type " .. t, 2)
        end
        local function decode(s, pos)
                pos = pos or 1
                local function skipWs(p)
                        while p <= #s do
                                local c = string.sub(s, p, p)
                                if c == " " or c == "\t" or c == "\n" or c == "\r" then p = p + 1 else break end
                        end
                        return p
                end
                local parseValue
                local function parseString(p)
                        p = p + 1
                        local buf = {}
                        while p <= #s do
                                local c = string.sub(s, p, p)
                                if c == '"' then
                                        return table.concat(buf), p + 1
                                elseif c == "\\" then
                                        local e = string.sub(s, p + 1, p + 1)
                                        if e == "u" then
                                                local hex = string.sub(s, p + 2, p + 5)
                                                local code = tonumber(hex, 16)
                                                p = p + 6
                                                if code < 0x80 then
                                                        buf[#buf + 1] = string.char(code)
                                                elseif code < 0x800 then
                                                        buf[#buf + 1] = string.char(0xC0 + math.floor(code / 64), 0x80 + code % 64)
                                                else
                                                        buf[#buf + 1] = string.char(0xE0 + math.floor(code / 4096),
                                                                0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
                                                end
                                        else
                                                local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
                                                buf[#buf + 1] = map[e] or e
                                                p = p + 2
                                        end
                                else
                                        buf[#buf + 1] = c
                                        p = p + 1
                                end
                        end
                        error("unterminated string", 0)
                end
                parseValue = function(p)
                        p = skipWs(p)
                        local c = string.sub(s, p, p)
                        if c == '"' then
                                return parseString(p)
                        elseif c == "{" then
                                local obj = {}
                                p = skipWs(p + 1)
                                if string.sub(s, p, p) == "}" then return obj, p + 1 end
                                while true do
                                        p = skipWs(p)
                                        local k
                                        k, p = parseString(p)
                                        p = skipWs(p)
                                        if string.sub(s, p, p) ~= ":" then error("expected :", 0) end
                                        local v
                                        v, p = parseValue(p + 1)
                                        obj[k] = v
                                        p = skipWs(p)
                                        local d = string.sub(s, p, p)
                                        if d == "," then p = p + 1
                                        elseif d == "}" then return obj, p + 1
                                        else error("expected , or }", 0) end
                                end
                        elseif c == "[" then
                                local arr = {}
                                p = skipWs(p + 1)
                                if string.sub(s, p, p) == "]" then return arr, p + 1 end
                                while true do
                                        local v
                                        v, p = parseValue(p)
                                        arr[#arr + 1] = v
                                        p = skipWs(p)
                                        local d = string.sub(s, p, p)
                                        if d == "," then p = p + 1
                                        elseif d == "]" then return arr, p + 1
                                        else error("expected , or ]", 0) end
                                end
                        elseif string.sub(s, p, p + 3) == "true" then
                                return true, p + 4
                        elseif string.sub(s, p, p + 4) == "false" then
                                return false, p + 5
                        elseif string.sub(s, p, p + 3) == "null" then
                                return nil, p + 4
                        else
                                local num = string.match(s, "^%-?%d+%.?%d*[eE]?%+?%-?%d*", p)
                                if not num or num == "" then
                                        num = string.match(s, "^%-?%d+", p)
                                end
                                if num and num ~= "" then
                                        return tonumber(num), p + #num
                                end
                                error("unexpected character at " .. p .. ": " .. string.sub(s, p, p + 10), 0)
                        end
                end
                return parseValue(pos)
        end
        local function jd(s)
                if type(s) == "buffer" then s = buffer.tostring(s) end
                return decode(tostring(s))
        end
        return { encode = function(v) return encode(v, {}) end, decode = jd }
end)()
local realGlobals = real.getfenv(0)
local harnessSrc0 = debug.info(1, "s")

local markPrefix = "\0" .. (__mark or "")

local protocol = { hash_mult = 31, hash_mod = 2147483648, hash_stride = 4096, chunk_min = 4096 }

local native = cfg.native and real.typeof(realGlobals.game) == "Instance"
local outBuf = {}
if native then
        real.print = function(...)
                local t = table.pack(...)
                for i = 1, t.n do t[i] = real.tostring(t[i]) end
                real.insert(outBuf, real.concat(t, "\t", 1, t.n))
                if cfg.print_tail and #outBuf > 2 * cfg.print_tail then
                        outBuf = table.move(outBuf, #outBuf - cfg.print_tail + 1, #outBuf, 1, {})
                end
        end
end
local startClock = real.clock()

local loopMark = real.setmetatable({}, { __tostring = function() return "<envlog: loop truncated>" end })
local abort = real.setmetatable({}, { __tostring = function() return "<envlog: budget exhausted>" end })
local tamper = real.setmetatable({}, { __tostring = function() return "<envlog: anti-tamper suppressed>" end })
local abortReason = nil
local tamperCount = 0
local trigger, noteTrigger = nil, nil

local rootTrace = { lines = {}, waits = {} }
local traceStack = { rootTrace }
local stmtCount = 0

local hub = { pf = nil, pid = nil, plast = nil }
function hub.get()
        local pf, pid, plast = hub.pf, hub.pid, hub.plast
        local parts = {}
        local lvl = 3
        local inner = nil
        while true do
                local f = debug.info(lvl, "f")
                if f == nil then break end
                local proto = pf[f]
                local id = proto and pid[proto]
                if id then
                        if id == 1 and #parts > 0 then inner = parts[1] end
                        real.insert(parts, 1, id .. ":" .. real.tostring(plast[id]))
                end
                lvl += 1
        end
        hub.seen = hub.seen or {}
        if inner and parts[1] == "1:" .. real.tostring(plast[1]) then
                local c = real.tonumber(real.match(inner, "^(%d+):"))
                hub.rootCallee = c
                hub.seen[c] = hub.seen[c] or "ok"
        elseif #parts == 1 and real.match(parts[1], "^1:") then
                for c in real.next, hub.seen do hub.seen[c] = "probe" end
                hub.rootCallee = nil
        elseif #parts >= 1 and not real.match(parts[1], "^1:") and (not hub.rootCallee or hub.seen[hub.rootCallee] == "probe") then
                local c = real.tonumber(real.match(parts[1], "^(%d+):"))
                if c and hub.seen[c] ~= "probe" then
                        hub.rootCallee = c
                        hub.seen[c] = "ok"
                end
        end
        return real.concat(parts, ",")
end

local function curBlock()
        return traceStack[#traceStack]
end

local abortHits = 0
local function checkBudget()
        if hub.unlimited then return end
        if abortReason then
                abortHits += 1
                if abortHits > 1 and coroutine.isyieldable() then coroutine.yield(abort) end
                real.error(abort, 0)
        end
        if stmtCount > maxStmts then
                abortReason = "statement limit reached"
                real.error(abort, 0)
        end
        local now = real.clock()
        if now - startClock > timeBudget then
                abortReason = "time budget exhausted"
                real.error(abort, 0)
        end
        if cfg.heartbeat and now - (cfg._hb or startClock) > cfg.heartbeat then
                cfg._hb = now
                real.print(markPrefix .. "HB\n" .. real.rep(" ", 16384))
        end
end

local function emit(stmt)
        checkBudget()
        if hub.syncGenv and not hub.syncing then hub.syncGenv() end
        local b = curBlock()
        if b.stopped then
                b.stopped += 1
                if b.stopped > 200 then
                        abortReason = "a stopped loop kept running (its error was caught by the script)"
                        real.error(abort, 0)
                end
                real.error(loopMark, 0)
        end
        stmtCount += 1
        if hub.pf then stmt.chain = hub.get() end
        real.insert(b.lines, stmt)
        for i = #traceStack, 1, -1 do
                local rb = traceStack[i]
                if rb.isRoot or i == 1 then
                        rb.tape = rb.tape or {}
                        real.insert(rb.tape, { stmt = stmt, block = b })
                        break
                end
        end
        if #b.lines > maxBlock then
                real.insert(b.lines, { text = "-- [envlog] block truncated after " .. maxBlock .. " statements" })
                b.stopped = 0
                real.error(loopMark, 0)
        end
        return stmt
end

local function comment(s)
        return emit({ text = "-- " .. s })
end

local infoOf = real.setmetatable({}, { __mode = "k" })
local byId = {}

real.auditState = {
    events = {},
    dropped = 0,
    max_events = cfg.audit_max_events or 10000,
    max_value = cfg.audit_max_value or 512,
}

real.auditSecretKeys = {
    token = true,
    accesstoken = true,
    refreshtoken = true,
    authorization = true,
    cookie = true,
    password = true,
    passwd = true,
    apikey = true,
    secret = true,
    sessionid = true,
}

real.auditRedactKey = function(k)
    if real.type(k) ~= "string" then return false end
    local key = real.gsub(real.lower(k), "[^%w]", "")
    return real.auditSecretKeys[key] == true
        or real.find(key, "token", 1, true) ~= nil
        or real.find(key, "password", 1, true) ~= nil
        or real.find(key, "secret", 1, true) ~= nil
end

real.auditValue = function(v, depth, seen)
    local t = real.type(v)

    if t == "nil" then return { type = "nil" } end
    if t == "boolean" or t == "number" then
        return { type = t, value = v }
    end

    if t == "string" then
        if #v > real.auditState.max_value then
            return { type = t, truncated = true, length = #v }
        end
        return { type = t, value = v }
    end

    if t == "function" then return { type = "function" } end

    if t == "userdata" and infoOf[v] then
        local info = infoOf[v]
        return {
            type = "proxy",
            id = info.id,
            kind = info.kind,
            name = info.name or info.hint or info.key,
            className = info.className,
        }
    end

    if t ~= "table" then return { type = t } end

    depth = depth or 0
    seen = seen or {}

    if seen[v] then return { type = "table", circular = true } end
    if depth >= 3 then return { type = "table", truncated = true } end

    seen[v] = true
    local out = { type = "table", entries = {}, truncated = false }
    local count = 0

    for k, value in real.next, v do
        count += 1
        if count > 30 then
            out.truncated = true
            break
        end

        local key = real.type(k) == "string" and k or real.tostring(k)

        if real.auditRedactKey(key) then
            out.entries[key] = "[REDACTED]"
        else
            out.entries[key] = real.auditValue(value, depth + 1, seen)
        end
    end

    seen[v] = nil
    return out
end

real.audit = function(kind, fields)
    if cfg.audit == false then return end

    local state = real.auditState
    if #state.events >= state.max_events then
        state.dropped += 1
        return
    end

    fields = fields or {}
    fields.event = kind
    fields.seq = #state.events + 1
    fields.time = real.clock() - startClock

    state.events[#state.events + 1] = fields
end

local nextId = 0
local proxyMeta = {}
local isMethodName, methodFn
local methodProxyRef

local function isP(v)
        return real.type(v) == "userdata" and infoOf[v] ~= nil
end

local function newP(info)
        nextId += 1
        info.id = nextId
        info.children = {}
        info.props = {}
        local p = real.newproxy(true)
        local mt = real.getmetatable(p)
        for k, f in proxyMeta do
                mt[k] = f
        end
        infoOf[p] = info
        byId[nextId] = p
        return p
end

local function tok(p)
        return "\1" .. infoOf[p].id .. "\2"
end

local function isIdent(s)
        return real.type(s) == "string" and real.match(s, "^[%a_][%w_]*$") ~= nil and not ({
                ["and"] = 1, ["break"] = 1, ["do"] = 1, ["else"] = 1, ["elseif"] = 1, ["end"] = 1,
                ["false"] = 1, ["for"] = 1, ["function"] = 1, ["if"] = 1, ["in"] = 1, ["local"] = 1,
                ["nil"] = 1, ["not"] = 1, ["or"] = 1, ["repeat"] = 1, ["return"] = 1, ["then"] = 1,
                ["true"] = 1, ["until"] = 1, ["while"] = 1, ["continue"] = 1,
        })[s]
end

local function quote(s)
        local out = real.gsub(s, '[%c"\\\128-\255]', function(c)
                if c == "\n" then return "\\n" end
                if c == "\t" then return "\\t" end
                if c == "\r" then return "\\r" end
                if c == '"' then return '\\"' end
                if c == "\\" then return "\\\\" end
                local b = real.byte(c)
                return "\\" .. b
        end)
        return '"' .. out .. '"'
end

local function fmtNumber(n)
        if n ~= n then return "0/0" end
        if n == real.huge then return "math.huge" end
        if n == -real.huge then return "-math.huge" end
        if n == real.floor(n) and n > -1e15 and n < 1e15 then
                return real.fmt("%d", n)
        end
        local s = real.fmt("%.14g", n)
        if real.tonumber(s) ~= n then s = real.fmt("%.17g", n) end
        return s
end

local fmt
local genvTable
local genvName = real.setmetatable({}, { __mode = "k" })
local captureFunction
local fnText = real.setmetatable({}, { __mode = "k" })
local cfuncs = real.setmetatable({}, { __mode = "k" })
local cnames = real.setmetatable({}, { __mode = "k" })
local threadProxy = real.setmetatable({}, { __mode = "k" })

local makeTramp = real.loadstring("local impl = ... return function(...) return impl(...) end", "=" .. harnessSrc0)
local tramps = {}
local trampEnv = nil
local function tramp(impl)
        local t = makeTramp(impl)
        if trampEnv then real.setfenv(t, trampEnv) else real.insert(tramps, t) end
        return t
end

local function keySuffix(k)
        if isIdent(k) then
                return "." .. k
        end
        return "[" .. fmt(k) .. "]"
end

local scriptEnv

function fmt(v, depth, seen)
        local t = real.type(v)
        if t == "nil" then return "nil" end
        if t == "boolean" then return real.tostring(v) end
        if t == "number" then return fmtNumber(v) end
        if t == "string" then return quote(v) end
        if t == "userdata" then
                if infoOf[v] then return tok(v) end
                return "nil --[[userdata]]"
        end
        if t == "function" then
                if fnText[v] then return fnText[v] end
                if methodProxyRef and methodProxyRef[v] then return tok(methodProxyRef[v]) end
                return captureFunction(v)
        end
        if t == "table" then
                if v == scriptEnv then return "getfenv()" end
                if genvName[v] then return genvName[v] end
                depth = depth or 0
                seen = seen or {}
                if seen[v] then return "{ --[[cycle]] }" end
                if depth > 6 then return "{ --[[...]] }" end
                seen[v] = true
                local parts = {}
                local n = 0
                for i = 1, 1e9 do
                        local x = real.rawget(v, i)
                        if x == nil then break end
                        n = i
                        real.insert(parts, fmt(x, depth + 1, seen))
                end
                local keys = {}
                for k in real.next, v do
                        if not (real.type(k) == "number" and k >= 1 and k <= n and k % 1 == 0) then
                                real.insert(keys, k)
                        end
                end
                local function rank(k)
                        local x = real.rawget(v, k)
                        if real.type(x) == "function" then return 4 end
                        if k == "Title" or k == "Name" or k == "Text" then return 1 end
                        if k == "Desc" or k == "Description" or k == "Content" then return 2 end
                        return 3
                end
                real.sort(keys, function(a, b)
                        local ta, tb = real.type(a), real.type(b)
                        if ta ~= tb then return ta < tb end
                        if ta == "string" then
                                local ra, rb = rank(a), rank(b)
                                if ra ~= rb then return ra < rb end
                                return a < b
                        end
                        if ta == "number" then return a < b end
                        return false
                end)
                for _, k in keys do
                        local key = isIdent(k) and k or ("[" .. fmt(k, depth + 1, seen) .. "]")
                        local x = real.rawget(v, k)
                        if k == "Callback" and real.type(x) == "function" then cfg._cbtry = true end
                        real.insert(parts, key .. " = " .. fmt(x, depth + 1, seen))
                        cfg._cbtry = nil
                end
                seen[v] = nil
                if #parts == 0 then return "{}" end
                local flat = "{ " .. real.concat(parts, ", ") .. " }"
                if #flat <= 100 and not real.find(flat, "\3", 1, true) then return flat end
                local ind = real.rep("\t", depth + 1)
                return "{\n" .. ind .. real.concat(parts, ",\n" .. ind) .. "\n" .. real.rep("\t", depth) .. "}"
        end
        if t == "vector" then
                return "Vector3.new(" .. fmtNumber(v.x) .. ", " .. fmtNumber(v.y) .. ", " .. fmtNumber(v.z) .. ")"
        end
        if t == "buffer" then return "buffer.create(" .. buffer.len(v) .. ")" end
        if t == "thread" and threadProxy[v] then return tok(threadProxy[v]) end
        return "nil --[[" .. t .. "]]"
end

local function fmtArgs(...)
        local n = real.select("#", ...)
        local parts = {}
        for i = 1, n do
                parts[i] = fmt((real.select(i, ...)))
        end
        return real.concat(parts, ", ")
end

local function globalP(name, tname)
        return newP({ kind = "name", name = name, tname = tname or "Instance" })
end

local function exprP(text, tname, hint)
        return newP({ kind = "expr", text = text, tname = tname or "Instance", hint = hint })
end

local api = { enums = {}, classes = {} }
do
        local src = __roblox or { enums = "", classes = "" }
        for ename, items in string.gmatch(src.enums, "([%w_]+):([^;]*)") do
                local e = { name = ename, items = {}, byName = {}, byValue = {} }
                for iname, v in string.gmatch(items, "([%w_]+)=(%-?%d+)") do
                        local item = { Name = iname, Value = real.tonumber(v) }
                        real.insert(e.items, item)
                        e.byName[iname] = item
                        if e.byValue[item.Value] == nil then e.byValue[item.Value] = item end
                end
                api.enums[ename] = e
        end
        for cname, super, fns, evs, props in string.gmatch(src.classes, "([%w_]+)<([%w_]*)|([^|]*)|([^|]*)|([^;]*)") do
                local c = { super = super ~= "" and super or nil, m = {}, e = {}, p = {} }
                for x in string.gmatch(fns, "[^,]+") do c.m[x] = true end
                for x in string.gmatch(evs, "[^,]+") do c.e[x] = true end
                for x in string.gmatch(props, "[^,]+") do
                        local name, vt = real.match(x, "^([^:]+):?(.*)$")
                        c.p[name] = vt ~= "" and vt or true
                end
                api.classes[cname] = c
        end
end

local function memberKind(cls, k)
        local guard = 0
        while cls and guard < 32 do
                guard += 1
                local c = api.classes[cls]
                if not c then return nil end
                if c.m[k] then return "method" end
                if c.e[k] then return "event" end
                if c.p[k] then return "prop" end
                cls = c.super
        end
        return nil
end

local function propType(cls, k)
        local guard = 0
        while cls and guard < 32 do
                guard += 1
                local c = api.classes[cls]
                if not c then return nil end
                local v = c.p[k]
                if v then return v ~= true and v or nil end
                cls = c.super
        end
        return nil
end

local numericT = { float = true, double = true, int = true, int64 = true, int32 = true, int16 = true, number = true }
local numDefault = { Health = 100, MaxHealth = 100, WalkSpeed = 16, JumpPower = 50, JumpHeight = 7.2,
        HipHeight = 2, Gravity = 196.2, FieldOfView = 70, MaxSlopeAngle = 89, TimePosition = 0, Volume = 0.5,
        TimeLength = 1, Speed = 1, Brightness = 1, Range = 16, Size = 1 }
local dtMembers = {
        Vector3 = { X = "n", Y = "n", Z = "n", Magnitude = "n", Unit = "Vector3" },
        Vector2 = { X = "n", Y = "n", Magnitude = "n", Unit = "Vector2" },
        CFrame = { X = "n", Y = "n", Z = "n", Position = "Vector3", p = "Vector3", LookVector = "Vector3",
                RightVector = "Vector3", UpVector = "Vector3", XVector = "Vector3", YVector = "Vector3", ZVector = "Vector3",
                Rotation = "CFrame" },
        UDim2 = { X = "UDim", Y = "UDim", Width = "UDim", Height = "UDim" },
        UDim = { Scale = "n", Offset = "n" },
        Color3 = { R = "n", G = "n", B = "n" },
        NumberRange = { Min = "n", Max = "n" },
        Rect = { Width = "n", Height = "n", Min = "Vector2", Max = "Vector2" },
}

local propClass = {
        LocalPlayer = "Player", Character = "Model", CurrentCamera = "Camera", PlayerGui = "PlayerGui",
        Backpack = "Backpack", PrimaryPart = "Part", HumanoidRootPart = "Part", Head = "Part", Torso = "Part",
        UpperTorso = "MeshPart", LowerTorso = "MeshPart", PlayerScripts = "PlayerScripts", Terrain = "Terrain",
        leaderstats = "Folder", Animator = "Animator",
}

local function childClass(pi, key)
        if real.type(key) ~= "string" then return nil end
        if propClass[key] then return propClass[key] end
        if pi.className and memberKind(pi.className, key) == "prop" then return nil end
        if api.classes[key] and not api.enums[key] then return key end
        return nil
end

local function indexP(parent, key)
        local pi = infoOf[parent]
        local c = pi.children[key]
        if c then return c end
        c = newP({ kind = "index", parent = parent, key = key,
                tname = pi.childT or "Instance",
                hint = real.type(key) == "string" and key or nil, ns = pi.ns,
                className = pi.tname == "Instance" and childClass(pi, key) or nil })
        pi.children[key] = c
        return c
end

local enumRoot
local function enumType(name)
        local c = infoOf[enumRoot].children[name]
        if c then return c end
        c = indexP(enumRoot, name)
        infoOf[c].tname = "Enum"
        infoOf[c].enumName = name
        infoOf[c].className = nil
        return c
end
local function enumItem(ename, iname)
        local et = enumType(ename)
        local c = infoOf[et].children[iname]
        if c then return c end
        local item = api.enums[ename].byName[iname]
        c = indexP(et, iname)
        local info = infoOf[c]
        info.tname = "EnumItem"
        info.enumName = ename
        info.className = nil
        info.props.Name = iname
        info.props.Value = item.Value
        info.props.EnumType = et
        return c
end

local realValues = real.setmetatable({}, { __mode = "k" })
hub.dtUnsupported = __roblox and __roblox.datatypes and __roblox.datatypes.unsupported
local noReal = real.setmetatable({}, { __tostring = function() return "<envlog: no native twin>" end })

local function unwrap(v, depth)
        if isP(v) then
                local r = realValues[v]
                if r ~= nil then return r end
                if infoOf[v] and infoOf[v].tname == "EnumItem" then return v end
                real.error(noReal, 0)
        elseif real.type(v) == "table" and depth < 3 then
                local t = {}
                for k, x in real.pairs(v) do t[unwrap(k, depth + 1)] = unwrap(x, depth + 1) end
                return t
        elseif real.type(v) == "function" or real.type(v) == "thread" then
                real.error(noReal, 0)
        end
        return v
end
local function unwrapArgs(args)
        local ok, out = real.pcall(function()
                local o = { n = args.n }
                for i = 1, args.n do o[i] = unwrap(args[i], 0) end
                return o
        end)
        if ok then return out end
        if out ~= noReal then real.error(out, 0) end
        return nil
end
local function realOf(v)
        if isP(v) then return realValues[v], realValues[v] ~= nil end
        if real.type(v) == "table" or real.type(v) == "function" then return nil, false end
        return v, true
end

local plainT = { number = true, string = true, boolean = true, ["nil"] = true, vector = true }
local function nativeClass(inst)
        return inst:IsA("GuiBase") or inst:IsA("UIBase")
end
local function wrapReal(r, text, hint, depth)
        if isP(r) then return r, true end
        local t = real.type(r)
        if plainT[t] then return r, true end
        local tt = real.typeof(r)
        if tt == "userdata" and not native then tt = __roblox.datatypes.typeOf(r) or tt end
        if tt == "EnumItem" then
                local ename = real.tostring(r.EnumType)
                if api.enums[ename] and api.enums[ename].byName[r.Name] then return enumItem(ename, r.Name), true end
                return nil, false
        end
        if tt == "Instance" or tt == "RBXScriptSignal" or tt == "RBXScriptConnection" or t == "function" or t == "thread" then
                return nil, false
        end
        if t == "table" then
                if (depth or 0) > 2 then return nil, false end
                local out = {}
                for k, x in real.pairs(r) do
                        local w, ok = wrapReal(x, text .. "[" .. fmt(k) .. "]", hint, (depth or 0) + 1)
                        if not ok then return nil, false end
                        out[k] = w
                end
                return out, true
        end
        local p = exprP(text, tt, hint)
        realValues[p] = r
        return p, true
end
local function attachReal(p, libName, k, call, ...)
        local lib
        if native then
                lib = realGlobals[libName]
        else
                lib = __roblox and __roblox.datatypes and __roblox.datatypes[libName]
                if real.type(lib) ~= "table" then return end
        end
        if lib == nil then return end
        local u = unwrapArgs(table.pack(...))
        if not u then return end
        local ok, r = real.pcall(function()
                local f = lib[k]
                if call then return f(real.unpack(u, 1, u.n)) end
                return f
        end)
        if ok and r ~= nil and real.type(r) ~= "table" then realValues[p] = r end
end

local p2dLog = {}
local p2dMiss = false
local function p2dKey(name, args)
        local parts = { name }
        for i = 1, args.n do
                local a = args[i]
                parts[#parts + 1] = real.type(a) == "number" and real.fmt("%.17g", a) or real.tostring(real.typeof(a))
        end
        return real.concat(parts, "|")
end
local function p2dEncode(v)
        local t = real.typeof(v)
        if t == "number" then return real.fmt("n:%.17g", v) end
        if t == "UDim2" then return real.fmt("u:%.17g,%.17g,%.17g,%.17g", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset) end
        if t == "Vector2" then return real.fmt("v:%.17g,%.17g", v.X, v.Y) end
        if t == "nil" then return "z:" end
        return nil
end
local function p2dDecode(str, text)
        local kind, rest = real.match(str, "^(%a):(.*)$")
        if kind == "n" then return real.tonumber(rest) end
        if kind == "z" then return nil end
        local nums = {}
        for x in string.gmatch(rest, "[^,]+") do nums[#nums + 1] = real.tonumber(x) end
        if kind == "u" then
                local p = exprP(text, "UDim2", "position")
                local xs = exprP(text .. ".X", "UDim", "X")
                infoOf[xs].props.Scale, infoOf[xs].props.Offset = nums[1], nums[2]
                local ys = exprP(text .. ".Y", "UDim", "Y")
                infoOf[ys].props.Scale, infoOf[ys].props.Offset = nums[3], nums[4]
                infoOf[p].props.X, infoOf[p].props.Y = xs, ys
                infoOf[p].props.Width, infoOf[p].props.Height = xs, ys
                return p
        end
        if kind == "v" then
                local p = exprP(text, "Vector2", "vector")
                infoOf[p].props.X, infoOf[p].props.Y = nums[1], nums[2]
                infoOf[p].props.Magnitude = math.sqrt(nums[1] * nums[1] + nums[2] * nums[2])
                return p
        end
        if kind == "r" then
                local p = exprP(text, "Rect", "rect")
                local mn = exprP(text .. ".Min", "Vector2", "Min")
                infoOf[mn].props.X, infoOf[mn].props.Y = nums[1], nums[2]
                local mx = exprP(text .. ".Max", "Vector2", "Max")
                infoOf[mx].props.X, infoOf[mx].props.Y = nums[3], nums[4]
                infoOf[p].props.Min, infoOf[p].props.Max = mn, mx
                infoOf[p].props.Width, infoOf[p].props.Height = nums[3] - nums[1], nums[4] - nums[2]
                return p
        end
        return nil
end

local function callP(text, hint, tname, force)
        if cfg.__superz_calls then
                local n = #cfg.__superz_calls
                cfg.__superz_calls[n + 1] = text
                if n >= 400 then table.remove(cfg.__superz_calls, 1) end
        end
        local p = newP({ kind = "call", tname = tname or "Instance", hint = hint })
        local st = emit({ call = text, res = p })
        if cfg.audit ~= false then
                real.pcall(function()
                        real.audit("call_result", { callee = text, result = real.auditValue(p), outcome = "simulated_proxy" })
                end)
        end
        infoOf[p].stmt = st
        if force then infoOf[p].forceVar = true end
        return p
end

local funcs = {}
local frec = {}
local nextFid = 0
local captureDepth = 0
local paramCounter = {}

local function paramName(base)
        paramCounter[base] = (paramCounter[base] or 0) + 1
        local n = paramCounter[base]
        return n == 1 and base or (base .. n)
end

local popTo

local lastThread = nil

local function runInBlock(block, fn, ...)
        block.isRoot = true
        real.insert(traceStack, block)
        local level = #traceStack
        captureDepth += 1
        local th = real.type(fn) == "thread" and fn or coroutine.create(fn)
        lastThread = th
        local res = table.pack(coroutine.resume(th, ...))
        if res[1] and res[2] == abort and coroutine.status(th) == "suspended" then res = { false, abort, n = 2 } end
        captureDepth -= 1
        popTo(level - 1)
        if not res[1] then
                local err = res[2]
                if err == abort then
                        real.insert(block.lines, { text = "-- [envlog] trace budget ran out here: " .. real.tostring(abortReason) })
                        real.error(abort, 0)
                elseif err == tamper then
                        if cfg.debug_tamper then real.print("[tamper-in-block]", debug.traceback()) end
                        real.insert(block.lines, { text = "-- [envlog] Luraph integrity-check thread (anti-tamper) suppressed here" })
                elseif err ~= loopMark then
                        real.insert(block.lines, { text = "-- [envlog] error: " .. real.gsub(real.tostring(err), "\n", " ") })
                        real.pcall(real.audit, "error", { context = "callback", message = real.gsub(real.tostring(err), "\n", " ") })
                end
        end
        return res
end

local deferred = {}
local handlers = {}
function captureFunction(fn, names, args, defer)
        local fid = funcs[fn]
        if fid and not defer then return "\3" .. fid .. "\4" end
        nextFid += 1
        fid = nextFid
        funcs[fn] = fid
        local rec = { params = {}, block = { lines = {}, waits = {} } }
        frec[fid] = rec
        if captureDepth >= maxDepth then
                real.insert(rec.block.lines, { text = "-- [envlog] nesting too deep" })
                return "\3" .. fid .. "\4"
        end
        local callArgs = {}
        if args then
                callArgs = args
                rec.params = { "..." }
        else
                names = names or { "...", "..." }
                local vararg = names[1] == "..."
                for i, nm in names do
                        local pn = vararg and paramName("arg") or paramName(nm)
                        rec.params[i] = pn
                        callArgs[i] = newP({ kind = "name", gen = true, name = pn, tname = "Instance" })
                end
        end
        if defer == "handler" then
                real.insert(handlers, { rec = rec, fn = fn, args = callArgs, n = args and args.n or #callArgs })
                return "\3" .. fid .. "\4"
        end
        if defer then
                local th = coroutine.create(fn)
                lastThread = th
                real.insert(deferred, { rec = rec, thread = th, args = callArgs, n = args and args.n or #callArgs, due = defer })
                return "\3" .. fid .. "\4"
        end
        local tryAlt = cfg._cbtry and not args
        cfg._cbtry = nil
        local res = runInBlock(rec.block, fn, real.unpack(callArgs, 1, args and args.n or #callArgs))
        if tryAlt and res[1] and #callArgs >= 1 then
                local alt = { lines = {}, waits = {} }
                local r2 = runInBlock(alt, fn, false, real.unpack(callArgs, 2, #callArgs))
                local clean = r2[1]
                for _, s in alt.lines do
                        if s.text and real.find(s.text, "-- [envlog]", 1, true) then clean = false end
                end
                if clean then
                        rec.alt = alt
                        local pn = "state"
                        infoOf[callArgs[1]].name = pn
                        rec.params[1] = pn
                end
        end
        return "\3" .. fid .. "\4"
end

local function runHandlers()
        deferred.running = true
        local i = 1
        while i <= #handlers do
                local h = handlers[i]
                i += 1
                popTo(1)
                local ok, err = real.pcall(runInBlock, h.rec.block, h.fn, real.unpack(h.args, 1, h.n))
                if not ok and err == abort then return end
        end
end

local function runDeferred()
        deferred.running = true
        while #deferred > 0 do
                table.sort(deferred, function(a, b) return a.due < b.due end)
                local d = real.remove(deferred, 1)
                if coroutine.status(d.thread) == "suspended" then
                        local ok, err = real.pcall(runInBlock, d.rec.block, d.thread, real.unpack(d.args, 1, d.n))
                        if not ok and err == abort then return end
                else
                        real.insert(d.rec.block.lines, { text = "-- [envlog] cancelled before it ran" })
                end
        end
end

function popTo(level)
        while #traceStack > level do
                local b = traceStack[#traceStack]
                traceStack[#traceStack] = nil
                if b.onClose then b.onClose() end
        end
end

local function iterProxy(p, how)
        local state = 0
        local kp, vp
        return function()
                state += 1
                if state == 1 then
                        local b = { lines = {}, waits = {} }
                        kp = newP({ kind = "name", gen = true, name = paramName(how == "ipairs" and "i" or "k"), tname = "number" })
                        vp = newP({ kind = "name", gen = true, name = paramName("v"), tname = "Instance" })
                        local header = "for " .. tok(kp) .. ", " .. tok(vp) .. " in " ..
                                (how and (how .. "(" .. tok(p) .. ")") or tok(p)) .. " do"
                        emit({ header = header, block = b })
                        real.insert(traceStack, b)
                        b.level = #traceStack
                        return kp, vp
                end
                for i = #traceStack, 1, -1 do
                        if traceStack[i].level == i and traceStack[i].header == nil then
                        end
                end
                popTo(#traceStack - 1)
                return nil
        end
end

local function normalize(block, from, to, baseId, baseFid)
        local parts = {}
        for i = from, to do
                local s = block.lines[i]
                local text = s.text or s.call or s.header or ""
                text = real.gsub(text, "\1(%d+)\2", function(id)
                        id = real.tonumber(id)
                        return id >= baseId and ("\1r" .. (id - baseId) .. "\2") or nil
                end)
                text = real.gsub(text, "\3(%d+)\4", function(id)
                        id = real.tonumber(id)
                        return id >= baseFid and ("\3r" .. (id - baseFid) .. "\4") or nil
                end)
                parts[#parts + 1] = text
        end
        return real.concat(parts, "\n")
end

local function onWait()
        local b = curBlock()
        local w = b.waits
        real.insert(w, { line = #b.lines, id = nextId, fid = nextFid })
        local n = #w
        if n >= 3 then
                local a, m, c = w[n - 2], w[n - 1], w[n]
                if c.line - m.line == m.line - a.line then
                        local s1 = normalize(b, a.line + 1, m.line, a.id, a.fid)
                        local s2 = normalize(b, m.line + 1, c.line, m.id, m.fid)
                        if s1 == s2 then
                                for _ = m.line + 1, c.line do
                                        real.remove(b.lines)
                                end
                                real.insert(b.lines, { text = "-- [envlog] the statements above repeat forever (loop)" })
                                b.stopped = 0
                                real.error(loopMark, 0)
                        end
                end
        end
        local root, rootLevel = nil, 1
        for i = #traceStack, 1, -1 do
                if traceStack[i].isRoot or i == 1 then root, rootLevel = traceStack[i], i; break end
        end
        root.tape = root.tape or {}
        root.marks = root.marks or {}
        local marks = root.marks
        real.insert(marks, { pos = #root.tape, id = nextId, fid = nextFid, depth = #traceStack, block = b })
        local nm = #marks
        if nm >= 3 then
                local m1, m2, m3 = marks[nm - 2], marks[nm - 1], marks[nm]
                local k = m2.pos - m1.pos
                if cfg.debug_loops then real.print("[loop marks]", m1.pos, m2.pos, m3.pos, m1.depth, m2.depth, m3.depth) end
                if k > 0 and m3.pos - m2.pos == k and m3.depth > m2.depth then
                        local function seg(from, to, baseId, baseFid)
                                local order, n = {}, 0
                                local function path(q, d)
                                        local qi = q and infoOf[q]
                                        if not qi or d > 12 then return "?" end
                                        if qi.kind == "name" and not qi.gen then return qi.name or "?" end
                                        if qi.kind == "index" and qi.parent then return path(qi.parent, d + 1) .. "." .. real.tostring(qi.key) end
                                        if not order[q] then n += 1; order[q] = n end
                                        return "#" .. order[q]
                                end
                                local parts = {}
                                for i = from, to do
                                        local st = root.tape[i].stmt
                                        local text = st.text or st.call or st.header or ""
                                        if st.res and isP(st.res) then text = text .. " ->" .. path(st.res, 0) end
                                        text = real.gsub(text, "\1(%d+)\2", function(id)
                                                return "\1" .. path(byId[real.tonumber(id)], 0) .. "\2"
                                        end)
                                        text = real.gsub(text, "\3(%d+)\4", function(id)
                                                id = real.tonumber(id)
                                                return id >= baseFid and ("\3r" .. (id - baseFid) .. "\4") or nil
                                        end)
                                        parts[#parts + 1] = text
                                end
                                return real.concat(parts, "\n")
                        end
                        local sA, sB = seg(m1.pos + 1, m2.pos, m1.id, m1.fid), seg(m2.pos + 1, m3.pos, m2.id, m2.fid)
                        if cfg.debug_loops and sA ~= sB then real.print("[loop A]\n" .. sA .. "\n[loop B]\n" .. sB) end
                        if sA == sB then
                                for i = m3.pos, m2.pos + 1, -1 do
                                        local e = root.tape[i]
                                        if e.block.lines[#e.block.lines] == e.stmt then real.remove(e.block.lines) end
                                        root.tape[i] = nil
                                end
                                popTo(m1.depth)
                                local home = curBlock()
                                local w = root.tape[m2.pos]
                                if w and w.block ~= home and w.block.lines[#w.block.lines] == w.stmt then
                                        real.remove(w.block.lines)
                                        real.insert(home.lines, w.stmt)
                                end
                                real.insert(home.lines, { text = "-- [envlog] the statements above repeat forever (loop)" })
                                home.stopped = 0
                                real.error(loopMark, 0)
                        end
                end
        end
        if n > maxWaits then
                real.insert(b.lines, { text = "-- [envlog] stopped after " .. maxWaits .. " waits" })
                b.stopped = 0
                real.error(loopMark, 0)
        end
end

local datatypes = {
        Vector3 = 1, Vector2 = 1, Vector3int16 = 1, Vector2int16 = 1, CFrame = 1, Color3 = 1,
        UDim = 1, UDim2 = 1, BrickColor = 1, TweenInfo = 1, NumberRange = 1, NumberSequence = 1,
        NumberSequenceKeypoint = 1, ColorSequence = 1, ColorSequenceKeypoint = 1, Ray = 1,
        Rect = 1, Region3 = 1, Region3int16 = 1, PhysicalProperties = 1, Font = 1,
        DateTime = 1, Axes = 1, Faces = 1, PathWaypoint = 1, SharedTable = 1, OverlapParams = 1,
        RaycastParams = 1, CatalogSearchParams = 1, DockWidgetPluginGuiInfo = 1, Path2DControlPoint = 1,
        Content = 1, SecurityCapabilities = 1, FloatCurveKey = 1, RotationCurveKey = 1, ValueCurveKey = 1,
        CFrameCurveKey = 1, UniqueId = 1,
}

local signalParams = {
        PlayerAdded = { "player" }, PlayerRemoving = { "player" },
        CharacterAdded = { "character" }, CharacterRemoving = { "character" }, CharacterAppearanceLoaded = { "character" },
        Touched = { "hit" }, TouchEnded = { "hit" },
        InputBegan = { "input", "gameProcessed" }, InputEnded = { "input", "gameProcessed" },
        InputChanged = { "input", "gameProcessed" },
        Heartbeat = { "deltaTime" }, RenderStepped = { "deltaTime" }, PreSimulation = { "deltaTime" },
        PostSimulation = { "deltaTime" }, PreRender = { "deltaTime" }, Stepped = { "time", "deltaTime" },
        ChildAdded = { "child" }, ChildRemoved = { "child" },
        DescendantAdded = { "descendant" }, DescendantRemoving = { "descendant" },
        Changed = { "value" }, HealthChanged = { "health" }, Chatted = { "message" },
        FocusLost = { "enterPressed", "inputObject" }, Triggered = { "player" },
        PromptTriggered = { "prompt", "player" }, PromptButtonHoldBegan = { "prompt", "player" },
        Idled = { "idleTime" }, MouseButton1Click = {}, MouseButton1Down = { "x", "y" },
        Activated = { "inputObject", "clickCount" }, Died = {}, Event = { "..." },
        OnClientEvent = { "..." }, OnClientInvoke = { "..." }, OnInvoke = { "..." },
        AncestryChanged = { "child", "parent" }, AttributeChanged = { "attribute" },
        StateChanged = { "old", "new" }, MoveToFinished = { "reached" }, Completed = { "playbackState" },
}

local classHint = {
        GetChildren = "children", GetDescendants = "descendants", GetPlayers = "players",
        GetTouchingParts = "parts", GetPartsInPart = "parts", GetPartBoundsInBox = "parts",
        GetPartBoundsInRadius = "parts", GetTagged = "tagged", GetAttributes = "attributes",
        GetPlayingAnimationTracks = "tracks", GetConnectedParts = "parts", GetJoints = "joints",
        GetChildrenOfClass = "children",
}
for k, v in {
        JSONEncode = "json", JSONDecode = "data", HttpGet = "response", HttpGetAsync = "response",
        GetAsync = "response", PostAsync = "response", RequestAsync = "response",
        Inverse = "inverse", ToWorldSpace = "cframe", ToObjectSpace = "cframe",
        Raycast = "raycastResult", GetMouse = "mouse", LoadAnimation = "track",
        InvokeServer = "response", Clone = "clone",
        GetPropertyChangedSignal = "changedSignal", GetAttribute = "attribute",
        GenerateGUID = "guid", UrlEncode = "encoded", Notify = "notification",
} do
        classHint[k] = v
end
for _, n in { "Window", "Tab", "Section", "Toggle", "Button", "Slider", "Dropdown", "Input",
        "Keybind", "Colorpicker", "Paragraph", "Dialog", "Label", "Textbox", "Divider", "Popup",
        "Code", "Group", "Page", "Category", "Checkbox", "ColorPicker", "TextBox" } do
        classHint[n] = n
end

local serviceCache = {}
local gameProxy
local workspaceProxy
local urls = {}
local remotes = {}

local function methodName(info)
        if info.kind == "index" and real.type(info.key) == "string" then return info.key end
        return nil
end

local function remember(list, v)
        if not list[v] then
                list[v] = true
                real.insert(list, v)
        end
end

local function instName(p)
        local v = infoOf[p].props.Name
        if real.type(v) == "string" then return v end
        return infoOf[p].className or "Instance"
end
local function kidsOf(p)
        local info = infoOf[p]
        info.kids = info.kids or {}
        return info.kids
end
local function setParent(child, parent)
        local ci = infoOf[child]
        local old = ci.props.Parent
        if isP(old) then
                local list = kidsOf(old)
                for i = #list, 1, -1 do
                        if list[i] == child then real.remove(list, i) end
                end
        end
        if isP(parent) then real.insert(kidsOf(parent), child) end
        ci.props.Parent = parent
        local rc = realValues[child]
        if rc ~= nil and real.typeof(rc) == "Instance" then
                local rp = isP(parent) and realValues[parent] or nil
                real.pcall(function() rc.Parent = (real.typeof(rp) == "Instance") and rp or nil end)
        end
end
local function findKid(p, name, recursive)
        for _, c in kidsOf(p) do
                if instName(c) == name then return c end
        end
        if recursive then
                for _, c in kidsOf(p) do
                        local r = findKid(c, name, true)
                        if r then return r end
                end
        end
        return nil
end
local function descendants(p, out)
        for _, c in kidsOf(p) do
                real.insert(out, c)
                descendants(c, out)
        end
        return out
end
local function destroyInst(p)
        local info = infoOf[p]
        if info.destroyed then return end
        for _, c in table.clone(kidsOf(p)) do destroyInst(c) end
        if isP(info.props.Parent) then setParent(p, nil) end
        info.props.Parent = nil
        info.destroyed = true
        local r = realValues[p]
        if r ~= nil and real.typeof(r) == "Instance" then real.pcall(r.Destroy, r) end
end
function hub.isClassA(cls, want)
        local c = cls
        local guard = 0
        while c and guard < 32 do
                guard += 1
                if c == want then return true end
                c = api.classes[c] and api.classes[c].super
        end
        return want == "Instance" or want == "Object"
end
function hub.cloneInst(root, text)
        local ri = infoOf[root]
        if not ri or ri.props.Archivable == false then return nil end
        local cmap = {}
        local function rec(src, newPar)
                local si = infoOf[src]
                local cp
                if src == root then
                        cp = callP(text, "clone")
                else
                        cp = newP({ kind = "expr", text = tok(newPar) .. ":FindFirstChild(" .. quote(real.tostring(si.props.Name or si.className or "Child")) .. ")", tname = "Instance", hint = si.className or "clone" })
                end
                cmap[src] = cp
                local ci = infoOf[cp]
                ci.created = true
                ci.className = si.className
                ci.kids = {}
                ci.modelScale = si.modelScale
                if si.attrs then ci.attrs = table.clone(si.attrs) end
                for k, v in real.pairs(si.props) do
                        if k ~= "Parent" then ci.props[k] = v end
                end
                if newPar then setParent(cp, newPar) end
                for _, child in kidsOf(src) do
                        local chi = infoOf[child]
                        if chi and chi.props.Archivable ~= false then
                                rec(child, cp)
                        end
                end
                return cp
        end
        local top = rec(root, nil)
        for _, cp in real.pairs(cmap) do
                local ci = infoOf[cp]
                for k, v in real.pairs(ci.props) do
                        if cmap[v] ~= nil then ci.props[k] = cmap[v] end
                end
        end
        return top
end
function hub.attParentWorldCF(p)
        local par = infoOf[p] and infoOf[p].props.Parent
        if isP(par) then
                local pi = infoOf[par]
                if pi.className == "Attachment" or pi.className == "Bone" then
                        return par.WorldCFrame
                end
                if pi.props.CFrame then return pi.props.CFrame end
        end
        return scriptEnv.CFrame.identity
end
function hub.modelBounds(self)
        local f32 = hub.p2d.f32
        local minX, minY, minZ = math.huge, math.huge, math.huge
        local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
        local found = false
        for _, d in descendants(self, {}) do
                local di = infoOf[d]
                if di and hub.isClassA(di.className, "BasePart") then
                        found = true
                        local cf = di.props.CFrame or scriptEnv.CFrame.identity
                        local sz = di.props.Size or vector.create(4, 1.2, 2)
                        local hx, hy, hz = sz.X * 0.5, sz.Y * 0.5, sz.Z * 0.5
                        for sx = -1, 1, 2 do
                                for sy = -1, 1, 2 do
                                        for szs = -1, 1, 2 do
                                                local wp = cf * vector.create(sx * hx, sy * hy, szs * hz)
                                                if wp.X < minX then minX = wp.X end
                                                if wp.Y < minY then minY = wp.Y end
                                                if wp.Z < minZ then minZ = wp.Z end
                                                if wp.X > maxX then maxX = wp.X end
                                                if wp.Y > maxY then maxY = wp.Y end
                                                if wp.Z > maxZ then maxZ = wp.Z end
                                        end
                                end
                        end
                end
        end
        if not found then return scriptEnv.CFrame.identity, vector.create(0, 0, 0) end
        local ext = vector.create(f32(maxX - minX), f32(maxY - minY), f32(maxZ - minZ))
        local ctr = vector.create(f32((minX + maxX) * 0.5), f32((minY + maxY) * 0.5), f32((minZ + maxZ) * 0.5))
        local pp = infoOf[self].props.PrimaryPart
        local rot = (isP(pp) and infoOf[pp].props.CFrame and infoOf[pp].props.CFrame.Rotation) or scriptEnv.CFrame.identity
        return rot + ctr, ext
end
function hub.guiScale(p)
        local sc = 1
        local cur = p
        while isP(cur) do
                for _, c in kidsOf(cur) do
                        if infoOf[c] and infoOf[c].className == "UIScale" then
                                sc = sc * (real.tonumber(infoOf[c].props.Scale) or 1)
                        end
                end
                cur = infoOf[cur].props.Parent
        end
        return sc
end
function hub.guiUnscaledSize(p)
        if not isP(p) or not infoOf[p] or infoOf[p].className == "ScreenGui" then return 0, 0 end
        local pw, ph = hub.guiUnscaledSize(infoOf[p].props.Parent)
        local sz = infoOf[p].props.Size
        if isP(sz) and realValues[sz] then
                local r = realValues[sz]
                return r.X.Scale * pw + r.X.Offset, r.Y.Scale * ph + r.Y.Offset
        end
        return 0, 0
end
local runserviceBool = { IsStudio = false, IsServer = false, IsClient = true, IsRunning = true,
        IsRunMode = false, IsEdit = false }

local noNativeMethod = { Clone = 1, Destroy = 1, Remove = 1, GetChildren = 1, GetDescendants = 1,
        FindFirstChild = 1, WaitForChild = 1, FindFirstChildOfClass = 1, FindFirstChildWhichIsA = 1,
        FindFirstAncestor = 1, FindFirstAncestorOfClass = 1, FindFirstAncestorWhichIsA = 1, FindFirstDescendant = 1,
        ClearAllChildren = 1, IsA = 1, Connect = 1, Once = 1, Wait = 1, GetPropertyChangedSignal = 1,
        GetAttributeChangedSignal = 1, IsDescendantOf = 1, IsAncestorOf = 1, GetFullName = 1,
        SetAttribute = 1, GetAttribute = 1, GetAttributes = 1, GetMass = 1, GetPivot = 1, PivotTo = 1,
        GetBoundingBox = 1, GetExtentsSize = 1, GetScale = 1, ScaleTo = 1 }
do
        local f32Buf = buffer.create(4)
        local function f32(x)
                buffer.writef32(f32Buf, 0, x)
                return buffer.readf32(f32Buf, 0)
        end
        local p2dModel = {}
        hub.p2d = p2dModel
        p2dModel.f32 = f32

        local function num(x)
                if real.type(x) == "number" then return x end
                return 0
        end
        function p2dModel.udim2(p)
                if not isP(p) then return nil end
                local inf = infoOf[p]
                local c = inf.ctor
                if c and c.ns == "UDim2" then
                        local a = c.args
                        if c.fn == "new" then
                                if isP(a[1]) or isP(a[2]) then
                                        local x, y = infoOf[a[1]] and infoOf[a[1]].ctor, infoOf[a[2]] and infoOf[a[2]].ctor
                                        return { x and num(x.args[1]) or 0, x and num(x.args[2]) or 0, y and num(y.args[1]) or 0,
                                                y and num(y.args[2]) or 0 }
                                end
                                return { num(a[1]), num(a[2]), num(a[3]), num(a[4]) }
                        elseif c.fn == "fromScale" then
                                return { num(a[1]), 0, num(a[2]), 0 }
                        elseif c.fn == "fromOffset" then
                                return { 0, num(a[1]), 0, num(a[2]) }
                        end
                        return nil
                end
                local propX, propY = inf.props and inf.props.X, inf.props and inf.props.Y
                if isP(propX) and isP(propY) then
                        local xp, yp = infoOf[propX].props, infoOf[propY].props
                        return { num(xp.Scale), num(xp.Offset), num(yp.Scale), num(yp.Offset) }
                end
                return nil
        end
        function p2dModel.frameSize(path)
                local parent = infoOf[path].props and infoOf[path].props.Parent
                if not isP(parent) then return nil end
                local sz = infoOf[parent].props and infoOf[parent].props.Size
                local u = sz and p2dModel.udim2(sz)
                if not u then return nil end
                if u[1] ~= 0 or u[3] ~= 0 then return nil end
                return u[2], u[4]
        end
        local function resolve(u, frameW, frameH)
                return f32(f32(u[1] * frameW) + u[2]), f32(f32(u[3] * frameH) + u[4])
        end
        function p2dModel.segments(cps, frameW, frameH)
                local pts = {}
                for i, cp in real.ipairs(cps) do
                        local c = isP(cp) and infoOf[cp].ctor
                        if not c or c.ns ~= "Path2DControlPoint" then return nil end
                        local zero = { 0, 0, 0, 0 }
                        local pos = c.args.n >= 1 and p2dModel.udim2(c.args[1]) or zero
                        local left = c.args.n >= 2 and p2dModel.udim2(c.args[2]) or zero
                        local right = c.args.n >= 3 and p2dModel.udim2(c.args[3]) or zero
                        if not pos or not left or not right then return nil end
                        local px, py = resolve(pos, frameW, frameH)
                        local lx, ly = resolve(left, frameW, frameH)
                        local rx, ry = resolve(right, frameW, frameH)
                        pts[i] = { px, py, lx, ly, rx, ry }
                end
                local segs = {}
                for i = 1, #pts - 1 do
                        local a, b = pts[i], pts[i + 1]
                        local s = {
                                a[1], a[2],
                                f32(a[1] + a[5]), f32(a[2] + a[6]),
                                f32(b[1] + b[3]), f32(b[2] + b[4]),
                                b[1], b[2],
                        }
                        segs[i] = p2dModel.coeffs(s)
                end
                return segs
        end
        function p2dModel.coeffs(s)
                local n = #s // 2
                local x0, y0 = s[1], s[2]
                local c = { n = n, x0 = x0, y0 = y0 }
                if n == 2 then
                        c.c1x, c.c1y = f32(s[3] - x0), f32(s[4] - y0)
                elseif n == 3 then
                        local x1, y1, x2, y2 = s[3], s[4], s[5], s[6]
                        c.c1x, c.c1y = f32(f32(x1 - x0) * 2), f32(f32(y1 - y0) * 2)
                        c.c2x, c.c2y = f32(f32(x0 - f32(x1 * 2)) + x2), f32(f32(y0 - f32(y1 * 2)) + y2)
                else
                        local x1, y1, x2, y2, x3, y3 = s[3], s[4], s[5], s[6], s[7], s[8]
                        c.c1x, c.c1y = f32(f32(x1 - x0) * 3), f32(f32(y1 - y0) * 3)
                        c.c2x = f32(f32(f32(x0 - f32(x1 * 2)) + x2) * 3)
                        c.c2y = f32(f32(f32(y0 - f32(y1 * 2)) + y2) * 3)
                        c.c3x = f32(f32(f32(x3 - x0) + f32(x1 * 3)) - f32(x2 * 3))
                        c.c3y = f32(f32(f32(y3 - y0) + f32(y1 * 3)) - f32(y2 * 3))
                end
                return c
        end
        function p2dModel.eval(c, u)
                if c.n == 2 then
                        return f32(c.x0 + f32(c.c1x * u)), f32(c.y0 + f32(c.c1y * u))
                elseif c.n == 3 then
                        return f32(c.x0 + f32(f32(c.c1x + f32(c.c2x * u)) * u)), f32(c.y0 + f32(f32(c.c1y + f32(c.c2y * u)) * u))
                end
                local ix, iy = f32(c.c2x + f32(c.c3x * u)), f32(c.c2y + f32(c.c3y * u))
                return f32(c.x0 + f32(f32(c.c1x + f32(ix * u)) * u)), f32(c.y0 + f32(f32(c.c1y + f32(iy * u)) * u))
        end
        function p2dModel.tangent(c, u)
                if c.n == 2 then return c.c1x, c.c1y end
                if c.n == 3 then
                        local k = f32(u * 2)
                        return f32(c.c1x + f32(c.c2x * k)), f32(c.c1y + f32(c.c2y * k))
                end
                local k = f32(3 * u)
                return f32(c.c1x + f32(u * f32(f32(c.c2x * 2) + f32(c.c3x * k)))),
                        f32(c.c1y + f32(u * f32(f32(c.c2y * 2) + f32(c.c3y * k))))
        end
        local function dist(ax, ay, bx, by)
                local dx, dy = f32(bx - ax), f32(by - ay)
                return f32(math.sqrt(f32(f32(dx * dx) + f32(dy * dy))))
        end
        p2dModel.dist = dist
        local tol = f32(1e-5)
        function p2dModel.eval0(c, u)
                if c.n == 2 then
                        return f32(c.c1x * u), f32(c.c1y * u)
                elseif c.n == 3 then
                        return f32(f32(c.c1x + f32(c.c2x * u)) * u), f32(f32(c.c1y + f32(c.c2y * u)) * u)
                end
                local ix, iy = f32(c.c2x + f32(c.c3x * u)), f32(c.c2y + f32(c.c3y * u))
                return f32(f32(c.c1x + f32(ix * u)) * u), f32(f32(c.c1y + f32(iy * u)) * u)
        end
        function p2dModel.seglen(c)
                local function rec(t0, t1, x0, y0, x1, y1, depth)
                        local tm = f32(f32(t0 + t1) * 0.5)
                        local xm, ym = p2dModel.eval0(c, tm)
                        local a = dist(x0, y0, x1, y1)
                        local b = f32(dist(x0, y0, xm, ym) + dist(xm, ym, x1, y1))
                        if depth >= 30 or f32(b - a) < tol then return b end
                        return f32(rec(t0, tm, x0, y0, xm, ym, depth + 1) + rec(tm, t1, xm, ym, x1, y1, depth + 1))
                end
                local x0, y0 = p2dModel.eval0(c, 0)
                local x1, y1 = p2dModel.eval0(c, 1)
                return rec(0, 1, x0, y0, x1, y1, 0)
        end
        local sixth = f32(1 / 6)
        function p2dModel.arcU(c, s)
                local d2x, d2y = f32(c.c2x * 2), f32(c.c2y * 2)
                local d3x, d3y
                if c.n == 4 then d3x, d3y = f32(c.c3x * 3), f32(c.c3y * 3) end
                local function inv(u)
                        local dx, dy
                        if c.n == 3 then
                                dx, dy = f32(c.c1x + f32(d2x * u)), f32(c.c1y + f32(d2y * u))
                        else
                                dx = f32(c.c1x + f32(u * f32(d2x + f32(u * d3x))))
                                dy = f32(c.c1y + f32(u * f32(d2y + f32(u * d3y))))
                        end
                        return math.sqrt(f32(f32(dx * dx) + f32(dy * dy)))
                end
                local h = f32(s / 32)
                local u = 0
                for _ = 1, 32 do
                        local k1 = f32(h / f32(inv(u)))
                        local k2 = f32(h / f32(inv(f32(u + f32(k1 * 0.5)))))
                        local k3 = f32(h / f32(inv(f32(u + f32(k2 * 0.5)))))
                        local k4 = f32(h / f32(inv(f32(u + k3))))
                        u = f32(u + f32(f32(f32(k1 + f32(2 * f32(k2 + k3))) + k4) * sixth))
                end
                return u
        end
        function p2dModel.length(segs)
                local t = 0
                for _, c in real.ipairs(segs) do
                        c.len = c.len or p2dModel.seglen(c)
                        t = f32(t + c.len)
                end
                return t
        end
        function p2dModel.locate(segs, t)
                t = f32(t)
                if t < 0 then t = 0 elseif t > 1 then t = 1 end
                local n = #segs
                local x = f32(t * n)
                local k = math.min(math.floor(x), n - 1)
                return segs[k + 1], f32(x - k)
        end
        function p2dModel.locateArc(segs, t)
                t = f32(t)
                if t < 0 then t = 0 elseif t > 1 then t = 1 end
                local curveLen = p2dModel.length(segs)
                local s = f32(t * curveLen)
                for _, c in real.ipairs(segs) do
                        if s <= c.len then
                                if c.n == 2 then return c, f32(s / c.len) end
                                return c, p2dModel.arcU(c, s)
                        end
                        s = f32(s - c.len)
                end
                return segs[1], 0
        end
        function p2dModel.answer(path, name, t)
                local inf = infoOf[path]
                local segs = inf.p2dSegs
                if not segs then return nil end
                local frameW, frameH = inf.p2dW, inf.p2dH
                if name == "GetLength" then
                        return real.fmt("n:%.17g", p2dModel.length(segs))
                elseif name == "GetBoundingRect" then
                        return "r:0,0,0,0"
                end
                if real.type(t) ~= "number" then return nil end
                local c, u
                if name == "GetPositionOnCurve" or name == "GetTangentOnCurve" then
                        c, u = p2dModel.locate(segs, t)
                elseif name == "GetPositionOnCurveArcLength" or name == "GetTangentOnCurveArcLength" then
                        c, u = p2dModel.locateArc(segs, t)
                end
                if not c then return nil end
                if real.find(name, "Position", 1, true) then
                        local x, y = p2dModel.eval(c, u)
                        return real.fmt("u:%.17g,0,%.17g,0", f32(x / frameW), f32(y / frameH))
                end
                local x, y = p2dModel.tangent(c, u)
                return real.fmt("v:%.17g,%.17g", x, y)
        end
end

local function onCall(p, ...)
        checkBudget()
        local info = infoOf[p]
        if cfg.ptrace then
                local a2 = real.select(2, ...)
                real.print("[call]", info.name or info.hint or info.key, real.select("#", ...), real.type(a2) == "string" and a2 or "")
        end
        local n = real.select("#", ...)
        local first = ...
        local name = methodName(info)
        local isMethod = info.kind == "index" and n >= 1 and first == info.parent and isP(first)
        local calleeText
        local args
        if isMethod then
                calleeText = tok(info.parent) .. ":" .. (isIdent(name) and name or "__call")
                args = table.pack(real.select(2, ...))
        else
                calleeText = tok(p)
                args = table.pack(...)
        end
        local a1 = args[1]

        if cfg.audit ~= false then
                real.pcall(function()
                        local auditArgs = {}
                        local redact = real.auditRedactKey(name)
                        for i = 1, args.n do
                                auditArgs[i] = redact and "[REDACTED]" or real.auditValue(args[i])
                        end
                        real.audit("call", { callee = calleeText, args = auditArgs, source = "proxy" })
                end)
        end

        if cfg.falsy and real.type(name) == "string" and real.find("," .. cfg.falsy .. ",", "," .. name .. ",", 1, true) then
                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ") --> false" })
                return false
        end

        if info.ns and datatypes[info.ns] then
                local dp = exprP(calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")", info.ns)
                infoOf[dp].ctor = { ns = info.ns, fn = name, args = args }
                return dp
        end

        if name == "Connect" or name == "Once" or name == "ConnectParallel" then
                local sig = infoOf[info.parent]
                local sigName = sig and methodName(sig)
                if cfg.input_text ~= nil then
                        for _, bp in real.pairs(byId) do
                                local bi = infoOf[bp]
                                if bi.created and bi.className == "TextBox" and bi.props.Text ~= cfg.input_text then
                                        bi.props.Text = cfg.input_text
                                        local rb = realValues[bp]
                                        if rb ~= nil then real.pcall(function() rb.Text = cfg.input_text end) end
                                end
                        end
                end
                local fnTok = real.type(a1) == "function" and captureFunction(a1, signalParams[sigName] or { "..." }, nil, "handler") or fmt(a1)
                local conn = callP(calleeText .. "(" .. fnTok .. ")", "connection", "RBXScriptConnection")
                infoOf[conn].props.Connected = true
                return conn
        end
        if name == "Wait" and isMethod then
                if not deferred.running and deferred.runner and coroutine.running() ~= deferred.runner and coroutine.isyieldable() then
                        coroutine.yield()
                end
                local sp = signalParams[methodName(infoOf[info.parent])]
                if sp and (sp[1] == "deltaTime" or sp[2] == "deltaTime") then
                        emit({ text = calleeText .. "()" })
                        onWait()
                        if sp[2] == "deltaTime" then return 1, 1 / 60 end
                        return 1 / 60
                end
                callP(calleeText .. "()", "result")
                local r = byId[nextId]
                onWait()
                return r
        end

        if name == "GetService" or name == "FindService" then
                local svc = a1
                if real.type(svc) == "string" and serviceCache[svc] then
                        return serviceCache[svc]
                end
                if real.type(svc) == "string" and not api.classes[svc] then
                        if name == "FindService" then return nil end
                        real.error(real.fmt("'%s' is not a valid Service name", svc), 0)
                end
                local r = callP(calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")", real.type(svc) == "string" and svc or "service", "Instance", true)
                if real.type(svc) == "string" and api.classes[svc] then
                        infoOf[r].className = svc
                        infoOf[r].props.Name = svc
                        infoOf[r].props.ClassName = svc
                        infoOf[r].props.Parent = gameProxy
                end
                if real.type(svc) == "string" then serviceCache[svc] = r end
                return r
        end

        if name == "GetSecret" and isMethod then
                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ") -- errors" })
                real.error("Can't find secret with given key", 0)
        end

        if (name == "SetTeleportSetting" or name == "GetTeleportSetting") and isMethod then
                local store = infoOf[info.parent].tpSettings or {}
                infoOf[info.parent].tpSettings = store
                if name == "SetTeleportSetting" then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        if args[1] ~= nil then store[args[1]] = args[2] end
                        return
                end
                return args[1] ~= nil and store[args[1]] or nil
        end

        local self = isMethod and info.parent or nil
        local sinfo = self and infoOf[self]
        if sinfo and sinfo.tname == "RBXScriptConnection" and name == "Disconnect" then
                emit({ text = calleeText .. "()" })
                sinfo.props.Connected = false
                return
        end
        if sinfo and sinfo.tname == "Enum" and sinfo.enumName then
                local e = api.enums[sinfo.enumName]
                if name == "GetEnumItems" then
                        local list = {}
                        for _, it in e.items do real.insert(list, enumItem(sinfo.enumName, it.Name)) end
                        return list
                elseif name == "FromName" then
                        return (real.type(a1) == "string" and e.byName[a1]) and enumItem(sinfo.enumName, a1) or nil
                elseif name == "FromValue" then
                        local it = e.byValue[a1]
                        return it and enumItem(sinfo.enumName, it.Name) or nil
                end
        end
        if sinfo and sinfo.tname == "EnumItem" and name == "IsA" then
                return a1 == sinfo.enumName
        end
        if self and runserviceBool[name] ~= nil then
                return runserviceBool[name]
        end
        if sinfo and (sinfo.created or sinfo.kids) then
                if name == "GetChildren" then
                        emit({ text = calleeText .. "()" })
                        return table.clone(kidsOf(self))
                elseif name == "GetDescendants" then
                        emit({ text = calleeText .. "()" })
                        return descendants(self, {})
                elseif (name == "FindFirstChild" or name == "WaitForChild") and real.type(a1) == "string" then
                        local found = findKid(self, a1, name == "FindFirstChild" and args[2] == true)
                        if found or sinfo.created then
                                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                                return found
                        end
                elseif name == "Destroy" then
                        emit({ text = calleeText .. "()" })
                        destroyInst(self)
                        return
                elseif name == "ClearAllChildren" then
                        emit({ text = calleeText .. "()" })
                        for _, c in table.clone(kidsOf(self)) do destroyInst(c) end
                        return
                elseif name == "IsA" and sinfo.created then
                        return hub.isClassA(sinfo.className, a1)
                elseif name == "IsDescendantOf" and sinfo.created and isP(a1) and infoOf[a1].created then
                        local cur = sinfo.props.Parent
                        while isP(cur) do
                                if cur == a1 then return true end
                                cur = infoOf[cur].props.Parent
                        end
                        return false
                elseif name == "IsAncestorOf" and sinfo.created and isP(a1) and infoOf[a1].created then
                        local cur = infoOf[a1].props.Parent
                        while isP(cur) do
                                if cur == self then return true end
                                cur = infoOf[cur].props.Parent
                        end
                        return false
                elseif name == "SetAttribute" and sinfo.created and real.type(a1) == "string" then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        sinfo.attrs = sinfo.attrs or {}
                        sinfo.attrs[a1] = args[2]
                        return
                elseif name == "GetAttribute" and sinfo.created and real.type(a1) == "string" then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        return sinfo.attrs and sinfo.attrs[a1] or nil
                elseif name == "GetAttributes" and sinfo.created then
                        emit({ text = calleeText .. "()" })
                        return sinfo.attrs and table.clone(sinfo.attrs) or {}
                elseif name == "Clone" and sinfo.created then
                        return hub.cloneInst(self, calleeText .. "()")
                elseif name == "GetMass" and sinfo.created and hub.isClassA(sinfo.className, "BasePart") then
                        emit({ text = calleeText .. "()" })
                        return self.Mass
                elseif name == "GetPivot" and sinfo.created and (hub.isClassA(sinfo.className, "BasePart") or sinfo.className == "Model") then
                        emit({ text = calleeText .. "()" })
                        if sinfo.className == "Model" then
                                local pp = sinfo.props.PrimaryPart
                                if isP(pp) then
                                        return (infoOf[pp].props.CFrame or scriptEnv.CFrame.identity) * (infoOf[pp].props.PivotOffset or scriptEnv.CFrame.identity)
                                end
                                local bcf = hub.modelBounds(self)
                                return bcf
                        end
                        return (sinfo.props.CFrame or scriptEnv.CFrame.identity) * (sinfo.props.PivotOffset or scriptEnv.CFrame.identity)
                elseif name == "PivotTo" and sinfo.created and isP(a1) and (hub.isClassA(sinfo.className, "BasePart") or sinfo.className == "Model") then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        if sinfo.className == "Model" then
                                local pp = sinfo.props.PrimaryPart
                                local oldPivot
                                if isP(pp) then
                                        oldPivot = (infoOf[pp].props.CFrame or scriptEnv.CFrame.identity) * (infoOf[pp].props.PivotOffset or scriptEnv.CFrame.identity)
                                else
                                        oldPivot = hub.modelBounds(self)
                                end
                                local delta = a1 * oldPivot:Inverse()
                                for _, d in descendants(self, {}) do
                                        local di = infoOf[d]
                                        if di and hub.isClassA(di.className, "BasePart") then
                                                local ncf = delta * (di.props.CFrame or scriptEnv.CFrame.identity)
                                                di.props.CFrame = ncf
                                                di.props.Position = ncf.Position
                                        end
                                end
                                return
                        end
                        local po = sinfo.props.PivotOffset or scriptEnv.CFrame.identity
                        local ncf = a1 * po:Inverse()
                        sinfo.props.CFrame = ncf
                        sinfo.props.Position = ncf.Position
                        return
                elseif name == "GetBoundingBox" and sinfo.created and sinfo.className == "Model" then
                        emit({ text = calleeText .. "()" })
                        return hub.modelBounds(self)
                elseif name == "GetExtentsSize" and sinfo.created and sinfo.className == "Model" then
                        emit({ text = calleeText .. "()" })
                        local _, ext = hub.modelBounds(self)
                        return ext
                elseif name == "GetScale" and sinfo.created and sinfo.className == "Model" then
                        emit({ text = calleeText .. "()" })
                        return sinfo.modelScale or 1
                elseif name == "ScaleTo" and sinfo.created and sinfo.className == "Model" and real.type(a1) == "number" then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        local f32 = hub.p2d.f32
                        local oldScale = sinfo.modelScale or 1
                        local newScale = f32(a1)
                        local ratio = f32(newScale / oldScale)
                        local pp = sinfo.props.PrimaryPart
                        local pivotCF
                        if isP(pp) then
                                pivotCF = (infoOf[pp].props.CFrame or scriptEnv.CFrame.identity) * (infoOf[pp].props.PivotOffset or scriptEnv.CFrame.identity)
                        else
                                pivotCF = hub.modelBounds(self)
                        end
                        local ppos = pivotCF.Position
                        for _, d in descendants(self, {}) do
                                local di = infoOf[d]
                                if di and hub.isClassA(di.className, "BasePart") then
                                        local sz = di.props.Size or vector.create(4, 1.2, 2)
                                        di.props.Size = sz * ratio
                                        local cf = di.props.CFrame or scriptEnv.CFrame.identity
                                        local np = ppos + (cf.Position - ppos) * ratio
                                        di.props.CFrame = (cf - cf.Position) + np
                                        di.props.Position = np
                                end
                        end
                        sinfo.modelScale = newScale
                        return
                end
        end
        if sinfo and sinfo.className == "TweenService" and name == "GetValue" then
                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                local f32 = hub.p2d.f32
                local x = f32(real.tonumber(a1) or 0)
                if x <= 0 then return 0 end
                if x >= 1 then return 1 end
                local es = isP(args[2]) and infoOf[args[2]].props.Name or args[2]
                local ed = isP(args[3]) and infoOf[args[3]].props.Name or args[3]
                local function base(t)
                        if es == "Linear" then return t end
                        if es == "Cubic" then return f32(f32(t * t) * t) end
                        if es == "Quart" then local t2 = f32(t * t) return f32(t2 * t2) end
                        if es == "Quint" then local t2 = f32(t * t) return f32(f32(t2 * t2) * t) end
                        return f32(t * t)
                end
                if ed == "In" then return base(x) end
                if ed == "InOut" then
                        if x < 0.5 then return f32(0.5 * base(f32(x * 2))) end
                        return f32(1 - f32(0.5 * base(f32(2 - f32(x * 2)))))
                end
                return f32(1 - base(f32(1 - x)))
        end
        if sinfo and sinfo.className == "TextService" and name == "GetTextSize" then
                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                local txt = real.tostring(a1 or "")
                local fs = real.tonumber(args[2]) or 14
                local fnm = isP(args[3]) and infoOf[args[3]].props.Name or real.tostring(args[3] or "Code")
                local fsz = args[4]
                local maxW = (isP(fsz) and realValues[fsz] and realValues[fsz].X) or 4096
                local mono = (fnm == "Code" or fnm == "Arcade" or fnm == "RobotoMono")
                local baseW = math.max(1, math.floor(fs * 0.6 + 0.5))
                local function charW(ch)
                        if mono then return baseW end
                        if ch == "i" or ch == "l" or ch == "I" or ch == "." or ch == " " then return math.max(1, math.floor(fs * 0.3)) end
                        if ch == "W" or ch == "M" then return math.max(baseW + 2, math.floor(fs * 0.85)) end
                        return baseW
                end
                local function strW(s)
                        local w = 0
                        for i = 1, #s do w += charW(real.sub(s, i, i)) end
                        return w
                end
                local maxLineW, numLines = 0, 0
                for line in string.gmatch(txt .. "\n", "([^\n]*)\n") do
                        local curW = 0
                        local firstWord = true
                        for word in string.gmatch(line, "%S+") do
                                local ww = strW(word)
                                local spw = firstWord and 0 or charW(" ")
                                if not firstWord and curW + spw + ww > maxW then
                                        if curW > maxLineW then maxLineW = curW end
                                        numLines += 1
                                        curW = ww
                                else
                                        curW += spw + ww
                                end
                                firstWord = false
                        end
                        if curW > maxLineW then maxLineW = curW end
                        numLines += 1
                end
                if numLines == 0 then numLines = 1 end
                return scriptEnv.Vector2.new(maxLineW, numLines * fs)
        end
        if name == "IsA" then
                local cls = sinfo and sinfo.className
                if real.type(cls) == "string" and real.type(a1) == "string" and api.classes[cls] then
                        return hub.isClassA(cls, a1)
                end
                return true
        end
        if name == "IsDescendantOf" or name == "IsAncestorOf" then
                if isP(a1) and isP(self) then
                        if a1 == self then return false end
                        if name == "IsDescendantOf" and self == gameProxy then return false end
                        if name == "IsAncestorOf" and a1 == gameProxy then return false end
                end
                return true
        end
        if name == "GetLogHistory" then
                return {}
        end

        if cfg.real_json and (name == "JSONEncode" or name == "JSONDecode") then
                local ok, out
                if name == "JSONEncode" then
                        ok, out = real.pcall(real.json.encode, args[1])
                else
                        ok, out = real.pcall(real.json.decode, a1)
                end
                if ok then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        return out
                end
        end
        if real.type(a1) == "string"
                and (name == "HttpGet" or name == "HttpGetAsync" or name == "GetAsync" or name == "RequestAsync") then
                local liveTries = 0
                while true do
                        local list = urls.__lrm_plant
                        if real.type(list) == "table" then
                                local served
                                for i = 1, #list do
                                        local plant = list[i]
                                        if real.type(plant) == "table" and real.type(plant.body) == "string" then
                                                local u = plant.url
                                                if u == nil or (real.type(u) == "string" and real.sub(a1, 1, #u) == u) then
                                                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                                                        comment(calleeText .. " -> canned via urls[" .. i .. "] ("
                                                                .. real.tostring(#plant.body) .. " bytes, .." .. real.sub(a1, -10) .. ")")
                                                        served = true
                                                        if name == "HttpGet" then return plant.body end
                                                        return { Success = true, StatusCode = 200,
                                                                Headers = plant.headers or {}, Body = plant.body }
                                                end
                                        end
                                end
                                _ = served
                        end
                        if cfg.http_map then
                                local hit = cfg.http_map["GET " .. a1] or cfg.http_map[a1]
                                if hit == nil then
                                        for k, v in real.next, cfg.http_map do
                                                if real.type(k) == "string" and #k > 1 and real.sub(k, #k, #k) == "*" then
                                                        local pfx = real.sub(k, 1, #k - 1)
                                                        if real.sub(a1, 1, #pfx) == pfx or ("GET " .. a1):sub(1, #pfx) == pfx then
                                                                hit = v
                                                                break
                                                        end
                                                end
                                        end
                                end
                                if hit then
                                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                                        comment(calleeText .. " -> canned " .. real.tostring(hit.status or 200)
                                                .. " (" .. real.tostring(#real.tostring(hit.body or "")) .. " bytes)")
                                        if name == "HttpGet" then return hit.body end
                                        return { Success = true, StatusCode = hit.status or 200,
                                                Headers = hit.headers or {}, Body = hit.body }
                                end
                        end
                        if real.find(a1, "luarmor", 1, true)
                                and cfg.serve and servePad and coroutine.isyieldable()
                                and liveTries < 4 then
                                liveTries += 1
                                real.print(markPrefix .. "NEEDFETCH " .. a1)
                                real.print(servePad)
                                coroutine.yield("__LRMRES " .. a1)
                        else
                                break
                        end
                end
        end
        if name == "GenerateGUID" and isMethod then
                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                local v1, v2, v3 = math.random(0, 2147483647), math.random(0, 2147483647), math.random(0, 2147483647)
                return string.format("%08x-%04x-4%03x-%04x-%04x%08x",
                        v1 % 4294967296,
                        v1 % 65536,
                        v2 % 4096,
                        (v3 % 16384) + 0x8000,
                        v2 % 65536, v3 % 4294967296)
        end
        if (name == "JSONEncode" or name == "JSONDecode") and isMethod then
                local j = cfg.__superz_json
                local ok, out
                if name == "JSONEncode" then
                        ok, out = real.pcall(j.encode, args[1])
                else
                        ok, out = real.pcall(j.decode, a1 or args[1])
                end
                if ok then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        return out
                end
        end
        if name == "GetClientId" and isMethod then
                emit({ text = calleeText .. "()" })
                return "6c1f8a20-4e2b-4c9d-9f3a-71b2d5e0a4c7"
        end
        if (name == "ComputeStringHash" or name == "ComputeBufferHash") and isMethod and real.sha256 then
                emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                local msg = a1
                if real.type(msg) == "buffer" then msg = buffer.tostring(msg) end
                local hex = real.sha256(real.tostring(msg or ""))
                local raw = real.gsub(hex, "..", function(cc) return string.char(real.tonumber(cc, 16)) end)
                if name == "ComputeBufferHash" then return buffer.fromstring(raw) end
                return raw
        end
        if (name == "HttpGet" or name == "HttpGetAsync" or name == "GetAsync") and real.type(a1) == "string" then
                remember(urls, a1)
                local szcanned = cfg.__superz_canned
                local hit = szcanned and (szcanned["GET " .. a1] or szcanned[a1])
                if hit then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        return hit.body
                end
        end

if name == "HttpGet" or name == "HttpGetAsync" or name == "HttpPost" or name == "HttpPostAsync"
                or name == "GetAsync" or name == "PostAsync" or name == "RequestAsync" then
                if real.type(a1) == "string" then remember(urls, a1) end
                return callP(calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")", "response", "string")
        end

        if name == "FireServer" or name == "InvokeServer" or name == "Fire" or name == "Invoke" then
                remember(remotes, info.parent)
        end

        if not native and sinfo and sinfo.className == "Path2D" and name == "SetControlPoints" then
                sinfo.p2dSegs = nil
                sinfo.p2dPoints = real.type(a1) == "table" and not isP(a1) and table.clone(a1) or nil
                sinfo.p2dSet = true
                local frameW, frameH = hub.p2d.frameSize(self)
                if frameW and real.type(a1) == "table" and not isP(a1) then
                        local ok, segs = real.pcall(hub.p2d.segments, a1, frameW, frameH)
                        if ok and segs and #segs > 0 then
                                sinfo.p2dSegs, sinfo.p2dW, sinfo.p2dH = segs, frameW, frameH
                        end
                end
        end
        if not native and sinfo and sinfo.className == "Path2D" and sinfo.created then
                if name == "GetMaxControlPoints" then
                        emit({ text = calleeText .. "()" })
                        return 100
                elseif name == "GetControlPoints" and (sinfo.p2dPoints or not sinfo.p2dSet) then
                        emit({ text = calleeText .. "()" })
                        return table.clone(sinfo.p2dPoints or {})
                elseif (name == "GetLength" or name == "GetBoundingRect" or (real.type(name) == "string"
                        and real.find(name, "OnCurve", 1, true))) and not isP(sinfo.props.Parent) then
                        emit({ text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")" })
                        real.error("Attempting to use Path2D with invalid parent", 0)
                end
        end
        if not native and sinfo and sinfo.className == "Path2D" and real.type(name) == "string" and (name == "GetLength" or name == "GetBoundingRect" or real.find(name, "OnCurve", 1, true)) then
                local rec = __p2d and __p2d[p2dKey(name, args)]
                if rec and cfg.p2d_check then
                        local ok, r = real.pcall(hub.p2d.answer, self, name, args[1])
                        real.print(markPrefix .. "P2DCHECK " .. p2dKey(name, args) .. "\t" .. real.tostring(rec) .. "\t" .. real.tostring(ok and r)
                                .. "\t" .. ((ok and r == rec) and "same" or "DIFF"))
                end
                if not rec and not cfg.p2d_nomodel then
                        local ok, r = real.pcall(hub.p2d.answer, self, name, args[1])
                        if ok and r then
                                rec = r
                                real.insert(p2dLog, p2dKey(name, args) .. "\t" .. r .. "\tmodel")
                        end
                end
                if not rec then p2dMiss = true end
                if rec then
                        local text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")"
                        local vals = {}
                        local n = 0
                        for field in string.gmatch(rec, "[^\t]+") do
                                n += 1
                                vals[n] = p2dDecode(field, text)
                        end
                        if n == 1 and isP(vals[1]) then
                                local cp = callP(text, real.match(name, "^Get(%u%w*)$") or "result", infoOf[vals[1]].tname)
                                infoOf[cp].props = infoOf[vals[1]].props
                                return cp
                        end
                        emit({ text = text })
                        return real.unpack(vals, 1, n)
                end
        end

        if self and realValues[self] ~= nil and real.type(name) == "string" and not noNativeMethod[name] then
                local r = realValues[self]
                local isInst = real.typeof(r) == "Instance"
                local u = unwrapArgs(args)
                if u then
                        local res = table.pack(real.pcall(function() return r[name](r, real.unpack(u, 1, u.n)) end))
                        if not res[1] then
                                if not isInst and res[2] ~= hub.dtUnsupported then real.error(res[2], 0) end
                        else
                                local text = calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")"
                                local hint0 = real.match(name, "^Get(%u%w*)$") or "result"
                                hint0 = real.gsub(hint0, "^%u", string.lower)
                                if isInst and r.ClassName == "Path2D" then
                                        local enc = {}
                                        for i = 2, res.n do enc[#enc + 1] = p2dEncode(res[i]) or "?" end
                                        real.insert(p2dLog, p2dKey(name, args) .. "\t" .. real.concat(enc, "\t"))
                                end
                                local outv, good = {}, true
                                for i = 2, res.n do
                                        local w, ok = wrapReal(res[i], text, hint0)
                                        if not ok then good = false break end
                                        outv[i - 1] = w
                                end
                                if good then
                                        if not isInst then return real.unpack(outv, 1, res.n - 1) end
                                        if res.n == 2 and isP(outv[1]) then
                                                local cp = callP(text, hint0, infoOf[outv[1]].tname)
                                                realValues[cp] = res[2]
                                                return cp
                                        end
                                        emit({ text = text })
                                        return real.unpack(outv, 1, res.n - 1)
                                end
                        end
                end
        end

        local hint
        if name == "FindFirstChild" or name == "WaitForChild" or name == "FindFirstChildOfClass"
                or name == "FindFirstChildWhichIsA" or name == "FindFirstAncestor" or name == "FindFirstAncestorOfClass"
                or name == "FindFirstAncestorWhichIsA" or name == "FindFirstDescendant" then
                hint = real.type(a1) == "string" and a1 or "child"
        elseif name == "new" and info.parent and infoOf[info.parent].kind == "name" and infoOf[info.parent].name == "Instance" then
                hint = real.type(a1) == "string" and a1 or "instance"
        elseif name and classHint[name] then
                hint = classHint[name]
        elseif name == "Clone" then
                hint = "clone"
        elseif name == "Create" and isMethod and infoOf[info.parent].className == "TweenService" then
                hint = "tween"
        elseif name then
                hint = real.match(name, "^Get(%u%w*)$") or real.match(name, "^Find(%u%w*)$")
                local made = real.match(name, "^Create(%u%w*)$") or real.match(name, "^New(%u%w*)$")
                        or real.match(name, "^Add(%u%w*)$") or real.match(name, "^Make(%u%w*)$")
                if hint then
                        hint = real.gsub(hint, "^%u", string.lower)
                else
                        hint = made or "result"
                end
        else
                hint = "result"
        end
        return callP(calleeText .. "(" .. fmtArgs(real.unpack(args, 1, args.n)) .. ")", hint)
end

local opaque = { EnumItem = 1, Enum = 1, Enums = 1, RBXScriptSignal = 1, RBXScriptConnection = 1 }
local function opaqueType(v)
        if not isP(v) then return nil end
        local info = infoOf[v]
        if opaque[info.tname] then return info.tname end
        if info.created or (info.className and info.kind ~= "call" or info.kind == "name" and info.className) then
                return "Instance"
        end
        return nil
end
local function luaTypeName(v)
        return opaqueType(v) or real.typeof(v)
end
local function arithError(opname, a, b)
        if opaqueType(a) or opaqueType(b) then
                real.error(real.fmt("attempt to perform arithmetic (%s) on %s and %s", opname, luaTypeName(a), luaTypeName(b)), 3)
        end
end
local arith = {
        ["+"] = function(a, b) return a + b end, ["-"] = function(a, b) return a - b end,
        ["*"] = function(a, b) return a * b end, ["/"] = function(a, b) return a / b end,
        ["//"] = function(a, b) return a // b end, ["%"] = function(a, b) return a % b end,
        ["^"] = function(a, b) return a ^ b end,
}
local opNames = { ["+"] = "add", ["-"] = "sub", ["*"] = "mul", ["/"] = "div", ["//"] = "idiv", ["%"] = "mod", ["^"] = "pow" }
local function binop(op, tname)
        return function(a, b)
                arithError(opNames[op], a, b)
                local ra, oka = realOf(a)
                local rb, okb = realOf(b)
                if oka and okb then
                        local ok, r = real.pcall(arith[op], ra, rb)
                        if not ok and native then real.error(r, 2) end
                        if ok then
                                local w, good = wrapReal(r, "(" .. fmt(a) .. " " .. op .. " " .. fmt(b) .. ")", nil)
                                if good then return w end
                        end
                end
                return exprP("(" .. fmt(a) .. " " .. op .. " " .. fmt(b) .. ")", tname or (isP(a) and infoOf[a].tname) or (isP(b) and infoOf[b].tname) or "number")
        end
end

local methodPrefix = { "Get", "Find", "Wait", "Is", "Clone", "Destroy", "Connect", "Once", "Fire", "Invoke",
        "Set", "Clear", "Remove", "Add", "Load", "Play", "Stop", "Pause", "Resume", "Adjust", "Move", "Pivot",
        "Apply", "Take", "Kick", "Teleport", "Emit", "Create", "Raycast", "Blockcast", "Spherecast", "Shapecast",
        "Http", "Request", "JSON", "Generate", "Compute", "Change", "Equip", "Unequip", "Preload", "Bind", "Unbind",
        "Disconnect", "Activate", "Deactivate", "Update", "Serialize", "Break", "Reset", "Scale", "To", "Lerp",
        "Navigate", "Render", "Open", "Close", "Enable", "Disable", "Insert", "Show", "Hide", "Tween", "Capture",
        "Post", "Publish", "Subscribe", "Increment", "Decrement", "Save", "Read", "Write", "Check", "Can", "Has",
        "Prompt", "Send", "Kill", "Spawn", "Transform", "Invert", "Reverse", "Clamp", "Sample", "Evaluate",
        "Batch", "Sync", "Query", "Register", "Unregister", "Rebuild", "Refresh", "Cancel", "Dump", "Test", "From", "Expand" }
local methodExact = { connect = 1, wait = 1, disconnect = 1, Wait = 1, Connect = 1, Once = 1, ConnectParallel = 1,
        Disconnect = 1, Destroy = 1, Clone = 1, Remove = 1, ClearAllChildren = 1, Kick = 1, Play = 1, Stop = 1,
        findFirstChild = 1, children = 1, getChildren = 1, clone = 1, destroy = 1, remove = 1, isA = 1 }
local methodCache = real.setmetatable({}, { __mode = "k" })
local methodProxy = real.setmetatable({}, { __mode = "k" })
methodProxyRef = methodProxy
function isMethodName(k)
        if real.type(k) ~= "string" then return false end
        if methodExact[k] then return true end
        for _, pre in methodPrefix do
                if real.sub(k, 1, #pre) == pre and real.match(real.sub(k, #pre + 1, #pre + 1), "^%u$") then
                        return true
                end
        end
        return false
end
local sharedMethods = {}
local signalT = { RBXScriptSignal = true, RBXScriptConnection = true }
function methodFn(p, k)
        local want = infoOf[p].tname
        if signalT[want] then
                local ip = indexP(p, k)
                local f = function(...)
                        local self = ...
                        if real.select("#", ...) == 0 then
                                real.error(real.fmt("missing argument #1 to '%s' (%s expected)", k, want), 0)
                        end
                        if not (isP(self) and infoOf[self].tname == want) then
                                real.error(real.fmt("invalid argument #1 to '%s' (%s expected, got %s)", k, want, luaTypeName(self)), 0)
                        end
                        return proxyMeta.__call(indexP(self, k), ...)
                end
                cfuncs[f] = true
                cnames[f] = k
                methodProxy[f] = ip
                return f
        end
        local ck = real.tostring(infoOf[p].tname) .. "|" .. real.tostring(k)
        local f = sharedMethods[ck]
        if f then return f end
        local ip = indexP(p, k)
        f = function(...)
                local self = ...
		if not (isP(self) and (want == nil or infoOf[self].tname == want)) then
			if runserviceBool[k] ~= nil and not cfg.devirt then
				return runserviceBool[k]
			end
			real.error("Expected ':' not '.' calling member function " .. k, 0)
		end
                return proxyMeta.__call(indexP(self, k), ...)
        end
        cfuncs[f] = true
        cnames[f] = k
        methodProxy[f] = ip
        sharedMethods[ck] = f
        return f
end

local signalMembers = {
        RBXScriptSignal = { Connect = "method", ConnectParallel = "method", Once = "method", Wait = "method" },
        RBXScriptConnection = { Connected = "prop", Disconnect = "method" },
}
proxyMeta.__index = function(p, k)
        local info = infoOf[p]
        if signalT[info.tname] then
                if k == "connect" then k = "Connect" elseif k == "wait" then k = "Wait" elseif k == "disconnect" then k = "Disconnect" end
        end
        if k == "CreatorType" then return cfg.__superz_creator_type or "User" end
        if k == "GameId" then return cfg.__superz_game_id or 0 end
        if k == "PlaceId" then return cfg.__superz_place_id or 0 end
        if k == "CreatorId" then return cfg.__superz_creator_id or 0 end
        if cfg.trace or cfg.ptrace then real.print("[index]", info.name or info.hint, k) end
        if k == "Parent" and (info.nilParent or info.created) then return info.props.Parent end
        if k == "Parent" and info.props.Parent == nil and info.tname == "Instance" and p ~= workspaceProxy then
                local depth, q = 0, p
                while q and infoOf[q] and infoOf[q].key == "Parent" do
                        depth += 1
                        q = infoOf[q].parent
                end
                if depth >= 3 then return workspaceProxy end
        end
        if signalMembers[info.tname] then
                local m = signalMembers[info.tname][k]
                if m == "method" then return methodFn(p, k) end
                if m == nil then
                        real.error(real.fmt("%s is not a valid member of %s", real.tostring(k), info.tname), 0)
                end
        end
        local v = info.props[k]
        if v ~= nil then return v end
        if (info.tname == "RaycastParams" or info.tname == "OverlapParams") and k == "IncludeInstances" then
                return nil
        end
        if info.created then
                if hub.isClassA(info.className, "BasePart") then
                        if k == "CurrentPhysicalProperties" then
                                return info.props.CustomPhysicalProperties or scriptEnv.PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
                        elseif k == "Mass" then
                                local f32 = hub.p2d.f32
                                local sz = info.props.Size or vector.create(4, 1.2, 2)
                                local cpp = info.props.CustomPhysicalProperties or scriptEnv.PhysicalProperties.new(0.7, 0.3, 0.5, 1, 1)
                                return f32(f32(f32(sz.X * sz.Y) * sz.Z) * cpp.Density)
                        end
                elseif info.className == "Attachment" or info.className == "Bone" then
                        if k == "WorldCFrame" then
                                return hub.attParentWorldCF(p) * (info.props.CFrame or scriptEnv.CFrame.identity)
                        elseif k == "WorldPosition" then
                                return (hub.attParentWorldCF(p) * (info.props.CFrame or scriptEnv.CFrame.identity)).Position
                        end
                elseif hub.isClassA(info.className, "GuiObject") then
                        if k == "AbsoluteSize" then
                                local w, h = hub.guiUnscaledSize(p)
                                local sc = hub.guiScale(p)
                                return scriptEnv.Vector2.new(w * sc, h * sc)
                        elseif k == "AbsolutePosition" then
                                local par = info.props.Parent
                                local px, py, pw, ph = 0, 0, 0, 0
                                if isP(par) and infoOf[par].className ~= "ScreenGui" then
                                        local pap = par.AbsolutePosition
                                        px, py = pap.X, pap.Y
                                        pw, ph = hub.guiUnscaledSize(par)
                                end
                                local sc = hub.guiScale(p)
                                local layout = nil
                                if isP(par) then
                                        for _, c in kidsOf(par) do
                                                if infoOf[c] and infoOf[c].className == "UIListLayout" then layout = c; break end
                                        end
                                end
                                if layout then
                                        local li = infoOf[layout]
                                        local pad = li.props.Padding
                                        local padPx = (isP(pad) and realValues[pad] and (realValues[pad].Offset * sc)) or 0
                                        local horiz = isP(li.props.FillDirection) and infoOf[li.props.FillDirection].props.Name == "Horizontal"
                                        local items = {}
                                        for idx, c in kidsOf(par) do
                                                if infoOf[c] and hub.isClassA(infoOf[c].className, "GuiObject") then
                                                        real.insert(items, { c = c, lo = real.tonumber(infoOf[c].props.LayoutOrder) or 0, idx = idx })
                                                end
                                        end
                                        table.sort(items, function(a, b) if a.lo ~= b.lo then return a.lo < b.lo end return a.idx < b.idx end)
                                        local off = 0
                                        for _, it in items do
                                                if it.c == p then break end
                                                local asz = it.c.AbsoluteSize
                                                off = off + (horiz and asz.X or asz.Y) + padPx
                                        end
                                        return scriptEnv.Vector2.new(horiz and (px + off) or px, horiz and py or (py + off))
                                end
                                local pos = info.props.Position
                                local ox, oy = 0, 0
                                if isP(pos) and realValues[pos] then
                                        local r = realValues[pos]
                                        ox, oy = (r.X.Scale * pw + r.X.Offset) * sc, (r.Y.Scale * ph + r.Y.Offset) * sc
                                end
                                return scriptEnv.Vector2.new(px + ox, py + oy)
                        end
                elseif info.className == "UIListLayout" and k == "AbsoluteContentSize" then
                        local par = info.props.Parent
                        if not isP(par) then return scriptEnv.Vector2.new(0, 0) end
                        local sc = hub.guiScale(par)
                        local pad = info.props.Padding
                        local padPx = (isP(pad) and realValues[pad] and (realValues[pad].Offset * sc)) or 0
                        local horiz = isP(info.props.FillDirection) and infoOf[info.props.FillDirection].props.Name == "Horizontal"
                        local totalMain, maxCross, count = 0, 0, 0
                        for _, c in kidsOf(par) do
                                if infoOf[c] and hub.isClassA(infoOf[c].className, "GuiObject") then
                                        count += 1
                                        local asz = c.AbsoluteSize
                                        if horiz then
                                                totalMain += asz.X
                                                if asz.Y > maxCross then maxCross = asz.Y end
                                        else
                                                totalMain += asz.Y
                                                if asz.X > maxCross then maxCross = asz.X end
                                        end
                                end
                        end
                        if count > 1 then totalMain += (count - 1) * padPx end
                        return horiz and scriptEnv.Vector2.new(totalMain, maxCross) or scriptEnv.Vector2.new(maxCross, totalMain)
                elseif info.className == "ObjectValue" and k == "Value" then
                        return nil
                end
        end
        local rv = realValues[p]
        if rv ~= nil and real.type(k) == "string" then
                local isInst = real.typeof(rv) == "Instance"
                local ok, x = real.pcall(function() return rv[k] end)
                if not ok then
                        if not isInst and x ~= hub.dtUnsupported then real.error(x, 2) end
                elseif x == nil and info.tname == "TweenInfo" then
                        if k == "EasingStyle" then return enumItem("EasingStyle", "Quad") end
                        if k == "EasingDirection" then return enumItem("EasingDirection", "Out") end
                elseif real.type(x) ~= "function" then
                        local w, good = wrapReal(x, tok(p) .. keySuffix(k), k)
                        if good then return w end
                end
        end
        if info.genv then
                return nil
        end
        if info.tname == "Enums" and real.type(k) == "string" and api.enums[k] then
                return enumType(k)
        end
        if info.tname == "Enum" and info.enumName then
                local e = api.enums[info.enumName]
                if e and e.byName[k] then return enumItem(info.enumName, k) end
                if k == "GetEnumItems" or k == "FromName" or k == "FromValue" then return methodFn(p, k) end
        end
        if info.tname == "EnumItem" and k == "IsA" then
                return methodFn(p, k)
        end
        if (info.tname == "Faces" or info.tname == "Axes") and info.ctor and real.type(k) == "string" then
                local axisOf = { Right = "X", Left = "X", Top = "Y", Bottom = "Y", Back = "Z", Front = "Z" }
                local isFaces = info.tname == "Faces"
                local want = isFaces and (axisOf[k] and k) or (axisOf[k] or ((k == "X" or k == "Y" or k == "Z") and k))
                if want then
                        local a = info.ctor.args
                        for i = 1, a.n do
                                local ai = isP(a[i]) and infoOf[a[i]]
                                if ai and ai.tname == "EnumItem" then
                                        local n = ai.props.Name
                                        if isFaces then
                                                if ai.enumName == "NormalId" and n == want then return true end
                                        elseif (ai.enumName == "NormalId" and axisOf[n] == want) or (ai.enumName == "Axis" and n == want) then
                                                return true
                                        end
                                end
                        end
                        return false
                end
        end
        local dm = dtMembers[info.tname]
        if dm and real.type(k) == "string" and dm[k] and realValues[p] == nil then
                if dm[k] == "n" then return 0 end
                local c = indexP(p, k)
                infoOf[c].tname = dm[k]
                infoOf[c].className = nil
                return c
        end
        local cls = info.className
        if cls and api.classes[cls] and real.type(k) == "string" then
                local kind = memberKind(cls, k)
                if kind == "method" then return methodFn(p, k) end
                if kind == "event" then
                        local c = newP({ kind = "index", parent = p, key = k, tname = "RBXScriptSignal", hint = k,
                                sigKey = info.id .. "." .. k })
                        return c
                end
                if kind == "prop" then
                        local vt = propType(cls, k)
                        if vt and numericT[vt] then return numDefault[k] or 0 end
                        local c = indexP(p, k)
                        if vt and dtMembers[vt] then
                                infoOf[c].tname = vt
                                infoOf[c].className = nil
                        elseif vt == "bool" then
                                infoOf[c].tname = "boolean"
                                infoOf[c].className = nil
                        elseif vt == "string" then
                                infoOf[c].tname = "string"
                                infoOf[c].className = nil
                        end
                        return c
                end
        end
        if isMethodName(k) and info.tname ~= "table" then
                return methodFn(p, k)
        end
        return indexP(p, k)
end
proxyMeta.__newindex = function(p, k, v)
        local info = infoOf[p]
        if cfg.ptrace then real.print("[newindex]", info.name or info.hint, k, real.typeof(v)) end
        if k == "Parent" and info.destroyed then
                real.error(real.fmt("The Parent property of %s is locked, current parent: NULL, new parent %s",
                        instName(p), isP(v) and instName(v) or "NULL"), 0)
        end
        emit({ text = tok(p) .. keySuffix(k) .. " = " .. fmt(v) })
        local rv = realValues[p]
        if native and rv ~= nil and k ~= "Parent" and real.type(k) == "string" then
                local u = unwrapArgs(table.pack(v))
                if u then
                        local ok, err = real.pcall(function() rv[k] = u[1] end)
                        if not ok then real.error(err, 2) end
                end
        end
        if k == "Parent" and (v == nil or isP(v)) then
                setParent(p, v)
        elseif (info.tname == "RaycastParams" or info.tname == "OverlapParams") and (k == "ExcludeInstances" or k == "IncludeInstances") then
                if v == nil then
                        info.props[k] = (k == "ExcludeInstances") and table.freeze({}) or nil
                elseif real.type(v) == "table" then
                        info.props[k] = table.freeze(table.clone(v))
                end
        elseif info.created and hub.isClassA(info.className, "BasePart") then
                if k == "CFrame" and isP(v) then
                        info.props.CFrame = v
                        info.props.Position = v.Position
                elseif k == "Position" and real.type(v) == "vector" then
                        info.props.Position = v
                        local cf = info.props.CFrame or scriptEnv.CFrame.identity
                        info.props.CFrame = (cf - cf.Position) + v
                else
                        info.props[k] = v
                end
        elseif info.created and (info.className == "Attachment" or info.className == "Bone") then
                if k == "CFrame" and isP(v) then
                        info.props.CFrame = v
                        info.props.Position = v.Position
                elseif k == "Position" and real.type(v) == "vector" then
                        info.props.Position = v
                        local cf = info.props.CFrame or scriptEnv.CFrame.identity
                        info.props.CFrame = (cf - cf.Position) + v
                elseif k == "WorldCFrame" and isP(v) then
                        local lcf = hub.attParentWorldCF(p):Inverse() * v
                        info.props.CFrame = lcf
                        info.props.Position = lcf.Position
                elseif k == "WorldPosition" and real.type(v) == "vector" then
                        local lpos = hub.attParentWorldCF(p):PointToObjectSpace(v)
                        info.props.Position = lpos
                        local cf = info.props.CFrame or scriptEnv.CFrame.identity
                        info.props.CFrame = (cf - cf.Position) + lpos
                else
                        info.props[k] = v
                end
        else
                info.props[k] = v
        end
end
proxyMeta.__call = onCall
proxyMeta.__tostring = function(p)
        if realValues[p] ~= nil then return real.tostring(realValues[p]) end
        return "<" .. (infoOf[p].hint or "proxy") .. ">"
end
proxyMeta.__concat = function(a, b)
        if opaqueType(a) or opaqueType(b) then
                real.error(real.fmt("attempt to concatenate %s with %s", luaTypeName(a), luaTypeName(b)), 2)
        end
        local function __sz_rval(x)
                local t = type(x)
                if (t == "table" or t == "userdata") and realValues[x] ~= nil then return realValues[x] end
                return x
        end
        local __ra, __rb = __sz_rval(a), __sz_rval(b)
        local __ta, __tb = real.type(__ra), real.type(__rb)
        if (__ta == "string" or __ta == "number") and (__tb == "string" or __tb == "number") then
                return __ra .. __rb
        end
        if cfg.__superz_logglobal then
                local function __sz_desc(x)
                        local rv = "-"
                        local xt = type(x)
                        if (xt == "table" or xt == "userdata") and realValues[x] ~= nil then rv = real.tostring(realValues[x]):sub(1, 40) end
                        local inf = ((xt == "table" or xt == "userdata") and infoOf[x]) or nil
                        local kind = inf and real.tostring(inf.kind) or "?"
                        local txt = inf and real.tostring(inf.text or inf.name or inf.hint or "?"):sub(1, 60) or real.tostring(x):sub(1, 40)
                        return xt .. "/" .. kind .. "/" .. txt .. "/realv=" .. rv
                end
                real.print("\1SUPERZCONCATOP\1" .. __sz_desc(a) .. " || " .. __sz_desc(b))
        end
        return exprP(fmt(a) .. " .. " .. fmt(b), "string")
end
proxyMeta.__add = binop("+")
proxyMeta.__sub = binop("-")
proxyMeta.__mul = binop("*")
proxyMeta.__div = binop("/")
proxyMeta.__idiv = binop("//")
proxyMeta.__mod = binop("%")
proxyMeta.__pow = binop("^")
proxyMeta.__unm = function(a)
        if opaqueType(a) then
                real.error(real.fmt("attempt to perform arithmetic (unm) on %s", luaTypeName(a)), 2)
        end
        if realValues[a] ~= nil then
                local ok, r = real.pcall(function() return -realValues[a] end)
                if not ok and native then real.error(r, 2) end
                if ok then
                        local w, good = wrapReal(r, "(-" .. fmt(a) .. ")", nil)
                        if good then return w end
                end
        end
        return exprP("(-" .. fmt(a) .. ")", infoOf[a].tname)
end
proxyMeta.__len = function(p)
        return 1
end
proxyMeta.__eq = function(a, b)
        if cfg.ptrace then real.print("[eq]", infoOf[a] and (infoOf[a].name or infoOf[a].hint), infoOf[b] and (infoOf[b].name or infoOf[b].hint)) end
        local ra, rb = realValues[a], realValues[b]
        if ra ~= nil and rb ~= nil then return ra == rb end
        local ia, ib = infoOf[a], infoOf[b]
        if ia and ib and ia.sigKey and ia.sigKey == ib.sigKey then return true end
        return real.rawequal(a, b)
end
local assumedCmp = 0
proxyMeta.__lt = function(a, b)
        assumedCmp += 1
        comment("condition: " .. fmt(a) .. " < " .. fmt(b) .. "  (assumed true)")
        return true
end
proxyMeta.__le = function(a, b)
        assumedCmp += 1
        comment("condition: " .. fmt(a) .. " <= " .. fmt(b) .. "  (assumed false)")
        return false
end
proxyMeta.__iter = function(p)
        return iterProxy(p, nil)
end
proxyMeta.__metatable = "The metatable is locked"

local function anyProxy(...)
        for i = 1, real.select("#", ...) do
                if isP((real.select(i, ...))) then return true end
        end
        return false
end

local function wrapLib(libName, lib, tname)
        local out = {}
        for k, f in real.pairs(lib) do
                if real.type(f) == "function" then
                        local label = libName .. "." .. k
                        out[k] = function(...)
                                if anyProxy(...) then
                                        return exprP(label .. "(" .. fmtArgs(...) .. ")", tname)
                                end
                                return f(...)
                        end
                else
                        out[k] = f
                end
        end
        return out
end

function genvTable(label)
        local t = {}
        genvName[t] = label
        local shadow = {}
        hub.genvShadow = hub.genvShadow or {}
        hub.genvShadow[t] = shadow
        return real.setmetatable(t, {
                __newindex = function(self, k, v)
                        emit({ text = label .. keySuffix(k) .. " = " .. fmt(v) })
                        real.rawset(self, k, v)
                        shadow[k] = v
                end,
        })
end
hub.syncGenv = function()
        hub.syncing = true
        for t, shadow in real.next, hub.genvShadow do
                local label = genvName[t]
                for k, v in real.next, t do
                        if not real.rawequal(shadow[k], v) then
                                shadow[k] = v
                                emit({ text = label .. keySuffix(k) .. " = " .. fmt(v) })
                        end
                end
                for k in real.next, shadow do
                        if real.rawget(t, k) == nil then
                                shadow[k] = nil
                                emit({ text = label .. keySuffix(k) .. " = nil" })
                        end
                end
        end
        hub.syncing = false
end

scriptEnv = {}
local envTable = scriptEnv
local RandomMT = {}
local randomState
local genv = genvTable("getgenv()")
local collected = {}

envTable.string = wrapLib("string", string, "string")
envTable.math = wrapLib("math", math, "number")
envTable.table = table
envTable.bit32 = bit32
envTable.coroutine = coroutine
local UNorm = (function()
        local unicodeData = __unicode or { decomp = "", ccc = "", comp = "" }
        local decomp, ccc, comp = {}, {}, {}
        for k, v in string.gmatch(unicodeData.decomp, "(%x+):([%x,]+)") do
                local list = {}
                for x in string.gmatch(v, "%x+") do real.insert(list, real.tonumber(x, 16)) end
                decomp[real.tonumber(k, 16)] = list
        end
        for k, v in string.gmatch(unicodeData.ccc, "(%x+):(%x+)") do
                ccc[real.tonumber(k, 16)] = real.tonumber(v, 16)
        end
        for a, b, c in string.gmatch(unicodeData.comp, "(%x+),(%x+):(%x+)") do
                comp[real.tonumber(a, 16) * 0x110000 + real.tonumber(b, 16)] = real.tonumber(c, 16)
        end
        local SBase, LBase, VBase, TBase = 0xAC00, 0x1100, 0x1161, 0x11A7
        local LCount, VCount, TCount = 19, 21, 28
        local NCount = VCount * TCount
        local SCount = LCount * NCount

        local function decompose(s)
                local out = {}
                for _, cp in utf8.codes(s) do
                        local si = cp - SBase
                        if si >= 0 and si < SCount then
                                real.insert(out, LBase + si // NCount)
                                real.insert(out, VBase + (si % NCount) // TCount)
                                local t = si % TCount
                                if t ~= 0 then real.insert(out, TBase + t) end
                        elseif decomp[cp] then
                                for _, x in decomp[cp] do real.insert(out, x) end
                        else
                                real.insert(out, cp)
                        end
                end
                local i = 1
                while i <= #out do
                        if (ccc[out[i]] or 0) > 0 then
                                local j = i
                                while j + 1 <= #out and (ccc[out[j + 1]] or 0) > 0 do j += 1 end
                                for a = i + 1, j do
                                        local x = out[a]
                                        local cx = ccc[x]
                                        local b = a - 1
                                        while b >= i and ccc[out[b]] > cx do
                                                out[b + 1] = out[b]
                                                b -= 1
                                        end
                                        out[b + 1] = x
                                end
                                i = j + 1
                        else
                                i += 1
                        end
                end
                return out
        end

        local function compose(cps)
                local out = {}
                local starter = nil
                local lastClass = -1
                for _, cp in cps do
                        local c = ccc[cp] or 0
                        local done = false
                        if starter then
                                local s = out[starter]
                                local li, vi = s - LBase, cp - VBase
                                if li >= 0 and li < LCount and vi >= 0 and vi < VCount and starter == #out then
                                        out[starter] = SBase + (li * VCount + vi) * TCount
                                        done = true
                                else
                                        local si, ti = s - SBase, cp - TBase
                                        if si >= 0 and si < SCount and si % TCount == 0 and ti > 0 and ti < TCount and starter == #out then
                                                out[starter] = s + ti
                                                done = true
                                        end
                                end
                                if not done and (lastClass < c or (lastClass == 0 and starter == #out)) then
                                        local p = comp[s * 0x110000 + cp]
                                        if p and (starter == #out or lastClass < c) then
                                                out[starter] = p
                                                done = true
                                        end
                                end
                        end
                        if not done then
                                real.insert(out, cp)
                                if c == 0 then
                                        starter = #out
                                        lastClass = 0
                                else
                                        lastClass = c
                                end
                        end
                end
                return out
        end

        local function pack(cps)
                local parts = {}
                for i, cp in cps do parts[i] = utf8.char(cp) end
                return real.concat(parts)
        end
        return {
                nfd = function(s) return pack(decompose(s)) end,
                nfc = function(s) return pack(compose(decompose(s))) end,
        }
end)()

envTable.utf8 = (function()
        local t = {}
        for k, v in real.pairs(utf8) do t[k] = v end
        t.graphemes = function(s, i, j)
                local list = {}
                for p, c in utf8.codes(s) do real.insert(list, { p, p + #utf8.char(c) - 1 }) end
                local n = 0
                return function()
                        n += 1
                        local g = list[n]
                        if g then return g[1], g[2] end
                end
        end
        t.nfcnormalize = function(s) return UNorm.nfc(s) end
        t.nfdnormalize = function(s) return UNorm.nfd(s) end
        return t
end)()
envTable.vector = vector
envTable.os = { clock = function() return real.clock() + (hub.clockOff or 0) end, time = os.time, date = os.date, difftime = os.difftime }
cnames[envTable.os.clock] = "clock"
envTable.debug = debug
envTable.buffer = (function()
        local b = {}
        local robloxBuffer = {}
        for n in string.gmatch("copy,create,fill,fromstring,len,readbits,readf32,readf64,readi16,readi32,readi8,"
                .. "readstring,readu16,readu32,readu8,tostring,writebits,writef32,writef64,writei16,writei32,writei8,"
                .. "writestring,writeu16,writeu32,writeu8", "[^,]+") do robloxBuffer[n] = true end
        for k, f in real.pairs(buffer) do
                if robloxBuffer[k] then b[k] = f end
        end
        local lastOff = -1
        local undo = {}
        for _, nm in { "writei8", "writeu8", "writei16", "writeu16" } do
                b[nm] = buffer[nm]
        end
        for _, nm in { "writei32", "writeu32" } do
                local orig = buffer[nm]
                b[nm] = function(buf, off, v)
                        if tamperCount > 0 and v >= 0 and v < 256 and off ~= lastOff + 4 and buffer.len(buf) > 4096 then
                                real.error(tamper, 0)
                        end
                        if v >= 0 and v < 256 and off ~= lastOff + 4 and buffer.len(buf) > 4096 and off + 4 <= buffer.len(buf) then
                                real.insert(undo, { buf, off, buffer.readu32(buf, off) })
                                if #undo >= (cfg.tamper_limit or 64) then
                                        for i = #undo, 1, -1 do
                                                local u = undo[i]
                                                buffer.writeu32(u[1], u[2], u[3])
                                        end
                                        table.clear(undo)
                                        tamperCount += 1
                                        if not trigger then noteTrigger() end
                                        if (cfg.oplog or cfg.inline_probe) and envTable.__opdump then envTable.__opdump() end
                                        real.error(tamper, 0)
                                end
                        elseif #undo > 0 and off == lastOff + 4 then
                                table.clear(undo)
                        end
                        lastOff = off
                        return orig(buf, off, v)
                end
        end
        if not cfg.dump_strings then return b end
        b.readstring = function(buf, off, len)
                local s = buffer.readstring(buf, off, len)
                real.insert(collected, s)
                return s
        end
        b.tostring = function(buf)
                local s = buffer.tostring(buf)
                real.insert(collected, s)
                return s
        end
        return b
end)()

for _, k in { "assert", "error", "next", "rawget", "rawset", "rawequal", "rawlen", "select", "setmetatable",
        "getmetatable", "unpack", "newproxy", "gcinfo", "_VERSION" } do
        envTable[k] = realGlobals[k]
end

envTable.type = function(...)
        local v = ...
        if isP(v) then
                local t = infoOf[v].tname
                if t == "string" or t == "number" or t == "table" or t == "boolean" then return t end
                return "userdata"
        end
        return real.type(...)
end
envTable.typeof = function(...)
        local v = ...
        if cfg.ptrace then real.print("[typeof]", isP(v) and (infoOf[v].name or infoOf[v].hint) or real.typeof(v)) end
        if isP(v) then
                local t = infoOf[v].tname
                if t == "table" then return "table" end
                return t or "Instance"
        end
        if randomState and randomState[v] then return "Random" end
        local t = real.typeof(...)
        if t == "vector" then return "Vector3" end
        return t
end
envTable.tostring = function(...)
        local v = ...
        if cfg.ptrace then real.print("[tostring]", isP(v) and (infoOf[v].name or infoOf[v].hint) or real.typeof(v)) end
        if isP(v) then
                local info = infoOf[v]
                if info.tname == "EnumItem" then return "Enum." .. info.enumName .. "." .. info.props.Name end
                if info.tname == "Enum" then return info.enumName end
                if info.tname == "Enums" then return "Enums" end
                if realValues[v] ~= nil then return real.tostring(realValues[v]) end
                if real.type(info.props.Name) == "string" and (info.className or opaqueType(v) == "Instance") then return info.props.Name end
                if cfg.__superz_logglobal then
                        local iks = {}
                        for ik2, iv2 in pairs(info) do
                                iks[#iks + 1] = tostring(ik2) .. "=" .. tostring(iv2):sub(1, 70)
                        end
                        real.print("\1SUPERZTOSTRING\1" .. table.concat(iks, " | "))
                end
                return exprP("tostring(" .. tok(v) .. ")", "string")
        end
        return real.tostring(...)
end
envTable.tonumber = function(...)
        local v = ...
        if isP(v) then return exprP("tonumber(" .. tok(v) .. ")", "number") end
        return real.tonumber(...)
end
envTable.next = function(...)
        local t = ...
        if isP(t) then
                if real.select("#", ...) < 1 then real.error("missing argument #1 to 'next' (table expected)", 0) end
                return nil
        end
        return real.next(...)
end
envTable.pairs = function(...)
        local t = ...
        if isP(t) then return iterProxy(t, "pairs"), t, nil end
        local f, s0, c0 = real.pairs(...)
        if f == real.next then f = envTable.next end
        return f, s0, c0
end
envTable.ipairs = function(...)
        local t = ...
        if isP(t) then return iterProxy(t, "ipairs"), t, 0 end
        return real.ipairs(...)
end
envTable.pcall = real.pcall
envTable.ypcall = real.pcall
envTable.xpcall = real.xpcall
if cfg.cstack_pcall then
        local resume, yield = coroutine.resume, coroutine.yield
        local atLimit = false
        local inner = coroutine.create(function()
                while true do yield() end
        end)
        local outer = coroutine.create(function()
                while true do
                        atLimit = not resume(inner)
                        yield()
                end
        end)
        local rpcall = real.pcall
        local limitedPcall = function(...)
                atLimit = true
                resume(outer)
                if atLimit then return false, "C stack overflow" end
                return rpcall(...)
        end
        cfuncs[limitedPcall] = true
        cnames[limitedPcall] = "pcall"
        fnText[limitedPcall] = "pcall"
        envTable.pcall = limitedPcall
        envTable.ypcall = limitedPcall
end
envTable.getfenv = function(x)
        if isP(x) and infoOf[x].tname == "function" then return scriptEnv end
        local arg = x
        if x == nil then
                arg = 3
        elseif real.type(x) == "number" and x > 0 then
                arg = x + 2
        end
        local ok, env = real.pcall(real.getfenv, arg)
        if not ok then real.error(env, 2) end
        return env
end
cfuncs[envTable.getfenv] = true
envTable.setfenv = function(x, env)
        if real.type(x) == "number" then
                return real.setfenv(x == 0 and 0 or x + 1, env)
        end
        if cfuncs[x] or isP(x) or (real.type(x) == "function" and debug.info(x, "s") == harnessSrc0) then
                real.error("'setfenv' cannot change environment of given object", 0)
        end
        return real.setfenv(x, env)
end
envTable.print = function(...)
        emit({ text = "print(" .. fmtArgs(...) .. ")" })
end
envTable.warn = function(...)
        emit({ text = "warn(" .. fmtArgs(...) .. ")" })
end
local newChunks = {}
local function srcKey(src)
        local h = 0
        for i = 1, #src, protocol.hash_stride do
                local bytes = { real.byte(src, i, math.min(i + protocol.hash_stride - 1, #src)) }
                for _, b in bytes do h = (h * protocol.hash_mult + b) % protocol.hash_mod end
        end
        return #src .. "_" .. h
end
envTable.loadstring = function(src, chunkname)
        if isP(src) then
                return exprP("loadstring(" .. tok(src) .. ")", "function")
        end
        local patched = nil
        if real.type(src) == "string" and #src >= (cfg.chunk_min or protocol.chunk_min) then
                local key = srcKey(src)
                patched = __chunks and __chunks[key]
                if not patched and not newChunks[key] then
                        newChunks[key] = src
                        real.insert(newChunks, key)
                end
                if cfg.spin and not (patched and real.find(patched, "__spin.n", 1, true)) then
                        patched = real.gsub(patched or src, "while true do [%w_, ]-=[%a_][%w_]*%[[%a_][%w_]*%];",
                                "%0__spin.n=__spin.n+1;if __spin.n>=__spin.step then __spin.f()end;")
                        patched = real.gsub(patched, "repeat local [%a_][%w_]*=%([%a_][%w_]*%[[%a_][%w_]*%]%);",
                                "%0__spin.n=__spin.n+1;if __spin.n>=__spin.step then __spin.f()end;")
                end
        end
        local f, err = real.loadstring(patched or src, chunkname)
        if not f then return nil, err end
        real.setfenv(f, scriptEnv)
        comment("loadstring() of " .. #src .. " bytes: " .. quote(real.sub(src, 1, 200)))
        return f
end
envTable.require = function(m)
        return callP("require(" .. fmt(m) .. ")", "module")
end

local function spawnLike(label, fn, ...)
        if real.type(fn) == "function" then
                local args = table.pack(...)
                lastThread = nil
                local okc, tokf = real.pcall(captureFunction, fn, nil, args)
                if not okc then
                        local fid = funcs[fn]
                        if fid then
                                local p = newP({ kind = "call", tname = "thread", hint = "thread" })
                                local st = { call = label .. "(" .. fid .. ")", res = p }
                                infoOf[p].stmt = st
                                real.insert(curBlock().lines, st)
                        end
                        real.error(tokf, 0)
                end
                local th = lastThread
                local p = callP(label .. "(" .. tokf .. (args.n > 0 and (", " .. fmtArgs(...)) or "") .. ")", "thread", "thread")
                if th then
                        threadProxy[th] = p
                        return th
                end
                return p
        end
        return callP(label .. "(" .. fmtArgs(fn, ...) .. ")", "thread", "thread")
end
local function doWait(label, t)
        local ret1 = (real.type(t) == "number" and t) or 0.03
        hub.clockOff = (hub.clockOff or 0) + ret1
        local ret2 = cfg.time_pin and ((cfg.time_pin or 0) + (cfg.clock_pin or 0.125) + hub.clockOff) or (real.clock() + hub.clockOff)
        local th = coroutine.running()
        if not deferred.running and th and th ~= deferred.runner and coroutine.isyieldable() then
                if captureDepth > 0 then
                        emit({ text = label .. "(" .. (t ~= nil and fmt(t) or "") .. ")" })
                        onWait()
                        real.insert(deferred, { rec = { params = {}, block = curBlock() }, thread = th,
                                args = { ret1, ret2, n = 2 }, n = 2, due = 0.25 })
                end
                return coroutine.yield(ret1, ret2)
        end
        emit({ text = label .. "(" .. (t ~= nil and fmt(t) or "") .. ")" })
        onWait()
        return ret1, ret2
end
local function typeName(n, ...)
        if real.select("#", ...) < n then return "no value" end
        return real.typeof((real.select(n, ...)))
end
local function argError(n, fname, expected, ...)
        real.error(real.fmt("invalid argument #%d to '%s' (%s expected, got %s)", n, fname, expected, typeName(n, ...)), 0)
end
local function checkRoutine(n, fname, ...)
        local v = real.select(n, ...)
        local t = real.type(v)
        if real.select("#", ...) < n or (t ~= "function" and t ~= "thread") then
                argError(n, fname, "function or thread", ...)
        end
        return v
end
local function checkNumber(n, fname, ...)
        local v = real.select(n, ...)
        if real.select("#", ...) >= n and v ~= nil and real.type(v) ~= "number" then
                if real.tonumber(v) then return real.tonumber(v) end
                argError(n, fname, "number", ...)
        end
        return v
end

local function scheduleLater(label, delayArg, due, fn, ...)
        if real.type(fn) == "thread" then
                local th = fn
                local args = table.pack(...)
                real.insert(deferred, { rec = { params = {}, block = { lines = {}, waits = {} } }, thread = th,
                        args = args, n = args.n, due = due })
                emit({ text = label .. "(" .. (delayArg and (fmt(delayArg) .. ", ") or "") .. fmt(th) .. ")" })
                return th
        end
        local args = table.pack(...)
        lastThread = nil
        local tokf = captureFunction(fn, nil, args, due)
        local th = lastThread
        local p = callP(label .. "(" .. (delayArg ~= nil and (fmt(delayArg) .. ", ") or "") .. tokf
                .. (args.n > 0 and (", " .. fmtArgs(...)) or "") .. ")", "thread", "thread")
        if th then threadProxy[th] = p; return th end
        return p
end

envTable.task = {
        spawn = function(...)
                local fn = checkRoutine(1, "spawn", ...)
                if real.type(fn) == "thread" then
                        emit({ text = "task.spawn(" .. fmt(fn) .. ")" })
                        coroutine.resume(fn, real.select(2, ...))
                        return fn
                end
                return spawnLike("task.spawn", ...)
        end,
        defer = function(...)
                checkRoutine(1, "defer", ...)
                return scheduleLater("task.defer", nil, 0.5, ...)
        end,
        delay = function(...)
                local t = checkNumber(1, "delay", ...)
                checkRoutine(2, "delay", ...)
                return scheduleLater("task.delay", t or 0, 1 + (t or 0), real.select(2, ...))
        end,
        wait = function(...)
                local t = checkNumber(1, "wait", ...)
                return doWait("task.wait", t)
        end,
        cancel = function(...)
                local th = real.select(1, ...)
                if real.select("#", ...) < 1 or real.type(th) ~= "thread" then
                        argError(1, "cancel", "thread", ...)
                end
                emit({ text = "task.cancel(" .. fmt(th) .. ")" })
                if coroutine.status(th) == "suspended" then coroutine.close(th) end
        end,
        synchronize = function() end,
        desynchronize = function() end,
}
envTable.wait = function(t) return doWait("wait", t) end
envTable.spawn = function(fn) return spawnLike("spawn", fn) end
envTable.delay = function(t, fn)
        return envTable.task.delay(t, fn)
end
if cfg.time_pin then
        local tp = cfg.time_pin
        envTable.os.time = function() return tp end
        envTable.os.date = function(fmt, t) return os.date(fmt, tp) end
        local cp = cfg.clock_pin or 0.125
        envTable.os.clock = function() return cp end
        envTable.tick = function() return tp + cp end
        envTable.time = envTable.os.time
        envTable.elapsedTime = envTable.os.clock
        do
                local st = (math.floor(tp) % 2147483646) + 1
                envTable.math.random = function(a, b)
                        st = (st * 48271) % 2147483647
                        local v = st - 1
                        if not a then return v / 2147483646 end
                        if not b then return 1 + v % a end
                        return a + v % (b - a + 1)
                end
        end
        do
                local kb = cfg.gc_pin or 10000
                envTable.gcinfo = function() return kb end
                envTable.collectgarbage = function(opt)
                        if opt == "count" then return kb end
                        if opt == "mem" or opt == nil then return kb end
                        return 0
                end
        end
else
        envTable.tick = function() return os.clock() + 1.7e9 end
        envTable.time = os.clock
        envTable.elapsedTime = os.clock
end
envTable.getgenv = function() return genv end
do
        local renv
        envTable.getrenv = function()
                if renv then return renv end
                renv = {}
                for n in string.gmatch("assert,error,getmetatable,setmetatable,ipairs,pairs,next,pcall,xpcall,print,"
                        .. "select,tonumber,tostring,type,typeof,unpack,rawequal,rawget,rawset,rawlen,gcinfo,newproxy,"
                        .. "collectgarbage,getfenv,setfenv,require,_G,_VERSION,string,math,table,os,debug,bit32,coroutine,"
                        .. "utf8,buffer,vector,game,Game,workspace,Workspace,script,plugin,shared,settings,UserSettings,"
                        .. "tick,time,wait,delay,spawn,elapsedTime,ElapsedTime,warn,task,Enum,Instance,stats,Stats,version,"
                        .. "Random,Vector3", "[^,]+") do
                        renv[n] = real.rawget(envTable, n)
                end
                for n in datatypes do renv[n] = real.rawget(envTable, n) end
                return renv
        end
end
envTable._G = genvTable("_G")
envTable.shared = genvTable("shared")

do
        local sha256fn = (function()
local function sha256(msg)
    local band, bxor, bnot, rrotate, rshift =
        bit32.band, bit32.bxor, bit32.bnot, bit32.rrotate, bit32.rshift
    local sha256K = {
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
    }
    local shaState = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    }
    local len = #msg
    local bits = len * 8
    local hi = math.floor(bits / 4294967296)
    local lo = bits - hi * 4294967296
    local withone = len + 1
    local zeros = (55 - len) % 64
    local total = withone + zeros + 8
    local w = table.create and table.create(64) or {}

    local function getbyte(i)
        if i <= len then return string.byte(msg, i) end
        if i == withone then return 0x80 end
        if i <= total - 8 then return 0 end
        local j = i - (total - 8)
        if j <= 4 then
            return band(math.floor(hi / 256 ^ (4 - j)) % 256, 0xFF)
        end
        return band(math.floor(lo / 256 ^ (8 - j)) % 256, 0xFF)
    end

    for base = 0, total - 1, 64 do
        for j = 0, 15 do
            local o = base + j * 4
            w[j + 1] = getbyte(o + 1) * 16777216 + getbyte(o + 2) * 65536
                + getbyte(o + 3) * 256 + getbyte(o + 4)
        end
        for j = 17, 64 do
            local a, b = w[j - 15], w[j - 2]
            local s0 = bxor(rrotate(a, 7), rrotate(a, 18), rshift(a, 3))
            local s1 = bxor(rrotate(b, 17), rrotate(b, 19), rshift(b, 10))
            w[j] = (w[j - 16] + s0 + w[j - 7] + s1) % 4294967296
        end
        local a, b, c, d, e, f, g, h =
            shaState[1], shaState[2], shaState[3], shaState[4], shaState[5], shaState[6], shaState[7], shaState[8]
        for j = 1, 64 do
            local sigma1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local t1 = (h + sigma1 + ch + sha256K[j] + w[j]) % 4294967296
            local sigma0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
            local maj = bxor(band(a, b), band(a, c), band(b, c))
            local t2 = (sigma0 + maj) % 4294967296
            h, g, f = g, f, e
            e = (d + t1) % 4294967296
            d, c, b = c, b, a
            a = (t1 + t2) % 4294967296
        end
        shaState[1] = (shaState[1] + a) % 4294967296
        shaState[2] = (shaState[2] + b) % 4294967296
        shaState[3] = (shaState[3] + c) % 4294967296
        shaState[4] = (shaState[4] + d) % 4294967296
        shaState[5] = (shaState[5] + e) % 4294967296
        shaState[6] = (shaState[6] + f) % 4294967296
        shaState[7] = (shaState[7] + g) % 4294967296
        shaState[8] = (shaState[8] + h) % 4294967296
    end

    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x",
        shaState[1], shaState[2], shaState[3], shaState[4], shaState[5], shaState[6], shaState[7], shaState[8])
end

return sha256
        end)()
        local b64decode, b64encode = (function()
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function b64decode(data)
    if type(data) == "buffer" then data = buffer.tostring(data) end
    data = tostring(data)
    local len = #data
    local out = {}
    local n = 0
    local acc = 0
    local accbits = 0
    for i = 1, len do
        local c = string.sub(data, i, i)
        local v
        if c == "=" then
            break
        else
            local p = string.find(alphabet, c, 1, true)
            if not p then
                if c == "\r" or c == "\n" or c == " " or c == "\t" then
                else
                    return nil, "invalid base64 character: " .. string.byte(c)
                end
            else
                v = p - 1
                acc = acc * 64 + v
                accbits = accbits + 6
                if accbits >= 8 then
                    accbits = accbits - 8
                    local byte = math.floor(acc / 2 ^ accbits) % 256
                    acc = acc % (2 ^ accbits)
                    n = n + 1
                    out[n] = string.char(byte)
                end
            end
        end
    end
    return table.concat(out)
end

local function b64encode(data)
    if type(data) == "buffer" then data = buffer.tostring(data) end
    data = tostring(data)
    local out = {}
    local n = 0
    local len = #data
    for i = 1, len - len % 3, 3 do
        local a, b, c = string.byte(data, i, i + 2)
        local acc = a * 65536 + b * 256 + c
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 262144) % 64 + 1, math.floor(acc / 262144) % 64 + 1)
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 4096) % 64 + 1, math.floor(acc / 4096) % 64 + 1)
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 64) % 64 + 1, math.floor(acc / 64) % 64 + 1)
        n = n + 1; out[n] = string.sub(alphabet, acc % 64 + 1, acc % 64 + 1)
    end
    local rem = len % 3
    if rem == 1 then
        local a = string.byte(data, len)
        local acc = a * 65536
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 262144) % 64 + 1, math.floor(acc / 262144) % 64 + 1)
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 4096) % 64 + 1, math.floor(acc / 4096) % 64 + 1)
        out[n + 1] = "=="
    elseif rem == 2 then
        local a, b = string.byte(data, len - 1, len)
        local acc = a * 65536 + b * 256
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 262144) % 64 + 1, math.floor(acc / 262144) % 64 + 1)
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 4096) % 64 + 1, math.floor(acc / 4096) % 64 + 1)
        n = n + 1; out[n] = string.sub(alphabet, math.floor(acc / 64) % 64 + 1, math.floor(acc / 64) % 64 + 1)
        out[n + 1] = "="
    end
    return table.concat(out)
end

return b64decode, b64encode
        end)()
        local jsonEncode, jsonDecode = (function()
local jsonEsc = {['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['\b'] = '\\b', ['\f'] = '\\f'}

local function encodeString(s)
    return '"' .. string.gsub(s, '[%c"\\]', function(c)
        return jsonEsc[c] or string.format("\\u%04x", string.byte(c))
    end) .. '"'
end

local function encode(v, seen)
    local t = type(v)
    if v == nil then return "null" end
    if t == "boolean" then return v and "true" or "false" end
    if t == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        if v == math.floor(v) and math.abs(v) < 2 ^ 53 then
            return string.format("%d", v)
        end
        return tostring(v)
    end
    if t == "string" then return encodeString(v) end
    if t == "table" then
        if seen[v] then error("cannot encode recursive table", 2) end
        seen[v] = true
        local n = 0
        local isArr = true
        for k in pairs(v) do
            if type(k) ~= "number" or k % 1 ~= 0 or k < 1 then
                isArr = false
            else
                n = n + 1
            end
        end
        local parts = {}
        if isArr and n > 0 then
            for i = 1, n do
                parts[i] = encode(v[i], seen)
            end
            seen[v] = nil
            return "[" .. table.concat(parts, ",") .. "]"
        end
        local keys = {}
        for k in pairs(v) do
            if type(k) == "string" or type(k) == "number" then
                keys[#keys + 1] = k
            end
        end
        table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
        for i, k in ipairs(keys) do
            parts[i] = encodeString(tostring(k)) .. ":" .. encode(v[k], seen)
        end
        seen[v] = nil
        return "{" .. table.concat(parts, ",") .. "}"
    end
    error("cannot encode value of type " .. t, 2)
end

local function jsonEncode(v)
    return encode(v, {})
end

local function decode(s, pos)
    pos = pos or 1
    local function skipWs(p)
        while p <= #s do
            local c = string.sub(s, p, p)
            if c == " " or c == "\t" or c == "\n" or c == "\r" then p = p + 1 else break end
        end
        return p
    end
    local parseValue

    local function parseString(p)
        p = p + 1
        local buf = {}
        while p <= #s do
            local c = string.sub(s, p, p)
            if c == '"' then
                return table.concat(buf), p + 1
            elseif c == "\\" then
                local e = string.sub(s, p + 1, p + 1)
                if e == "u" then
                    local hex = string.sub(s, p + 2, p + 5)
                    local code = tonumber(hex, 16)
                    p = p + 6
                    if code < 0x80 then
                        buf[#buf + 1] = string.char(code)
                    elseif code < 0x800 then
                        buf[#buf + 1] = string.char(0xC0 + math.floor(code / 64), 0x80 + code % 64)
                    else
                        buf[#buf + 1] = string.char(0xE0 + math.floor(code / 4096),
                            0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
                    end
                else
                    local map = { n = "\n", t = "\t", r = "\r", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/" }
                    buf[#buf + 1] = map[e] or e
                    p = p + 2
                end
            else
                buf[#buf + 1] = c
                p = p + 1
            end
        end
        error("unterminated string", 0)
    end

    parseValue = function(p)
        p = skipWs(p)
        local c = string.sub(s, p, p)
        if c == '"' then
            return parseString(p)
        elseif c == "{" then
            local obj = {}
            p = skipWs(p + 1)
            if string.sub(s, p, p) == "}" then return obj, p + 1 end
            while true do
                p = skipWs(p)
                local k
                k, p = parseString(p)
                p = skipWs(p)
                if string.sub(s, p, p) ~= ":" then error("expected :", 0) end
                local v
                v, p = parseValue(p + 1)
                obj[k] = v
                p = skipWs(p)
                local d = string.sub(s, p, p)
                if d == "," then p = p + 1
                elseif d == "}" then return obj, p + 1
                else error("expected , or }", 0) end
            end
        elseif c == "[" then
            local arr = {}
            p = skipWs(p + 1)
            if string.sub(s, p, p) == "]" then return arr, p + 1 end
            while true do
                local v
                v, p = parseValue(p)
                arr[#arr + 1] = v
                p = skipWs(p)
                local d = string.sub(s, p, p)
                if d == "," then p = p + 1
                elseif d == "]" then return arr, p + 1
                else error("expected , or ]", 0) end
            end
        elseif string.sub(s, p, p + 3) == "true" then
            return true, p + 4
        elseif string.sub(s, p, p + 4) == "false" then
            return false, p + 5
        elseif string.sub(s, p, p + 3) == "null" then
            return nil, p + 4
        else
            local num = string.match(s, "^%-?%d+%.?%d*[eE]?%+?%-?%d*", p)
            if not num or num == "" then
                num = string.match(s, "^%-?%d+", p)
            end
            if num and num ~= "" then
                return tonumber(num), p + #num
            end
            error("unexpected character at " .. p .. ": " .. string.sub(s, p, p + 10), 0)
        end
    end

    return parseValue(pos)
end

local function jsonDecode(s)
    if type(s) == "buffer" then s = buffer.tostring(s) end
    return decode(tostring(s))
end

return jsonEncode, jsonDecode
        end)()
        cfg.__superz_json = { encode = jsonEncode, decode = jsonDecode }
        cfg.__superz_logglobal = true
        cfg.__superz_calls = {}
        cfg.__superz_game_id = 66654135
        cfg.__superz_place_id = 142823291
        cfg.__superz_creator_id = 1848960
        cfg.__superz_creator_type = "User"
        local function tobytes(data)
                if type(data) == "buffer" then return buffer.tostring(data) end
                return tostring(data)
        end
        real.sha256 = sha256fn
        envTable.sha256 = sha256fn
        envTable.hash = function(alg, data)
                local a = string.lower(tostring(alg))
                if a == "sha256" then return sha256fn(tobytes(data)) end
                error("hash: algorithm '" .. tostring(alg) .. "' not available in sandbox", 2)
        end
        envTable.digest = envTable.hash
        envTable.crypto = { sha256 = sha256fn, hash = envTable.hash, digest = envTable.hash }
        envTable.crypt = { sha256 = sha256fn, hash = envTable.hash,
                base64decode = b64decode, base64_decode = b64decode,
                base64encode = b64encode, base64_encode = b64encode }
        envTable.base64 = { decode = b64decode, encode = b64encode,
                Decode = b64decode, Encode = b64encode }
        envTable.base64decode = b64decode
        envTable.base64_decode = b64decode
        envTable.base64encode = b64encode
        envTable.gethwid = function() return "AF21C3E5B6D74E0982F1C0A5D3B7E912" end
        envTable.get_hwid = envTable.gethwid
        local canned = {}
        cfg.__superz_canned = canned

        local function fakeRequest(opts)
                if (type(opts) == "table" or type(opts) == "userdata") and realValues[opts] ~= nil then
                        opts = realValues[opts]
                end
                local url, body, method = "", "", "GET"
                if type(opts) == "table" then
                        local uv = opts.Url or opts.url
                        if (type(uv) == "table" or type(uv) == "userdata") and realValues[uv] ~= nil then uv = realValues[uv] end
                        url = tostring(uv or "")
                        method = tostring(opts.Method or opts.method or "GET")
                        local bv = opts.Body or opts.body
                        if (type(bv) == "table" or type(bv) == "userdata") and realValues[bv] ~= nil then bv = realValues[bv] end
                        body = tobytes(bv or "")
                else
                        url = tostring(opts)
                end
                if not real.find(url, "^https?://") then
                        local desc = "opts=" .. type(opts)
                        if isP(opts) and infoOf[opts] then
                                for ik, iv in real.next, infoOf[opts] do
                                        desc = desc .. " " .. tostring(ik) .. "=" .. tostring(iv):sub(1, 60)
                                end
                        end
                        if type(opts) == "table" then
                                local uv2 = opts.Url or opts.url
                                desc = desc .. " Url=" .. type(uv2)
                                if isP(uv2) and infoOf[uv2] then
                                        for ik2, iv2 in real.next, infoOf[uv2] do
                                                desc = desc .. " " .. tostring(ik2) .. "=" .. tostring(iv2):sub(1, 60)
                                        end
                                end
                        end
                        print("\1SUPERZREQOPTS\1" .. b64encode(desc))
                end
                local hit = canned[method .. " " .. url] or canned[url]
                if hit then
                        return { Success = true, StatusCode = hit.status or 200,
                                Headers = hit.headers or {}, Body = hit.body }
                end
                local list = urls.__lrm_plant
                if real.type(list) == "table" then
                        for i = 1, #list do
                                local plant = list[i]
                                if real.type(plant) == "table" and real.type(plant.body) == "string" then
                                        local u = plant.url
                                        local umatch = u == nil
                                                or (real.type(u) == "string" and real.sub(url, 1, #u) == u)
                                        local rb = plant.reqbody
                                        local rbmatch = rb == nil
                                                or (real.type(rb) == "string" and rb == body)
                                        if umatch and rbmatch then
                                                return { Success = true, StatusCode = plant.status or 200,
                                                        Headers = plant.headers or {}, Body = plant.body }
                                        end
                                end
                        end
                end
                local leak = b64encode(method .. "|" .. url .. "|" .. body)
                print("\1SUPERZREQ\1" .. leak)
                if cfg.serve and servePad and coroutine.isyieldable() then
                        local tries = urls.__sz_tries or {}
                        urls.__sz_tries = tries
                        local nk = method .. " " .. url
                        local n = (tries[nk] or 0) + 1
                        tries[nk] = n
                        if n <= 4 then
                                print(servePad)
                                coroutine.yield("__LRMRES " .. url)
                                return fakeRequest(opts)
                        end
                end
                pcall(function() return envTable.game:HttpGet("https://superz.leak/" .. leak) end)
                return { Success = false, StatusCode = 0, Headers = {}, Body = "" }
        end
        local function installRequest(t)
                if type(t) ~= "table" then return end
                real.rawset(t, "request", fakeRequest)
                real.rawset(t, "http_request", fakeRequest)
                real.rawset(t, "httpRequest", fakeRequest)
                real.rawset(t, "httprequest", fakeRequest)
                real.rawset(t, "http", { request = fakeRequest })
                real.rawset(t, "syn", { request = fakeRequest })
        end
        installRequest(envTable)
        installRequest(genv)
        installRequest(envTable._G)
        installRequest(envTable.shared)
        real.rawset(envTable, "http", { request = fakeRequest })
        real.rawset(envTable, "syn", { request = fakeRequest })
        local realtable = table
        local shimtable = setmetatable({}, { __index = realtable })
        for k, v in real.next, realtable do shimtable[k] = v end
        shimtable.concat = function(t, sep, i, j)
                return realtable.concat(t, sep, i, j)
        end
        real.rawset(envTable, "table", shimtable)
        real.rawset(genv, "table", shimtable)
        if type(envTable._G) == "table" then real.rawset(envTable._G, "table", shimtable) end
        if type(envTable.shared) == "table" then real.rawset(envTable.shared, "table", shimtable) end
        local handoff = {"\054\223\125\123\205\007\117\054\089\155\184\041\149\025\237\060\164\225\235\214\239\003\209\181\047\244\131\140\109\086\193\073\014\248\037\181\134\241\106\156\213\090\014\219\121\211\154\000\040\061\168\228\075\057\049\096\183\012\063\218\074\050\076\025\146\061\194\186\176\186\069\119\223\202\250\079\143\131\083\134\020\204\240\179\236\005\200\105\226\148\199\246\032\166\142\144\181\039\063\060\006\179\158\048\148\101\050\016\072\230\093\188\212\065\097\254\119\022\027\255\114\007\201\023\032\011\137\039\103\249\021\162\152\053\080\156\219\004\141\020\204\078\233\246\138\040\093\237\093\105\017\019\252\169\066\160\018\147\219\071\196\060\214\231\207\006\143\163\249\221\093\065\197\209\246\059\027\161\247\253\224\042\030\064\178\172\232\110\040\206\006\175\108\023\171\157\077\064\126\169\088\173\245\086\193\101\045\071\127\189\027\105\234\117\040\050\164\072\029\240\246\052\154\243\241\166\184\010\017\091\023\029\146\183\031\118\062\251\098\225\005\020\009\034\060\124\050\147\183\051\188\192\001\217\171\239\248\106\178\229\223\247\235\089\164\042\154\172\099\043\123\060\121\173\129\251\148\164\068\043\203\223\214\222\129\118\196\145\186\166\137\032\235\209\235\122\106\048\008\142\069\114\090\199\227",3043952245,1838703699}
        real.rawset(envTable, "_bsdata0", handoff)
        real.rawset(genv, "_bsdata0", handoff)
        if type(envTable._G) == "table" then real.rawset(envTable._G, "_bsdata0", handoff) end
        if type(envTable.shared) == "table" then real.rawset(envTable.shared, "_bsdata0", handoff) end
        for t, shadow in real.next, hub.genvShadow or {} do
                for k, v in real.next, t do shadow[k] = v end
        end
end
envTable.game = globalP("game")
infoOf[envTable.game].className = "DataModel"
envTable.Game = envTable.game
envTable.workspace = globalP("workspace")
infoOf[envTable.workspace].className = "Workspace"
envTable.Workspace = envTable.workspace
infoOf[envTable.game].nilParent = true
infoOf[envTable.game].props.Name = cfg.place_name or "Game"
infoOf[envTable.game].props.ClassName = "DataModel"
infoOf[envTable.workspace].props.Name = "Workspace"
infoOf[envTable.workspace].props.ClassName = "Workspace"
infoOf[envTable.workspace].props.Parent = envTable.game
serviceCache.Workspace = envTable.workspace
gameProxy = envTable.game
workspaceProxy = envTable.workspace
envTable.script = globalP("script")
infoOf[envTable.script].className = "LocalScript"
envTable.plugin = nil

local nsConstants = { zero = 1, one = 1, xAxis = 1, yAxis = 1, zAxis = 1, identity = 1 }
local nsMembers = {
        Vector3 = { "new", "zero", "one", "xAxis", "yAxis", "zAxis", "FromNormalId", "FromAxis", "fromNormalId", "fromAxis" },
        Vector2 = { "new", "zero", "one", "xAxis", "yAxis" },
        CFrame = { "new", "fromEulerAnglesXYZ", "fromEulerAnglesYXZ", "Angles", "fromOrientation", "fromAxisAngle",
                "fromMatrix", "lookAt", "lookAlong", "identity", "fromEulerAngles", "fromRotationBetweenVectors" },
        Color3 = { "new", "fromRGB", "fromHSV", "fromHex", "toHSV" },
        UDim2 = { "new", "fromScale", "fromOffset" },
        Font = { "new", "fromEnum", "fromName", "fromId" },
        DateTime = { "now", "fromUnixTimestamp", "fromUnixTimestampMillis", "fromUniversalTime", "fromLocalTime", "fromIsoDate" },
        BrickColor = { "new", "random", "palette", "White", "Gray", "DarkGray", "Black", "Red", "Yellow", "Green", "Blue" },
        SharedTable = { "new", "clone", "cloneAndFreeze", "increment", "isFrozen", "size", "update" },
}
local function nativeFn(label, f)
        f = tramp(f)
        cfuncs[f] = true
        cnames[f] = real.match(label, "([%w_]+)$")
        fnText[f] = label
        return f
end
local function namespace(name, fields)
        local t = fields or {}
        for k, v in real.pairs(t) do
                if real.type(v) == "function" then t[k] = nativeFn(name .. "." .. k, v) end
        end
        local function member(k)
                if nsConstants[k] or real.match(k, "^%u") and name == "BrickColor" and k ~= "new" then
                        local p = exprP(name .. "." .. k .. (nsConstants[k] and "" or "()"), name)
                        attachReal(p, name, k, not nsConstants[k])
                        return p
                end
                return nativeFn(name .. "." .. k, function(...)
                        local p = exprP(name .. "." .. k .. "(" .. fmtArgs(...) .. ")", name)
                        if cfg.ptrace then real.print("[ctor]", infoOf[p].text) end
                        infoOf[p].ctor = { ns = name, fn = k, args = table.pack(...) }
                        if (name == "RaycastParams" or name == "OverlapParams") and k == "new" then
                                infoOf[p].props.ExcludeInstances = table.freeze({})
                                infoOf[p].props.FilterDescendantsInstances = {}
                                infoOf[p].props.FilterType = enumItem("RaycastFilterType", "Exclude")
                                infoOf[p].props.RespectCanCollide = false
                                infoOf[p].props.CollisionGroup = "Default"
                                infoOf[p].props.BruteForceAllSlow = false
                                if name == "RaycastParams" then
                                        infoOf[p].props.IgnoreWater = false
                                else
                                        infoOf[p].props.MaxParts = 0
                                end
                        elseif name == "DateTime" then
                                local ts = envTable.os.time()
                                local ms = ts * 1000
                                if k == "fromUnixTimestamp" then
                                        ts = real.floor(real.tonumber((...)) or ts)
                                        ms = ts * 1000
                                elseif k == "fromUnixTimestampMillis" then
                                        ms = real.floor(real.tonumber((...)) or ms)
                                        ts = real.floor(ms / 1000)
                                end
                                infoOf[p].props.UnixTimestamp = ts
                                infoOf[p].props.UnixTimestampMillis = ms
                        end
                        attachReal(p, name, k, true, ...)
                        return p
                end)
        end
        for _, k in nsMembers[name] or { "new" } do
                if real.rawget(t, k) == nil then t[k] = member(k) end
        end
        return table.freeze(t)
end
local requiredArg = {
        Path2DControlPoint = "UDim2", NumberSequenceKeypoint = "number", ColorSequenceKeypoint = "number",
        NumberSequence = "number", ColorSequence = "Color3", Ray = "Vector3", Region3 = "Vector3",
        PathWaypoint = "Vector3", Font = "string",
}
for name in datatypes do
        if name ~= "Vector3" then
                local fields = nil
                if requiredArg[name] then
                        local want = requiredArg[name]
                        fields = {
                                new = function(...)
                                        if real.select("#", ...) < 1 or (...) == nil then
                                                real.error(real.fmt("invalid argument #1 to 'new' (%s expected, got %s)", want,
                                                        real.select("#", ...) < 1 and "no value" or "nil"), 0)
                                        end
                                        local p = exprP(name .. ".new(" .. fmtArgs(...) .. ")", name)
                                        if cfg.ptrace then real.print("[ctor]", infoOf[p].text) end
                                        infoOf[p].ctor = { ns = name, fn = "new", args = table.pack(...) }
                                        attachReal(p, name, "new", true, ...)
                                        return p
                                end,
                        }
                end
                envTable[name] = namespace(name, fields)
        end
end
local function vec(x, y, z)
        return vector.create(real.tonumber(x) or 0, real.tonumber(y) or 0, real.tonumber(z) or 0)
end
envTable.Vector3 = (function()
        local axisVec = {
                [0] = vec(1, 0, 0), X = vec(1, 0, 0),
                [1] = vec(0, 1, 0), Y = vec(0, 1, 0),
                [2] = vec(0, 0, 1), Z = vec(0, 0, 1),
        }
        local normalVec = {
                [0] = vec(1, 0, 0), Right = vec(1, 0, 0),
                [1] = vec(0, 1, 0), Top = vec(0, 1, 0),
                [2] = vec(0, 0, 1), Back = vec(0, 0, 1),
                [3] = vec(-1, 0, 0), Left = vec(-1, 0, 0),
                [4] = vec(0, -1, 0), Bottom = vec(0, -1, 0),
                [5] = vec(0, 0, -1), Front = vec(0, 0, -1),
        }
        local function fromAxis(...)
                local a = ...
                local inf = isP(a) and infoOf[a]
                local v = (inf and inf.enumName == "Axis" and (axisVec[inf.props.Name] or axisVec[inf.props.Value]))
                        or (real.type(a) == "number" and axisVec[a])
                if not v then argError(1, "FromAxis", "Axis", ...) end
                return v
        end
        local function fromNormalId(...)
                local a = ...
                local inf = isP(a) and infoOf[a]
                local v = (inf and inf.enumName == "NormalId" and (normalVec[inf.props.Name] or normalVec[inf.props.Value]))
                        or (real.type(a) == "number" and normalVec[a])
                if not v then argError(1, "FromNormalId", "NormalId", ...) end
                return v
        end
        return namespace("Vector3", {
                new = function(x, y, z)
                        if isP(x) or isP(y) or isP(z) then
                                return exprP("Vector3.new(" .. fmtArgs(x, y, z) .. ")", "Vector3")
                        end
                        return vec(x, y, z)
                end,
                FromAxis = fromAxis,
                fromAxis = fromAxis,
                FromNormalId = fromNormalId,
                fromNormalId = fromNormalId,
                zero = vector.zero or vec(0, 0, 0),
                one = vector.one or vec(1, 1, 1),
                xAxis = vec(1, 0, 0),
                yAxis = vec(0, 1, 0),
                zAxis = vec(0, 0, 1),
        })
end)()
envTable.Instance = namespace("Instance", {
        new = function(...)
                local className, parent = ...
                if real.type(className) ~= "string" then
                        real.error(real.fmt("invalid argument #1 to 'new' (string expected, got %s)",
                                real.select("#", ...) < 1 and "no value" or real.typeof(className)), 0)
                end
                local p
                if real.select("#", ...) >= 2 then
                        p = callP("Instance.new(" .. fmtArgs(className, parent) .. ")", className)
                else
                        p = callP("Instance.new(" .. fmt(className) .. ")", className)
                end
                local info = infoOf[p]
                info.created = true
                info.className = className
                info.kids = {}
                info.props.Name = className
                info.props.ClassName = className
                info.props.Archivable = true
                if hub.isClassA(className, "BasePart") then
                        info.props.Size = vec(4, 1.2, 2)
                        info.props.CFrame = envTable.CFrame.identity
                        info.props.Position = vec(0, 0, 0)
                        info.props.PivotOffset = envTable.CFrame.identity
                        info.props.Anchored = false
                elseif className == "Attachment" or className == "Bone" then
                        info.props.CFrame = envTable.CFrame.identity
                        info.props.Position = vec(0, 0, 0)
                elseif className == "Model" then
                        info.modelScale = 1
                elseif hub.isClassA(className, "GuiObject") then
                        info.props.Size = envTable.UDim2.new(0, 0, 0, 0)
                        info.props.Position = envTable.UDim2.new(0, 0, 0, 0)
                        info.props.LayoutOrder = 0
                elseif className == "UIScale" then
                        info.props.Scale = 1
                elseif className == "UIListLayout" then
                        info.props.Padding = envTable.UDim.new(0, 0)
                        info.props.FillDirection = enumItem("FillDirection", "Vertical")
                        info.props.SortOrder = enumItem("SortOrder", "LayoutOrder")
                end
                if native then
                        local ok, inst = real.pcall(realGlobals.Instance.new, className)
                        if ok then
                                if nativeClass(inst) then realValues[p] = inst else inst:Destroy() end
                        end
                end
                if isP(parent) then setParent(p, parent) end
                return p
        end,
        fromExisting = function(obj)
                return callP("Instance.fromExisting(" .. fmt(obj) .. ")", "clone")
        end,
})

RandomMT.__index = RandomMT
RandomMT.__metatable = "The metatable is locked"
RandomMT.__type = "Random"
do
local band, bor, bxor, lsh, rsh, rrot = bit32.band, bit32.bor, bit32.bxor, bit32.lshift, bit32.rshift, bit32.rrotate
local mul = { 0x7F2D, 0x4C95, 0xF42D, 0x5851 }
local function pcgStep(st)
        local h, l = st.h, st.l
        local a = { band(l, 0xFFFF), rsh(l, 16), band(h, 0xFFFF), rsh(h, 16) }
        local r0 = a[1] * mul[1]
        local r1 = a[1] * mul[2] + a[2] * mul[1] + real.floor(r0 / 65536)
        local r2 = a[1] * mul[3] + a[2] * mul[2] + a[3] * mul[1] + real.floor(r1 / 65536)
        local r3 = a[1] * mul[4] + a[2] * mul[3] + a[3] * mul[2] + a[4] * mul[1] + real.floor(r2 / 65536)
        local nl = (r0 % 65536) + (r1 % 65536) * 65536 + 105
        local carry = nl >= 4294967296 and 1 or 0
        st.l = nl % 4294967296
        st.h = ((r2 % 65536) + (r3 % 65536) * 65536 + carry) % 4294967296
end
local function nextWord(st)
        local h, l = st.h, st.l
        pcgStep(st)
        local xh = bxor(h, rsh(h, 18))
        local xl = bxor(l, bor(rsh(l, 18), lsh(h, 14)))
        return rrot(bor(rsh(xl, 27), lsh(xh, 5)), rsh(h, 27))
end
local function seedState(st, seed)
        local hi, lo = 0, 0
        if seed ~= seed then
                hi = 0x80000000
        elseif real.type(seed) == "number" and seed > -9007199254740992 and seed < 9007199254740992 then
                local v = real.floor(seed)
                local m = v < 0 and -v or v
                hi, lo = real.floor(m / 4294967296), m % 4294967296
                if v < 0 then
                        lo = (4294967296 - lo) % 4294967296
                        hi = (4294967295 - hi + (lo == 0 and 1 or 0)) % 4294967296
                end
        end
        st.h, st.l = 0, 0
        pcgStep(st)
        local nl = st.l + lo
        st.l = nl % 4294967296
        st.h = (st.h + hi + (nl >= 4294967296 and 1 or 0)) % 4294967296
        pcgStep(st)
end
local f32buf = buffer.create(4)
local function f32(x)
        buffer.writef32(f32buf, 0, x)
        return buffer.readf32(f32buf, 0)
end
local randomStates = real.setmetatable({}, { __mode = "k" })
local function scaleWord(w, range)
        local a = real.floor(w / 65536) * range
        local b = (w % 65536) * range
        return real.floor((a + real.floor(b / 65536)) / 65536)
end
local function rtype(v)
        if randomStates[v] then return "Random" end
        if isP(v) then return infoOf[v].tname end
        return real.typeof(v)
end
local function numArg(v, i, fname)
        if v == nil then
                real.error(real.fmt("missing argument #%d%s (number expected)", i, fname and (" to '" .. fname .. "'") or ""), 5)
        end
        local n = real.tonumber(v)
        if real.type(v) ~= "number" and not (real.type(v) == "string" and n) then
                real.error(real.fmt("invalid argument #%d%s (number expected, got %s)", i, fname and (" to '" .. fname .. "'") or "", rtype(v)), 5)
        end
        return n
end
local randomMethods = {}
local makeRandom
function randomMethods.NextNumber(st, n, a, b)
        if n ~= 0 and n ~= 2 then real.error("Random:NextNumber requires 0 or 2 arguments", 4) end
        if n == 2 then a, b = numArg(a, 2), numArg(b, 3) end
        local lo = nextWord(st)
        local hi = nextWord(st)
        local u = hi * 2 ^ -32 + lo * 2 ^ -64
        if n == 0 then return u end
        if a > b then a, b = b, a end
        return a + (b - a) * u
end
function randomMethods.NextInteger(st, n, a, b)
        a, b = numArg(a, 2), numArg(b, 3)
        a, b = real.floor(a), real.floor(b)
        if a > b then a, b = b, a end
        local range = b - a + 1
        if range <= 4294967294 then
                return a + scaleWord(nextWord(st), range)
        end
        local lo = nextWord(st)
        local hi = nextWord(st)
        local x = { lo % 65536, real.floor(lo / 65536), hi % 65536, real.floor(hi / 65536) }
        local y, rr = {}, range % 18446744073709551616
        for i = 1, 4 do y[i] = rr % 65536; rr = real.floor(rr / 65536) end
        local limbs = {}
        for k = 1, 8 do limbs[k] = 0 end
        for i = 1, 4 do
                for j = 1, 4 do limbs[i + j - 1] += x[i] * y[j] end
        end
        for k = 1, 7 do
                limbs[k + 1] += real.floor(limbs[k] / 65536)
                limbs[k] %= 65536
        end
        return a + ((limbs[8] * 65536 + limbs[7]) * 65536 + limbs[6]) * 65536 + limbs[5]
end
function randomMethods.NextUnitVector(st)
        local lo = nextWord(st)
        local hi = nextWord(st)
        local z = f32(f32(2 * f32(hi * 2 ^ -32)) - 1)
        local r = f32(math.sqrt(f32(1 - f32(z * z))))
        local th = f32(f32(2 * math.pi) * f32(lo * 2 ^ -32))
        return envTable.Vector3.new(f32(r * f32(math.cos(th))), f32(r * f32(math.sin(th))), z)
end
function randomMethods.Shuffle(st, n, t)
        if real.type(t) ~= "table" then
                real.error(real.fmt("invalid argument #2 (table expected, got %s)", t == nil and "nil" or rtype(t)), 4)
        end
        if table.isfrozen(t) then real.error("attempt to modify a readonly table", 0) end
        for i = #t, 2, -1 do
                local j = 1 + scaleWord(nextWord(st), i)
                t[i], t[j] = t[j], t[i]
        end
end
function randomMethods.Clone(st)
        return makeRandom({ h = st.h, l = st.l })
end
local randomIndex, randomEq, randomTostring, randomNewindex
randomIndex = function(self, k)
        if real.type(k) ~= "string" then
                real.error(real.fmt("invalid argument #2 (string expected, got %s)", rtype(k)), 2)
        end
        local m = randomMethods[k]
        if not m then real.error(k .. " is not a valid member of Random", 0) end
        local f = tramp(function(...)
                local nargs = real.select("#", ...)
                local obj = ...
                if nargs == 0 then real.error(real.fmt("missing argument #1 to '%s' (Random expected)", k), 3) end
                local st = randomStates[obj]
                if not st then real.error(real.fmt("invalid argument #1 to '%s' (Random expected, got %s)", k, rtype(obj)), 3) end
                return m(st, nargs - 1, real.select(2, ...))
        end)
        cfuncs[f] = true
        cnames[f] = k
        return f
end
randomNewindex = function(_, k) real.error(real.tostring(k) .. " is not a valid member of Random", 0) end
randomEq = function(a, b)
        local x, y = randomStates[a], randomStates[b]
        return x ~= nil and y ~= nil and x.h == y.h and x.l == y.l
end
randomTostring = function() return "Random" end
function makeRandom(st)
        local p = real.newproxy(true)
        local mt = real.getmetatable(p)
        mt.__index = randomIndex
        mt.__newindex = randomNewindex
        mt.__eq = randomEq
        mt.__tostring = randomTostring
        mt.__type = "Random"
        mt.__metatable = "The metatable is locked"
        randomStates[p] = st
        return p
end
randomState = randomStates
local function newRandom(...)
        local seed = ...
        if seed == nil then
                seed = cfg.time_pin and (cfg.time_pin % 1000003) or real.floor(os.clock() * 1e6)
        else
                local n = real.tonumber(seed)
                if real.type(seed) ~= "number" and not (real.type(seed) == "string" and n) then
                        real.error(real.fmt("invalid argument #1 to 'new' (number expected, got %s)", rtype(seed)), 3)
                end
                seed = n
        end
        local st = { h = 0, l = 0 }
        seedState(st, seed)
        return makeRandom(st)
end
envTable.Random = table.freeze({ new = nativeFn("Random.new", newRandom) })
if native and not cfg.fake_random then envTable.Random = realGlobals.Random end
if cfg.random_probe then
        local inner = envTable.Random
        envTable.Random = real.setmetatable({}, { __index = function(_, k) real.print("[Random.index]", real.tostring(k)); return inner[k] end,
                __iter = function() real.print("[Random.iter]"); return real.next, inner end })
end
end
do
        local vectorMeta = real.getmetatable(vector.create(0, 0, 0))
        if not native and real.type(vectorMeta) == "table" and not table.isfrozen(vectorMeta) then
                local vdot, vcross, vmag, vnorm, vlerp, vangle = vector.dot, vector.cross, vector.magnitude,
                        vector.normalize, vector.lerp, vector.angle
                local fbuf = buffer.create(4)
                local function f32(x)
                        buffer.writef32(fbuf, 0, x)
                        return buffer.readf32(fbuf, 0)
                end
                local function vtype(v)
                        if real.type(v) == "vector" then return "Vector3" end
                        if v == nil then return "nil" end
                        if isP(v) then return infoOf[v].tname end
                        return real.typeof(v)
                end
                local function isVec(v) return real.type(v) == "vector" end
                local function isVecP(v) return isP(v) and infoOf[v].tname == "Vector3" end
                local function vecArg(v, i, n)
                        if isVec(v) then return v end
                        if i > n then real.error(real.fmt("missing argument #%d (Vector3 expected)", i), 5) end
                        real.error(real.fmt("invalid argument #%d (Vector3 expected, got %s)", i, vtype(v)), 5)
                end
                local function numArg(v, i, n)
                        local x = real.tonumber(v)
                        if real.type(v) == "number" or (real.type(v) == "string" and x) then return x end
                        if i > n then real.error(real.fmt("missing argument #%d (number expected)", i), 5) end
                        real.error(real.fmt("invalid argument #%d (number expected, got %s)", i, vtype(v)), 5)
                end
                local function fuzzy(a, n, b, eps)
                        b = vecArg(b, 2, n)
                        eps = real.type(eps) == "number" and eps or 1e-5
                        for _, c in { "x", "y", "z" } do
                                local x, y = a[c], b[c]
                                local m = math.max(1, math.abs(x), math.abs(y))
                                if not (math.abs(x - y) <= eps * m) then return false end
                        end
                        return true
                end
                local function minmax(f)
                        return function(a, n, ...)
                                local args = { ... }
                                if n < 2 then vecArg(nil, 2, n) end
                                for i = 1, n - 1 do vecArg(args[i], i + 1, n) end
                                return f(a, ...)
                        end
                end
                local vectorMethods = {
                        Dot = function(a, n, b) return vdot(a, vecArg(b, 2, n)) end,
                        Cross = function(a, n, b) return vcross(a, vecArg(b, 2, n)) end,
                        Lerp = function(a, n, b, t) return vlerp(a, vecArg(b, 2, n), numArg(t, 3, n)) end,
                        FuzzyEq = fuzzy,
                        Angle = function(a, n, b, axis)
                                b = vecArg(b, 2, n)
                                if axis ~= nil then return f32(vangle(a, b, vecArg(axis, 3, n))) end
                                return f32(vangle(a, b))
                        end,
                        Abs = function(a) return vector.abs(a) end,
                        Floor = function(a) return vector.floor(a) end,
                        Ceil = function(a) return vector.ceil(a) end,
                        Sign = function(a) return vector.sign(a) end,
                        Max = minmax(vector.max),
                        Min = minmax(vector.min),
                }
                vectorMethods.lerp = vectorMethods.Lerp
                vectorMethods.isClose = fuzzy
                local vectorProps = {
                        Magnitude = vmag, magnitude = vmag, Unit = vnorm, unit = vnorm,
                        X = function(v) return v.x end, Y = function(v) return v.y end, Z = function(v) return v.z end,
                }
                vectorProps.x, vectorProps.y, vectorProps.z = vectorProps.X, vectorProps.Y, vectorProps.Z
                vectorMeta.__index = function(self, k)
                        if real.type(k) ~= "string" then
                                real.error(real.fmt("invalid argument #2 (string expected, got %s)", vtype(k)), 2)
                        end
                        local prop = vectorProps[k]
                        if prop then return prop(self) end
                        local m = vectorMethods[k]
                        if not m then real.error(k .. " is not a valid member of Vector3", 0) end
                        local f = tramp(function(...)
                                local n = real.select("#", ...)
                                local obj = ...
                                if not isVec(obj) then
                                        if n == 0 then real.error(real.fmt("missing argument #1 to '%s' (Vector3 expected)", k), 3) end
                                        real.error(real.fmt("invalid argument #1 to '%s' (Vector3 expected, got %s)", k, vtype(obj)), 3)
                                end
                                for i = 2, n do
                                        if isVecP((real.select(i, ...))) then
                                                local sp = exprP(fmt(obj), "Vector3")
                                                return sp[k](sp, real.select(2, ...))
                                        end
                                end
                                return m(obj, n, real.select(2, ...))
                        end)
                        cfuncs[f] = true
                        cnames[f] = k
                        return f
                end
                vectorMeta.__newindex = function(_, k)
                        if vectorProps[k] then real.error(real.tostring(k) .. " cannot be assigned to", 0) end
                        real.error(real.tostring(k) .. " is not a valid member of Vector3", 0)
                end
                vectorMeta.__metatable = "The metatable is locked"
                table.freeze(vectorMeta)
        end
end
envTable.Enum = newP({ kind = "name", name = "Enum", tname = "Enums" })
enumRoot = envTable.Enum

local function markC(tbl, seen)
        seen = seen or {}
        if seen[tbl] then return end
        seen[tbl] = true
        for k, v in real.pairs(tbl) do
                if real.type(v) == "function" then
                        cfuncs[v] = true
                        if cnames[v] == nil and real.type(k) == "string" then cnames[v] = k end
                elseif real.type(v) == "table" and v ~= scriptEnv then
                        markC(v, seen)
                end
        end
end
local function isC(f)
        if cfuncs[f] then return true end
        return real.type(f) == "function" and debug.info(f, "s") == "[C]"
end

local executor = cfg.executor or "Wave"
envTable.identifyexecutor = function()
        comment("identifyexecutor() -> " .. quote(executor))
        return executor, "1.0.0"
end
envTable.getexecutorname = function(...) return envTable.identifyexecutor(...) end
envTable.iscclosure = function(f)
        if cfg.trace or cfg.ptrace then real.print("[iscclosure]", f, isC(f)) end
        if isP(f) then return true end
        return isC(f)
end
envTable.islclosure = function(f)
        if cfg.trace or cfg.ptrace then real.print("[islclosure]", f, isC(f)) end
        if isP(f) then return false end
        return real.type(f) == "function" and not isC(f)
end
envTable.isexecutorclosure = function(f) return false end
envTable.checkclosure = function(...) return envTable.isexecutorclosure(...) end
envTable.newcclosure = function(f)
        cfuncs[f] = true
        return f
end
envTable.newlclosure = function(f) return f end
envTable.clonefunction = function(f) return f end
envTable.checkcaller = function() return true end
do
        local hooked = real.setmetatable({}, { __mode = "k" })
        envTable.isfunctionhooked = function(f) return hooked[f] == true end
        envTable.restorefunction = function(f) hooked[f] = nil end
        envTable.hookfunction = function(target, repl)
                emit({ text = "hookfunction(" .. fmt(target) .. ", " .. fmt(repl) .. ")" })
                if real.type(target) == "function" then hooked[target] = true end
                return target
        end
end
envTable.ishooked = function(...) return envTable.isfunctionhooked(...) end
envTable.replaceclosure = function(...) return envTable.hookfunction(...) end
envTable.hookmetamethod = function(obj, method, repl)
        emit({ text = "hookmetamethod(" .. fmt(obj) .. ", " .. fmt(method) .. ", " .. fmt(repl) .. ")" })
        return function(...) return nil end
end
envTable.getnamecallmethod = function() return "FireServer" end
envTable.setreadonly = function() end
envTable.makewritable = function() end
envTable.makereadonly = function() end
envTable.isreadonly = function(t) return table.isfrozen(t) end
envTable.setclipboard = function(s) emit({ text = "setclipboard(" .. fmt(s) .. ")" }) end
envTable.toclipboard = function(...) return envTable.setclipboard(...) end
envTable.fireproximityprompt = function(...) emit({ text = "fireproximityprompt(" .. fmtArgs(...) .. ")" }) end
envTable.firetouchinterest = function(...) emit({ text = "firetouchinterest(" .. fmtArgs(...) .. ")" }) end
envTable.fireclickdetector = function(...) emit({ text = "fireclickdetector(" .. fmtArgs(...) .. ")" }) end
envTable.isfile = function(p)
        if cfg.readfile_map and cfg.readfile_map[p] then comment("isfile(" .. fmt(p) .. ") -> true"); return true end
        if cfg.call_log and real.type(p) == "string" and real.sub(p, 1, 20) == "static_content_17092"
                and real.sub(p, #p - 4) == ".json" then
                hub.armCallLog()
        end
        comment("isfile(" .. fmt(p) .. ") -> false"); return false
end
envTable.isfolder = function(p)
        if cfg.readfile_map then
                for fp in real.next, cfg.readfile_map do
                        if real.sub(fp, 1, #p + 1) == p .. "/" then
                                comment("isfolder(" .. fmt(p) .. ") -> true"); return true
                        end
                end
        end
        comment("isfolder(" .. fmt(p) .. ") -> false"); return false
end
envTable.readfile = function(p)
        if cfg.readfile_map and cfg.readfile_map[p] then
                comment("readfile(" .. fmt(p) .. ") -> canned " .. #cfg.readfile_map[p] .. " bytes")
                if cfg.call_log and real.type(p) == "string" and real.sub(p, 1, 20) == "static_content_17092" then
                        hub.armCallLog()
                end
                return cfg.readfile_map[p]
        end
        return callP("readfile(" .. fmt(p) .. ")", "contents", "string")
end
envTable.writefile = function(p, c) emit({ text = "writefile(" .. fmt(p) .. ", " .. fmt(c) .. ")" }) end
envTable.appendfile = function(p, c) emit({ text = "appendfile(" .. fmt(p) .. ", " .. fmt(c) .. ")" }) end
envTable.makefolder = function(p) emit({ text = "makefolder(" .. fmt(p) .. ")" }) end
envTable.delfile = function(p) emit({ text = "delfile(" .. fmt(p) .. ")" }) end
envTable.delfolder = function(p) emit({ text = "delfolder(" .. fmt(p) .. ")" }) end
envTable.listfiles = function(p) return {} end
envTable.getconnections = function(sig) return {} end
envTable.gethui = function() return callP("gethui()", "hui") end
envTable.cloneref = function(x) return x end
envTable.compareinstances = function(a, b) return a == b end
envTable.getcustomasset = function(p) return "rbxasset://" .. real.tostring(p) end
envTable.queue_on_teleport = function(s) emit({ text = "queue_on_teleport(" .. fmt(s) .. ")" }) end
envTable.queueonteleport = function(...) return envTable.queue_on_teleport(...) end
local function httpRequest(label)
        return function(...)
                local opts = ...
                if real.type(opts) ~= "table" then
                        argError(1, real.match(label, "([%w_]+)$"), "table", ...)
                end
                if real.type(opts.Url) == "string" then remember(urls, opts.Url) end
                if real.type(opts.Url) == "string" and real.type(urls.__lrm_plant) == "table" then
                        local list = urls.__lrm_plant
                        local matched = false
                        for i = 1, #list do
                                local plant = list[i]
                                if real.type(plant) == "table" and real.type(plant.body) == "string" then
                                        local u = plant.url
                                        if u == nil or (real.type(u) == "string" and real.sub(opts.Url, 1, #u) == u) then
                                                comment(label .. " -> canned via urls[" .. i .. "] ("
                                                        .. real.tostring(#plant.body) .. " bytes, .." .. real.sub(opts.Url, -10) .. ")")
                                                matched = true
                                                return { Success = true, StatusCode = 200,
                                                        Headers = plant.headers or {}, Body = plant.body }
                                        end
                                end
                        end
                        if not matched then
                                local u0 = list[1]
                                if real.type(u0) == "table" and real.type(u0.url) == "string" then
                                        local w = u0.url
                                        local diff
                                        local scan = (#w < #opts.Url) and #w or #opts.Url
                                        for i = 1, scan do
                                                if real.byte(w, i) ~= real.byte(opts.Url, i) then
                                                        diff = i
                                                        break
                                                end
                                        end
                                        local lo = diff and ((diff - 8 > 1) and (diff - 8) or 1) or 1
                                        comment(label .. " -> plant MISS n=" .. real.tostring(#list)
                                                .. " len=" .. real.tostring(#w) .. "/" .. real.tostring(#opts.Url)
                                                .. " firstdiff=" .. real.tostring(diff)
                                                .. (diff and (" w=" .. real.sub(w, lo, diff + 8)
                                                        .. " r=" .. real.sub(opts.Url, lo, diff + 8)) or ""))
                                else
                                        comment(label .. " -> plant MISS n=" .. real.tostring(#list)
                                                .. " u0=" .. real.type(u0))
                                end
                        end
                end
                if real.type(opts.Url) == "string" and real.find(opts.Url, "x.luarmor", 1, true) then
                        local hit
                        if real.type(cfg.readfile_map) == "table" then
                                local body = cfg.readfile_map["__lrm_session_response"]
                                if body then
                                        local okh, hdrs = real.pcall(function() return real.json.decode(
                                                cfg.readfile_map.__lrm_session_headers or "{}") end)
                                        hit = { body = body, headers = (okh and hdrs) or {},
                                                legacy = true }
                                end
                        end
                        if hit then
                                comment(label .. " -> canned via readfile_map ("
                                        .. real.tostring(#hit.body) .. " bytes)")
                                return { Success = true, StatusCode = 200,
                                        Headers = hit.headers or {}, Body = hit.body }
                        end
                end
                if cfg.http_map and real.type(opts.Url) == "string" then
                        local method = real.tostring(opts.Method or opts.method or "GET"):upper()
                        local hit = cfg.http_map[method .. " " .. opts.Url] or cfg.http_map[opts.Url]
                        if hit == nil then
                                for k, v in real.next, cfg.http_map do
                                        if real.type(k) == "string" and #k > 1 and real.sub(k, #k, #k) == "*" then
                                                local pfx = real.sub(k, 1, #k - 1)
                                                if real.sub(opts.Url, 1, #pfx) == pfx
                                                        or (method .. " " .. opts.Url):sub(1, #pfx) == pfx then
                                                        hit = v
                                                        break
                                                end
                                        end
                                end
                        end
                        if hit then
                                comment(label .. " -> canned " .. real.tostring(hit.status or 200)
                                        .. " (" .. real.tostring(#real.tostring(hit.body or "")) .. " bytes)")
                                if cfg.call_log then hub.dumpCallLog() end
                                return { Success = true, StatusCode = hit.status or 200,
                                        Headers = hit.headers or {}, Body = hit.body }
                        end
                end
                if real.type(opts.Url) == "string" and real.find(opts.Url, "luarmor", 1, true)
                        and cfg.serve and servePad and coroutine.isyieldable() then
                        local tries = urls.__lrm_tries or {}
                        urls.__lrm_tries = tries
                        local n = (tries[opts.Url] or 0) + 1
                        tries[opts.Url] = n
                        if n <= 4 then
                                real.print(markPrefix .. "NEEDFETCH " .. opts.Url)
                                real.print(servePad)
                                coroutine.yield("__LRMRES " .. opts.Url)
                                return httpRequest(label)(...)
                        end
                end
                return callP(label .. "(" .. fmt(opts) .. ")", "response", "table")
        end
end

hub.armCallLog = function() end
if cfg.call_log then
        local ring = {}
        local rn = 0
        local armed = false
        local function push(s)
                rn = rn + 1
                ring[(rn - 1) % 4000] = s
        end
        local function summ(v)
                local t = real.type(v)
                if t == "string" then
                        local lim = cfg.call_log_full and 4000 or 28
                        local head = real.sub(v, 1, lim)
                        return "s" .. #v .. ":" .. real.gsub(head, "%c", "?")
                elseif t == "number" then
                        return real.tostring(v)
                end
                return t
        end
        local function wraplib(name, lib)
                if real.type(lib) ~= "table" then return end
                local wrapped = {}
                for fn, f in real.next, lib do
                        if real.type(f) == "function" then
                                wrapped[fn] = function(...)
                                        local a, b, c = ...
                                        push(name .. "." .. real.tostring(fn) .. "(" .. summ(a) .. ", " .. summ(b) .. ", " .. summ(c) .. ")")
                                        return f(...)
                                end
                        else
                                wrapped[fn] = f
                        end
                end
                local ok = real.pcall(function()
                        for k, v in real.next, wrapped do lib[k] = v end
                end)
                if not ok then
                        envTable[name] = wrapped
                end
        end
        hub.armCallLog = function()
                if armed then return end
                armed = true
                wraplib("string", envTable.string)
                wraplib("bit32", envTable.bit32)
                wraplib("math", envTable.math)
                wraplib("table", envTable.table)
                if envTable.buffer then wraplib("buffer", envTable.buffer) end
                if envTable.string then
                        real.pcall(function() debug.setmetatable("", { __index = envTable.string }) end)
                end
        end
        hub.dumpCallLog = function()
                local start = rn - 4000
                if start < 0 then start = 0 end
                for i = start, rn - 1 do
                        real.print("\1CALL\1" .. ring[i % 4000])
                end
        end
end
envTable.request = httpRequest("request")
envTable.http_request = httpRequest("http_request")
envTable.http = { request = httpRequest("http.request") }
envTable.syn = { request = httpRequest("syn.request") }
envTable.getrawmetatable = function(x)
        if genvName[x] then return nil end
        if isP(x) then
                return { __index = function() end, __newindex = function() end, __namecall = function() end }
        end
        return real.getmetatable(x)
end
envTable.setrawmetatable = function(x, mt) return x end
envTable.getgc = function() return {} end
envTable.getreg = function() return {} end
envTable.getloadedmodules = function() return {} end
envTable.getrunningscripts = function() return {} end
envTable.getscripts = function() return {} end
envTable.getinstances = function() return {} end
envTable.getnilinstances = function() return {} end
envTable.getscriptclosure = function() return function() end end
envTable.getsenv = function() return {} end
envTable.getcallingscript = function() return envTable.script end
envTable.getthreadidentity = function() return 8 end
envTable.getidentity = function(...) return envTable.getthreadidentity(...) end
envTable.getthreadcontext = function(...) return envTable.getthreadidentity(...) end
envTable.setthreadidentity = function() end
envTable.setidentity = function() end
envTable.lz4compress = function(s) return s end
envTable.lz4decompress = function(s) return s end
envTable.crypt = { base64encode = function(s) return s end, base64decode = function(s) return s end }
envTable.base64_encode = envTable.crypt.base64encode
envTable.base64_decode = envTable.crypt.base64decode
envTable.Drawing = { new = function(kind) return callP("Drawing.new(" .. fmt(kind) .. ")", real.type(kind) == "string" and kind or "drawing") end }
envTable.isrbxactive = function() return true end
envTable.isgameactive = function(...) return envTable.isrbxactive(...) end

local realInfo = debug.info
local harnessSrc = realInfo(1, "s")
local fakeDebug = {}
for k, v in real.pairs(debug) do fakeDebug[k] = v end

local function isHarness(f)
        return real.type(f) == "function" and realInfo(f, "s") == harnessSrc
end

local function visibleStack(th, from)
        local frames = {}
        local lvl = from
        while true do
                local f
                if th then f = realInfo(th, lvl, "f") else f = realInfo(lvl, "f") end
                if f == nil then
                        local src
                        if th then src = realInfo(th, lvl, "s") else src = realInfo(lvl, "s") end
                        if src == nil then break end
                end
                real.insert(frames, { f = f, lvl = lvl })
                lvl += 1
        end
        local out = {}
        local i = 1
        while i <= #frames do
                local fr = frames[i]
                local harness = isHarness(fr.f)
                if not harness and realInfo(fr.f or print, "s") == "[C]" then
                        local j = i
                        while j <= #frames and not isHarness(frames[j].f) and realInfo(frames[j].f or print, "s") == "[C]" do
                                j += 1
                        end
                        if j <= #frames and isHarness(frames[j].f) then
                                i = j
                                harness = true
                                fr = frames[i]
                        end
                end
                if harness then
                        while i + 1 <= #frames and isHarness(frames[i + 1].f) do
                                i += 1
                        end
                        real.insert(out, { f = frames[i].f, fake = true, lvl = frames[i].lvl })
                else
                        real.insert(out, { f = fr.f, lvl = fr.lvl })
                end
                i += 1
        end
        return out
end

local function fakeFields(f, opts)
        local out = {}
        for ch in string.gmatch(opts, ".") do
                if ch == "s" then real.insert(out, "[C]")
                elseif ch == "l" then real.insert(out, -1)
                elseif ch == "n" then real.insert(out, cnames[f] or "")
                elseif ch == "a" then real.insert(out, 0); real.insert(out, true)
                elseif ch == "f" then real.insert(out, f) end
        end
        return real.unpack(out)
end

local info0
fakeDebug.info = function(a, b, c)
        if cfg.ptrace then
                local r = table.pack(info0(a, b, c, 1))
                local t = {}
                for i = 1, r.n do t[i] = real.tostring(r[i]) end
                real.print("[debug.info]", real.type(a) == "function" and (cnames[a] or fnText[a] or real.tostring(a)) or real.tostring(a), b, c, "->", real.concat(t, ", ", 1, r.n))
                return real.unpack(r, 1, r.n)
        end
        return info0(a, b, c, 1)
end
cfuncs[fakeDebug.info] = true
cnames[fakeDebug.info] = "info"
function info0(a, b, c, extra)
        if real.type(a) == "function" then
                if cfuncs[a] or isHarness(a) then return fakeFields(a, b) end
                return realInfo(a, b)
        end
        local th, level, opts = nil, a, b
        if real.type(a) == "thread" then th, level, opts = a, b, c end
        if real.type(level) ~= "number" then
                if cfg.debug_stack and isP(a) then real.print("[debug.info on proxy]", infoOf[a].kind, infoOf[a].key, infoOf[a].hint) end
                return realInfo(a, b, c)
        end
        local stack = visibleStack(th, th and 0 or 3 + (extra or 0))
        local fr = stack[th and level + 1 or level]
        if cfg.debug_stack then
                local parts = {}
                for i, x in stack do
                        parts[i] = (x.fake and "*" or "") .. real.tostring(cnames[x.f] or x.f) .. "@" .. real.tostring(realInfo(x.f or print, "s"))
                        if i > 6 then break end
                end
                local raw = {}
                for l = 2, 9 do
                        local f = realInfo(l, "f")
                        raw[#raw + 1] = real.tostring(cnames[f] or f) .. "@" .. real.tostring(realInfo(l, "s"))
                end
                real.print("[stack] level", level, opts, "->", real.concat(parts, " | "), "\n   raw:", real.concat(raw, " | "))
        end
        if level == 0 and not th then
                return fakeFields(fakeDebug.info, opts)
        end
        if not fr then return nil end
        if fr.fake then return fakeFields(fr.f, opts) end
        if th then return realInfo(th, fr.lvl, opts) end
        return realInfo(fr.lvl - 1, opts)
end

fakeDebug.traceback = function(a, b, c)
        local tb = debug.traceback(a, b, c)
        if real.type(tb) ~= "string" then return tb end
        local keep = {}
        for line in string.gmatch(tb, "[^\n]+") do
                if not real.find(line, harnessSrc, 1, true) then real.insert(keep, line) end
        end
        return real.concat(keep, "\n")
end
do
        local memcat = "Default"
        if fakeDebug.profilebegin == nil then fakeDebug.profilebegin = function(label)
                if real.type(label) ~= "string" then real.error("invalid argument #1 to 'profilebegin' (string expected, got " .. real.typeof(label) .. ")", 2) end
        end end
        if fakeDebug.profileend == nil then fakeDebug.profileend = function() end end
        if fakeDebug.setmemorycategory == nil then fakeDebug.setmemorycategory = function(tag)
                if real.type(tag) ~= "string" then real.error("invalid argument #1 to 'setmemorycategory' (string expected, got " .. real.typeof(tag) .. ")", 2) end
                local old = memcat
                memcat = tag
                return old
        end end
        if fakeDebug.resetmemorycategory == nil then fakeDebug.resetmemorycategory = function() memcat = "Default" end end
        if fakeDebug.getmemorycategory == nil then fakeDebug.getmemorycategory = function() return memcat end end
end
envTable.debug = fakeDebug

envTable.getmetatable = function(...)
        if genvName[(...)] then return nil end
        return real.getmetatable(...)
end
cfuncs[envTable.getmetatable] = true
cnames[envTable.getmetatable] = "getmetatable"

if cfg.oplog then
        local ring, pos, ringSize = {}, 0, cfg.oplog
        envTable.__oplog = function(loop, op, pc)
                pos += 1
                ring[pos % ringSize] = loop .. " op=" .. op .. " pc=" .. pc
        end
        envTable.__seen = {}
        do
                local co = {}
                for k, f in real.pairs(coroutine) do
                        co[k] = function(...)
                                local res = table.pack(f(...))
                                local a = {}
                                for i = 1, real.select("#", ...) do a[i] = envTable.__name((real.select(i, ...))) end
                                local r = {}
                                for i = 1, res.n do r[i] = envTable.__name(res[i]) end
                                pos += 1
                                ring[pos % ringSize] = "CO coroutine." .. k .. "(" .. real.concat(a, ", ") .. ") -> " .. real.concat(r, ", ")
                                return real.unpack(res, 1, res.n)
                        end
                end
                envTable.coroutine = co
        end
        local pids, npid = {}, 0
        envTable.__opl = function(loop, op, pc, proto)
                local id = pids[proto]
                if not id then
                        npid += 1
                        id = npid
                        pids[proto] = id
                        pos += 1
                        ring[pos % ringSize] = "NEWPROTO P" .. id .. " " .. real.tostring(proto)
                end
                pos += 1
                ring[pos % ringSize] = "P" .. id .. " L" .. loop .. " op" .. op .. " pc" .. pc
        end
        envTable.__opv = function(v, pc)
                pos += 1
                ring[pos % ringSize] = "  = " .. envTable.__name(v)
        end
        local names = nil
        envTable.__name = function(v)
                if not names then
                        names = {}
                        for k, x in real.pairs(envTable) do
                                if real.type(x) == "function" then names[x] = k
                                elseif real.type(x) == "table" and x ~= scriptEnv then
                                        for k2, y in real.pairs(x) do
                                                if real.type(y) == "function" then names[y] = k .. "." .. real.tostring(k2) end
                                        end
                                end
                        end
                end
                if names[v] then return names[v] end
                local t = real.type(v)
                if t == "string" then return real.fmt("%q", real.sub(v, 1, 80)) end
                if isP(v) then return "<proxy " .. real.tostring(infoOf[v].name or infoOf[v].hint) .. ">" end
                return real.tostring(v)
        end
        envTable.__dump = function(label, t, depth)
                depth = depth or 0
                local function d(v, lvl)
                        if real.type(v) ~= "table" or lvl > 2 then return envTable.__name(v) end
                        local parts = {}
                        for k, x in real.pairs(v) do
                                real.insert(parts, "[" .. envTable.__name(k) .. "]=" .. d(x, lvl + 1))
                                if #parts > 80 then break end
                        end
                        return "{" .. real.concat(parts, ", ") .. "}"
                end
                real.print("[dump]", label, d(t, 0))
        end
        envTable.__opdump = function()
                for i = real.max(1, pos - ringSize + 1), pos do
                        real.print(ring[i % ringSize])
                end
        end
end

if cfg.flip_probe then
        envTable.__p = { n = 0 }
end

if cfg.inline_probe then
        envTable.__r = table.create(1e6)
        envTable.__p = { n = 0 }
        envTable.__opdump = function()
                local names = {}
                for k, x in real.pairs(envTable) do
                        if real.type(x) == "function" then names[x] = k
                        elseif real.type(x) == "table" and x ~= scriptEnv then
                                for k2, y in real.pairs(x) do
                                        if real.type(y) == "function" then names[y] = k .. "." .. real.tostring(k2) end
                                end
                        end
                end
                local function nm(v)
                        if names[v] then return names[v] end
                        if real.type(v) == "string" then return real.fmt("%q", real.sub(v, 1, 80)) end
                        if isP(v) then
                                local chain, q, guard = {}, v, 0
                                while q and guard < 12 do
                                        guard += 1
                                        local qi = infoOf[q]
                                        real.insert(chain, 1, real.tostring(qi.name or qi.key or qi.hint or qi.kind))
                                        q = qi.parent
                                end
                                return "<proxy " .. real.concat(chain, ".") .. ">"
                        end
                        return real.tostring(v)
                end
                local rr = envTable.__r
                for i = real.max(1, #rr - (cfg.dump_last or 1500000)), #rr do
                        local e = rr[i]
                        if real.type(e) == "number" then
                                local pc = e % 65536
                                local rest = (e - pc) / 65536
                                local op = rest % 256
                                rest = (rest - op) / 256
                                local loop = rest % 16
                                local pid = (rest - loop) / 16
                                real.print("P" .. pid .. " L" .. loop .. " op" .. op .. " pc" .. pc)
                        else
                                real.print("  = " .. nm(e[1]))
                        end
                end
        end
end

if cfg.co_log then
        local co = {}
        for k, f in real.pairs(coroutine) do co[k] = f end
        co.resume = function(...)
                local res = table.pack(coroutine.resume(...))
                real.print("[co.resume]", real.unpack(res, 1, res.n))
                return real.unpack(res, 1, res.n)
        end
        envTable.coroutine = co
end

envTable.__pid = { n = 0 }
envTable.__parg1 = {}
envTable.__ent = { n = 0 }
envTable.__skipp = {}
envTable.__pf = real.setmetatable({}, { __mode = "k" })
envTable.__plast = {}
if cfg.fold ~= false then
        hub.pf, hub.pid, hub.plast = envTable.__pf, envTable.__pid, envTable.__plast
end
for _, pid in cfg.skip_protos or {} do envTable.__skipp[pid] = true end
if cfg.spin then
        local sw = { n = 0, step = 1048576 }
        local idle, lastS, lastId = 0, -1, -1
        sw.f = function()
                sw.n = 0
                if cfg.heartbeat and real.clock() - (cfg._hb or startClock) > cfg.heartbeat then
                        cfg._hb = real.clock()
                        real.print(markPrefix .. "HB\n" .. real.rep(" ", 16384))
                end
                if stmtCount ~= lastS or nextId ~= lastId then
                        idle, lastS, lastId = 0, stmtCount, nextId
                        return
                end
                if hub.decodeUntil then
                        if real.clock() > hub.decodeUntil then
                                abortReason = "constant decode took too long"
                                real.error(abort, 0)
                        end
                        return
                end
                idle += 1
                if idle >= cfg.spin then
                        abortReason = abortReason or "endless loop in the script's own code (no environment access)"
                        if cfg.skip_spin and not trigger then
                                local ent = envTable.__ent
                                for i = ent.n, real.max(1, ent.n - 63), -1 do
                                        local p = ent[i % 64]
                                        if p and not envTable.__skipp[p] then trigger = p; break end
                                end
                        end
                        checkBudget()
                end
        end
        envTable.__spin = sw
end
envTable.__pa = cfg.devirt and { n = 0 } or false
envTable.__pk = {}
if envTable.__pa then
        local orig = real.setmetatable({}, { __mode = "k" })
        hub.paOrig = orig
        local nested = real.setmetatable({}, { __mode = "k" })
        local lazyKeys = real.setmetatable({}, { __mode = "k" })
        local holders = real.setmetatable({}, { __mode = "k" })
        local function numCopy(arr)
                local c, n = {}, 0
                for i, x in real.next, arr do
                        if real.type(x) == "number" then c[i] = x; n += 1 end
                end
                return n > 0 and c or nil
        end
        local function snapNested(proto, w)
                if nested[w] == nil then
                        if real.type(w) == "buffer" then
                                local b = buffer.create(buffer.len(w))
                                buffer.copy(b, 0, w)
                                nested[w] = b
                        else
                                nested[w] = numCopy(w) or false
                        end
                end
                return nested[w]
        end
        real.setmetatable(envTable.__pa, { __newindex = function(t, proto, v)
                real.rawset(t, proto, v)
                if real.type(proto) ~= "table" then return end
                local copy = {}
                for _, src_tbl in real.ipairs({ proto, v }) do
                        if real.type(src_tbl) == "table" then
                                for key, arr in real.next, src_tbl do
                                        if real.type(arr) == "table" then
                                                for wk, wv in real.next, arr do
                                                        if real.type(wk) == "string" and real.type(wv) == "table" and real.type(real.rawget(wv, 3)) == "function" then
                                                                hub.savedWn = hub.savedWn or {}
                                                                real.insert(hub.savedWn, { vm = arr, k = wk, v = wv })
                                                        end
                                                end
                                        end
                                        if real.type(arr) == "table" and arr ~= proto and arr ~= v and not copy[arr] then
                                                local c = numCopy(arr)
                                                if arr ~= envTable and real.getmetatable(arr) ~= nil and lazyKeys[arr] == nil then
                                                        local keys = {}
                                                        for k in real.next, arr do keys[k] = true end
                                                        lazyKeys[arr] = keys
                                                        c = c or {}
                                                end
                                                if c then
                                                        copy[arr] = c
                                                elseif arr ~= envTable and real.getmetatable(arr) == nil then
                                                        for _, w in real.next, arr do
                                                                if (real.type(w) == "table" and w ~= proto and w ~= v and w ~= arr and w ~= envTable and real.getmetatable(w) == nil)
                                                                        or real.type(w) == "buffer" then
                                                                        if snapNested(proto, w) then
                                                                                holders[proto] = holders[proto] or {}
                                                                                holders[proto][key] = arr
                                                                        end
                                                                end
                                                        end
                                                end
                                        end
                                end
                        end
                end
                orig[proto] = copy
        end })
        hub.lazyLate = real.setmetatable({}, { __mode = "k" })
        local function restore(copy)
                for arr, c in real.next, copy do
                        local keys = lazyKeys[arr]
                        if keys and not hub.lazyLate[arr] then
                                local late = {}
                                for k in real.next, arr do
                                        if not keys[k] then late[k] = true end
                                end
                                hub.lazyLate[arr] = late
                        end
                        for i, x in real.next, c do real.rawset(arr, i, x) end
                end
        end
        hub.unscramble = function()
                local fixed = 0
                local done, ran, size = {}, {}, {}
                for proto, copy in real.next, orig do
                        local arrays, all = 0, true
                        size[proto] = 0
                        for arr, c in real.next, copy do
                                if not lazyKeys[arr] then
                                        local n, same, huge = 0, 0, 0
                                        for i, x in real.next, c do
                                                n += 1
                                                local y = real.rawget(arr, i)
                                                if y == x then
                                                        same += 1
                                                elseif real.type(y) == "number" and (y >= 16777216 or y <= -16777216) then
                                                        huge += 1
                                                end
                                        end
                                        if same < n then ran[proto] = true end
                                        if n > size[proto] then size[proto] = n end
                                        if n >= 2 then arrays += 1 end
                                        if same > 0 and (same > n * 0.1 or huge < (n - same) * 0.8) then all = false end
                                end
                        end
                        if all and ran[proto] and arrays >= 2 then
                                restore(copy)
                                fixed += 1
                                done[proto] = true
                        end
                end
                local users = {}
                for proto, hs in real.next, holders do
                        for key, arr in real.next, hs do
                                users[arr] = users[arr] or {}
                                users[arr][proto] = key
                        end
                end
                for arr, set in real.next, users do
                        local restored, live = 0, 0
                        for p in real.next, set do
                                if done[p] then restored += size[p] or 0 elseif ran[p] then live += size[p] or 0 end
                        end
                        if restored > 0 then
                                local whole = restored >= live
                                local view = nil
                                for k, w in real.next, arr do
                                        local snap = nested[w]
                                        local changed = false
                                        if real.type(w) == "buffer" and snap then
                                                changed = buffer.tostring(w) ~= buffer.tostring(snap)
                                        elseif real.type(w) == "table" and snap then
                                                for i, x in real.next, snap do
                                                        if real.rawget(w, i) ~= x then changed = true break end
                                                end
                                        end
                                        if changed and whole then
                                                if real.type(w) == "buffer" then
                                                        buffer.copy(w, 0, snap)
                                                else
                                                        for i, x in real.next, snap do real.rawset(w, i, x) end
                                                end
                                        elseif changed then
                                                local pristine
                                                if real.type(w) == "buffer" then
                                                        pristine = buffer.create(buffer.len(snap))
                                                        buffer.copy(pristine, 0, snap)
                                                else
                                                        pristine = {}
                                                        for i, x in real.next, w do pristine[i] = x end
                                                        for i, x in real.next, snap do pristine[i] = x end
                                                end
                                                if not view then
                                                        view = {}
                                                        for k2, w2 in real.next, arr do view[k2] = w2 end
                                                end
                                                view[k] = pristine
                                        end
                                end
                                for p, key in real.next, set do
                                        if whole and ran[p] and not done[p] and orig[p] then
                                                restore(orig[p])
                                                done[p] = true
                                                fixed += 1
                                        elseif view and done[p] then
                                                real.rawset(p, key, view)
                                                if envTable.__pa[p] then real.rawset(envTable.__pa[p], key, view) end
                                        end
                                end
                        end
                end
                return fixed
        end
end
do
        local libs = { "string", "table", "math", "bit32", "buffer", "coroutine", "utf8", "os", "debug", "task", "vector" }
        hub.dumpProtos = function()
                local pa = envTable.__pa
                if not pa then return nil end
                hub.unscrambled = hub.unscramble()
                local fname = {}
                for f, label in real.next, fnText do
                        if real.type(f) == "function" and real.type(label) == "string" then
                                fname[f] = fname[f] or label
                        end
                end
                for k, v in real.next, envTable do
                        if real.type(v) == "function" and real.type(k) == "string" then fname[v] = fname[v] or k end
                end
                for _, lib in real.ipairs(libs) do
                        local t = real.rawget(envTable, lib)
                        if real.type(t) == "table" then
                                for k, v in real.next, t do
                                        if real.type(v) == "function" then fname[v] = fname[v] or (lib .. "." .. real.tostring(k)) end
                                end
                        end
                end
                local stop = { [envTable] = "ENV", [scriptEnv] = "ENV" }
                for _, lib in real.ipairs(libs) do
                        local t = real.rawget(envTable, lib)
                        if real.type(t) == "table" then stop[t] = lib end
                end
                for name in datatypes do
                        local t = real.rawget(envTable, name)
                        if real.type(t) == "table" then
                                stop[t] = stop[t] or name
                                for k, v in real.next, t do
                                        if real.type(v) == "function" then fname[v] = fname[v] or (name .. "." .. real.tostring(k)) end
                                end
                        end
                end
                local ids, queue, fids = {}, {}, {}
                local nfid = 0
                local function hex(s)
                        return (real.gsub(s, ".", function(c) return real.fmt("%02x", real.byte(c)) end))
                end
                local function num(x)
                        if x ~= x then return '{"num":"nan"}' end
                        if x == real.huge then return '{"num":"inf"}' end
                        if x == -real.huge then return '{"num":"-inf"}' end
                        if x == 0 and 1 / x < 0 then return '{"num":"-0"}' end
                        if x == real.floor(x) and x > -2 ^ 53 and x < 2 ^ 53 then return real.fmt("%d", x) end
                        return real.fmt("%.17g", x)
                end
                local function enc(v)
                        local t = real.type(v)
                        if v == nil then return "null"
                        elseif t == "boolean" then return v and "true" or "false"
                        elseif t == "number" then return num(v)
                        elseif t == "string" then return '{"s":"' .. hex(v) .. '"}'
                        elseif t == "function" then
                                if fname[v] then return '{"f":"' .. fname[v] .. '"}' end
                                if not fids[v] then nfid += 1; fids[v] = nfid end
                                local pf = real.rawget(envTable.__pf, v)
                                if real.type(pf) == "table" then
                                        return '{"lf":' .. fids[v] .. ',"pf":' .. enc(pf) .. '}'
                                end
                                if cfg.lf_debug then
                                        local na, va = debug.info(v, "a")
                                        real.print("LFDBG", fids[v], debug.info(v, "l"), na, va, debug.info(v, "n"))
                                end
                                return '{"lf":' .. fids[v] .. '}'
                        elseif t == "table" then
                                if stop[v] then return '{"g":"' .. stop[v] .. '"}' end
                                if not ids[v] then
                                        real.insert(queue, v)
                                        ids[v] = #queue
                                end
                                return '{"t":' .. ids[v] .. "}"
                        elseif real.typeof(v) == "buffer" then
                                return '{"b":"' .. hex(buffer.tostring(v)) .. '"}'
                        elseif t == "vector" then
                                return '{"vec":[' .. num(v.x) .. "," .. num(v.y) .. "," .. num(v.z) .. "]}"
                        end
                        local ok, src = real.pcall(function() return hub.exprOf and hub.exprOf(v) end)
                        if not ok or real.type(src) ~= "string" then
                                ok, src = real.pcall(real.tostring, v)
                        end
                        return '{"u":"' .. real.typeof(v) .. '","src":"' .. (ok and real.type(src) == "string" and hex(src) or "") .. '"}'
                end
                local forced = {}
                local fstats = { calls = 0, got = 0, t0 = real.clock() }
                hub.forceStats = fstats
                if hub.savedWn then
                        for _, sw in real.ipairs(hub.savedWn) do
                                if real.rawget(sw.vm, sw.k) == nil then
                                        real.rawset(sw.vm, sw.k, sw.v)
                                end
                        end
                end
                local byseq = {}
                for proto, cap in real.next, pa do
                        if real.type(cap) == "table" and cap.__seq then
                                byseq[cap.__seq] = real.setmetatable({ self = proto }, { __index = cap })
                        end
                end
                local snapTabs, snapBufs = {}, {}
                if real.type(cfg.force_req) == "string" then
                        local q = {}
                        for proto, cap in real.next, pa do
                                if real.type(cap) == "table" then
                                        real.insert(q, cap)
                                        real.insert(q, proto)
                                end
                        end
                        local qi = 1
                        while qi <= #q do
                                local t = q[qi]
                                qi += 1
                                if not snapTabs[t] and not stop[t] then
                                        local copy = {}
                                        for k, v in real.next, t do
                                                copy[k] = v
                                                if real.type(v) == "table" then
                                                        real.insert(q, v)
                                                elseif real.typeof(v) == "buffer" and not snapBufs[v] then
                                                        snapBufs[v] = buffer.tostring(v)
                                                end
                                        end
                                        snapTabs[t] = copy
                                end
                        end
                end
                local function applyBufs(bufs)
                local bufRestore = {}
                if real.type(bufs) == "string" then
                        for spec in string.gmatch(bufs, "[^;]+") do
                                local head = string.match(spec, "^[^/]+")
                                local v, si = nil, 0
                                for st in string.gmatch(head, "[^,]+") do
                                        local k = real.tonumber(st) or st
                                        si += 1
                                        if si == 1 then v = byseq[k]
                                        elseif si == 2 and real.type(v) == "table" then v = v[k]
                                        elseif real.type(v) == "table" then v = real.rawget(v, k)
                                        else v = nil end
                                end
                                if real.type(v) == "table" then
                                        for k, val in string.gmatch(spec, "/=(%-?%d+):([^/]+)") do
                                                k = real.tonumber(k)
                                                real.insert(bufRestore, { v, k, real.rawget(v, k), true })
                                                real.rawset(v, k, real.tonumber(val))
                                                fstats.bufs = (fstats.bufs or 0) + 1
                                        end
                                elseif real.typeof(v) == "buffer" then
                                        for off, hx in string.gmatch(spec, "/(%d+):(%x+)") do
                                                off = real.tonumber(off)
                                                local n = #hx // 2
                                                if off + n <= buffer.len(v) then
                                                        real.insert(bufRestore, { v, off, buffer.readstring(v, off, n) })
                                                        fstats.bufs = (fstats.bufs or 0) + 1
                                                        for j = 0, n - 1 do
                                                                buffer.writeu8(v, off + j, real.tonumber(string.sub(hx, 2 * j + 1, 2 * j + 2), 16))
                                                        end
                                                end
                                        end
                                end
                        end
                end
                return bufRestore
                end
                local function revertBufs(bufRestore)
                        for i = #bufRestore, 1, -1 do
                                local r = bufRestore[i]
                                if r[4] then real.rawset(r[1], r[2], r[3]) else buffer.writestring(r[1], r[2], r[3]) end
                        end
                end
                local bufRestore = applyBufs(cfg.force_buf)
                local function decodeStart(f, ...)
                        hub.decodeUntil = real.clock() + (cfg.decode_limit or 10)
                        return f(...)
                end
                local abortBefore
                local function decodeGuard(...)
                        hub.decodeUntil = nil
                        abortReason = abortBefore
                        return ...
                end
                local function slot(v, k) return v[k] end
                local function decodeSlot(v, k)
                        abortBefore = abortReason
                        return decodeGuard(real.pcall(decodeStart, slot, v, k))
                end
                local function canDecodeSlot(v, op)
                        if real.type(op) ~= "number" then return true end
                        if op < 0 or op > 1000000 then return false end
                        for nk = 0, -4, -1 do
                                local cand = real.rawget(v, nk)
                                if real.type(cand) == "table" then
                                        local b5, t6 = real.rawget(cand, 5), real.rawget(cand, 6)
                                        local b6, t7 = real.rawget(cand, 6), real.rawget(cand, 7)
                                        local b_obj, k_tab
                                        if real.type(b5) == "buffer" and real.type(t6) == "table" then
                                                b_obj, k_tab = b5, t6
                                        elseif real.type(b6) == "buffer" and real.type(t7) == "table" then
                                                b_obj, k_tab = b6, t7
                                        end
                                        if b_obj and k_tab then
                                                local off = real.rawget(k_tab, op)
                                                if real.type(off) == "number" and (off < 0 or off >= buffer.len(b_obj)) then
                                                        return false
                                                end
                                        end
                                end
                        end
                        return true
                end
                local function decodePath(path, derivedCache, forced)
                        local steps, ovs, toks = {}, {}, {}
                        for st in string.gmatch(path, "[^,]+") do
                                real.insert(toks, st)
                                local a, ov = string.match(st, "^(%-?%d+)@(%-?[%d%.e]+)$")
                                if a then
                                        ovs[#steps + 1] = real.tonumber(ov)
                                        st = a
                                end
                                real.insert(steps, real.tonumber(st) or st)
                        end
                        local derived = false
                        local v = byseq[steps[1]]
                        if not v then
                                for proto, cap in real.next, pa do
                                        if real.type(cap) == "table" and cap.__seq and not byseq[cap.__seq] then
                                                byseq[cap.__seq] = real.setmetatable({ self = proto }, { __index = cap })
                                        end
                                end
                                v = byseq[steps[1]]
                        end
                        local prefix = toks[1]
                        for si = 2, #steps do
                                prefix ..= "," .. toks[si]
                                if real.type(v) ~= "table" then v = nil break end
                                local k = steps[si]
                                local x
                                if si == 2 then
                                        x = v[k]
                                elseif ovs[si] ~= nil and derivedCache[prefix] ~= nil then
                                        derived = true
                                        x = derivedCache[prefix] or nil
                                elseif ovs[si] ~= nil then
                                        derived = true
                                        if not canDecodeSlot(v, ovs[si]) then
                                                v = nil
                                                break
                                        end
                                        fstats.calls += 1
                                        local k0 = real.rawget(v, 0)
                                        if real.type(k0) ~= "table" then
                                                for nk = -1, -4, -1 do
                                                        local cand = real.rawget(v, nk)
                                                        if real.type(cand) == "table" and real.type(real.rawget(cand, 1)) == "number" then
                                                                k0 = cand
                                                                break
                                                        end
                                                end
                                        end
                                        local old = real.rawget(v, k)
                                        local saved
                                        if real.type(k0) == "table" then
                                                saved = real.rawget(k0, k)
                                                real.rawset(k0, k, ovs[si])
                                        end
                                        real.rawset(v, k, nil)
                                        local ok, y = decodeSlot(v, k)
                                        real.rawset(v, k, old)
                                        if real.type(k0) == "table" then real.rawset(k0, k, saved) end
                                        if ok then x = y end
                                        derivedCache[prefix] = x == nil and false or x
                                        if cfg.force_debug then
                                                real.print("FORCEDBG", path, si, real.type(k0), real.tostring(saved), real.tostring(ok), real.tostring(y),
                                                        real.tostring(real.getmetatable(v) ~= nil))
                                        end
                                else
                                        x = real.rawget(v, k)
                                        if x == nil and not derived and forced[v] then
                                                x = forced[v][k]
                                        end
                                        if x == nil then
                                                local k0 = real.rawget(v, 0)
                                                if real.type(k0) ~= "table" then
                                                        for nk = -1, -4, -1 do
                                                                local cand = real.rawget(v, nk)
                                                                if real.type(cand) == "table" and real.type(real.rawget(cand, 1)) == "number" then
                                                                        k0 = cand
                                                                        break
                                                                end
                                                        end
                                                end
                                                local op = (real.type(k0) == "table" and real.type(k) == "number") and real.rawget(k0, k) or nil
                                                if real.type(k) == "number" and real.getmetatable(v) ~= nil and not canDecodeSlot(v, op) then
                                                        v = nil
                                                        break
                                                end
                                                fstats.calls += 1
                                                local ok, y = decodeSlot(v, k)
                                                if cfg.force_debug and not ok then
                                                        real.print("FORCEDBG", path, si, real.tostring(y))
                                                end
                                                if ok and y ~= nil then
                                                        x = y
                                                        if not derived then
                                                                forced[v] = forced[v] or {}
                                                                forced[v][k] = y
                                                                fstats.got += 1
                                                        end
                                                end
                                        end
                                end
                                v = x
                        end
                        return v, derived
                end
                local function callPath(path, derivedCache, forced)
                        local pp, as = string.match(path, "^!([^!]*)!(.*)$")
                        local proto = pp and decodePath((string.gsub(pp, "~", ",")), derivedCache, forced)
                        local f = real.type(proto) == "table" and real.rawget(envTable.__pk, proto)
                        if real.type(f) ~= "function" then return nil end
                        local args, n, frame = {}, 0, nil
                        for a in string.gmatch(as, "[^/]+") do
                                n += 1
                                local c, rest = string.sub(a, 1, 1), string.sub(a, 2)
                                if c == "n" then args[n] = real.tonumber(rest)
                                elseif c == "s" then
                                        args[n] = (real.gsub(rest, "%x%x", function(h) return string.char(real.tonumber(h, 16)) end))
                                elseif c == "t" then args[n] = true
                                elseif c == "f" then args[n] = false
                                elseif c == "F" then frame = frame or {}; args[n] = frame
                                end
                        end
                        if not frame then return nil end
                        fstats.calls += 1
                        abortBefore = abortReason
                        local res = table.pack(decodeGuard(real.pcall(decodeStart, f, real.unpack(args, 1, n))))
                        if not res[1] or res.n > 1 then return nil end
                        local out = {}
                        for k, v in real.next, frame do
                                local t = real.type(v)
                                if real.type(k) == "number" and (t == "string" or t == "number" or t == "boolean") then out[k] = v end
                        end
                        fstats.got += 1
                        return out
                end
                local function decodeAny(path, derivedCache, forced)
                        if string.sub(path, 1, 1) == "!" then
                                return callPath(path, derivedCache, forced), true
                        end
                        return decodePath(path, derivedCache, forced)
                end
                if real.type(cfg.force_req) == "string" then
                        local derivedCache = {}
                        for path in string.gmatch(cfg.force_req, "[^;]+") do
                                local v, derived = decodeAny(path, derivedCache, forced)
                                if derived then
                                        fstats.over = fstats.over or {}
                                        real.insert(fstats.over, path .. "=" .. (v ~= nil and enc(v) or "null"))
                                end
                        end
                end
                revertBufs(bufRestore)
                local function restoreSnap()
                        for t, copy in real.next, snapTabs do
                                real.pcall(function()
                                        local extra = {}
                                        for k in real.next, t do
                                                if copy[k] == nil then real.insert(extra, k) end
                                        end
                                        for _, k in real.ipairs(extra) do real.rawset(t, k, nil) end
                                        for k, v in real.next, copy do real.rawset(t, k, v) end
                                end)
                        end
                        for b, s in real.next, snapBufs do
                                buffer.writestring(b, 0, s)
                        end
                end
                restoreSnap()
                for t, kv in real.next, forced do
                        for k, v in real.next, kv do real.rawset(t, k, v) end
                end
                local out = {}
                local protos = {}
                for proto, cap in real.next, pa do
                        if real.type(proto) ~= "table" then continue end
                        local pid = envTable.__pid[proto]
                        local fields = {}
                        for k, v in real.next, cap do
                                real.insert(fields, '"' .. real.tostring(k) .. '":' .. enc(v))
                        end
                        local self = enc(proto)
                        real.insert(protos, '"' .. (pid and real.tostring(pid) or ("t" .. ids[proto])) .. '":{"self":' .. self .. ","
                                .. real.concat(fields, ",") .. "}")
                end
                local function mtIndex(t)
                        local mt = real.getmetatable(t)
                        local f = real.type(mt) == "table" and real.rawget(mt, "__index") or nil
                        return real.type(f) == "function" and enc(f) or "null"
                end
                local function tableJson(i, t, forced)
                        local view = {}
                        for k, v in real.next, t do view[k] = v end
                        if forced[t] then
                                for k, v in real.next, forced[t] do view[k] = v end
                        end
                        local maxn, cnt = 0, 0
                        for k in real.next, view do
                                if real.type(k) == "number" and k >= 1 and k == real.floor(k) and k < 2 ^ 31 then
                                        cnt += 1
                                        if k > maxn then maxn = k end
                                end
                        end
                        local dense = maxn > 0 and cnt * 2 >= maxn
                        local parts, kv = {}, {}
                        if dense then
                                for j = 1, maxn do parts[j] = enc(view[j]) end
                        end
                        for k, v in real.next, view do
                                if not (dense and real.type(k) == "number" and k >= 1 and k <= maxn and k == real.floor(k)) then
                                        real.insert(kv, "[" .. enc(k) .. "," .. enc(v) .. "]")
                                end
                        end
                        local lateKeys = hub.lazyLate and hub.lazyLate[t]
                        local late = ""
                        if lateKeys then
                                local e = {}
                                for k in real.next, lateKeys do real.insert(e, enc(k)) end
                                late = ',"late":[' .. real.concat(e, ",") .. "]"
                        end
                        return '"' .. i .. '":{"arr":[' .. real.concat(parts, ",") .. '],"kv":[' .. real.concat(kv, ",") .. "]" .. late
                                .. (real.getmetatable(t) ~= nil and (',"mt":true,"mtf":' .. mtIndex(t) .. "}") or "}")
                end
                local tabs = {}
                local i = 1
                while i <= #queue do
                        tabs[i] = tableJson(i, queue[i], forced)
                        i += 1
                end
                local pidmap = {}
                for proto, pid in real.next, envTable.__pid do
                        if real.type(proto) == "table" and ids[proto] then real.insert(pidmap, '"' .. ids[proto] .. '":' .. pid) end
                end
                local parg1 = {}
                if envTable.__parg1 then
                        for pid, a1 in real.next, envTable.__parg1 do
                                if real.type(pid) == "number" and real.type(a1) == "number" then
                                        real.insert(parg1, '"' .. pid .. '":' .. enc(a1))
                                end
                        end
                end
                local overs = {}
                for _, o in real.ipairs(fstats.over or {}) do
                        local path, val = string.match(o, "^([^=]+)=(.*)$")
                        real.insert(overs, '["' .. path .. '",' .. val .. "]")
                end
                if cfg.serve then
                        restoreSnap()
                        local sessDerived, sessForced, sessBufs = {}, {}, {}
                        local dumpEnd, sentEnd = #queue, #queue
                        local initPA, dumpedPA = {}, {}
                        for proto in real.next, pa do initPA[proto] = true; dumpedPA[proto] = true end
                        hub.fetch = function(req, bufs)
                                local t0 = real.clock()
                                hub.fetchEnd = function()
                                        revertBufs(sessBufs)
                                        restoreSnap()
                                end
                                if string.sub(bufs, 1, 1) == "+" then
                                        for _, r in real.ipairs(applyBufs(string.sub(bufs, 2))) do real.insert(sessBufs, r) end
                                elseif bufs ~= "=" then
                                        revertBufs(sessBufs)
                                        sessBufs = applyBufs(bufs)
                                end
                                local vals = {}
                                local start = sentEnd + 1
                                if string.sub(req, 1, 1) == "*" then
                                        req = string.sub(req, 2)
                                        start = dumpEnd + 1
                                        dumpedPA = {}
                                        for proto in real.next, initPA do dumpedPA[proto] = true end
                                end
                                for path in string.gmatch(req, "[^;]+") do
                                        local ok, v = real.pcall(decodeAny, path, sessDerived, sessForced)
                                        real.insert(vals, '["' .. path .. '",' .. (ok and v ~= nil and enc(v) or "null") .. "]")
                                end
                                local newProtos = {}
                                for proto, cap in real.next, pa do
                                        if not dumpedPA[proto] and real.type(proto) == "table" then
                                                dumpedPA[proto] = true
                                                if real.type(cap) == "table" and cap.__seq then
                                                        byseq[cap.__seq] = real.setmetatable({ self = proto }, { __index = cap })
                                                end
                                                local pid = envTable.__pid[proto]
                                                local fields = {}
                                                for k, v in real.next, cap do
                                                        real.insert(fields, '"' .. real.tostring(k) .. '":' .. enc(v))
                                                end
                                                local self = enc(proto)
                                                real.insert(newProtos, '"' .. (pid and real.tostring(pid) or ("t" .. ids[proto])) .. '":{"self":' .. self .. ","
                                                        .. real.concat(fields, ",") .. "}")
                                        end
                                end
                                local parts = {}
                                local j = start
                                while j <= #queue do
                                        real.insert(parts, tableJson(j, queue[j], sessForced))
                                        j += 1
                                end
                                sentEnd = #queue
                                return '{"t":' .. real.fmt("%.4f", real.clock() - t0) .. ',"values":[' .. real.concat(vals, ",") .. '],"tables":{'
                                        .. real.concat(parts, ",") .. '},"new_protos":{' .. real.concat(newProtos, ",") .. "}}"
                        end
                end
                return '{"root_callee":' .. real.tostring(hub.seen and hub.seen[hub.rootCallee] == "ok" and hub.rootCallee or "null") .. ',"overrides":[' .. real.concat(overs, ",") .. '],"protos":{' .. real.concat(protos, ",") .. '},"tables":{' .. real.concat(tabs, ",") ..
                        '},"pid_of_table":{' .. real.concat(pidmap, ",") .. '},"proto_arg1":{' .. real.concat(parg1, ",") .. "}}"
        end
end
function noteTrigger()
        local ent = envTable.__ent
        local routine = ent[ent.n % 64]
        for i = ent.n - 1, real.max(1, ent.n - 63), -1 do
                local q = ent[i % 64]
                if q ~= routine then
                        trigger = q
                        return
                end
        end
end

markC(envTable)
cfuncs[envTable.debug.info] = true

local unknownGlobals = {}
local seenGlobals = {}
real.setmetatable(scriptEnv, {
        __index = function(_, k)
                if real.type(k) ~= "string" then return nil end
                if #k >= 12 and real.match(k, "^_*%x+$") and real.find(k, "%d") then return nil end
                if seenGlobals[k] then
                        if cfg.trace_globals and (k == "_bsdata0" or k == "superflow_bytecode") then
                                real.print("[global-read-nil]", k, debug.traceback())
                        end
                        return nil
                end
                if cfg.__superz_logglobal then real.print("\1SUPERZGLOBAL\1" .. k) end
                local p = globalP(k, "function")
                if cfg.trace_globals and (k == "_bsdata0" or k == "superflow_bytecode") then
                        real.print("[global-proxy]", k, debug.info(2, "s"), debug.info(2, "l"),
                                debug.info(2, "n"), debug.traceback())
                end
                if cfg.ptrace then real.print("[unknown-global]", k) end
                remember(unknownGlobals, k)
                real.rawset(scriptEnv, k, p)
                return p
        end,
        __newindex = function(_, k, v)
                if real.type(k) == "string" then
                        seenGlobals[k] = true
                        if cfg.trace_globals and (k == "_bsdata0" or k == "superflow_bytecode") then
                                real.print("[global-write]", k, real.type(v), debug.traceback())
                        end
                end
                real.rawset(scriptEnv, k, v)
        end,
})

local traceWrap
local traceCache = {}
local traceNames = {}
local function argStr(...)
        local t = {}
        for i = 1, real.select("#", ...) do
                local v = real.select(i, ...)
                t[i] = isP(v) and ("<" .. real.tostring(infoOf[v].name or infoOf[v].hint) .. ">") or real.tostring(v)
                if traceNames[v] then t[i] = "<" .. traceNames[v] .. ">" end
                if real.type(v) == "string" then t[i] = real.fmt("%q", real.sub(v, 1, 60)) end
        end
        return real.concat(t, ", ")
end
function traceWrap(label, v)
        if real.type(v) == "function" then
                if traceCache[v] then return traceCache[v] end
                local w = function(...)
                        real.print("[call]", label .. "(" .. argStr(...) .. ")")
                        local res = table.pack(v(...))
                        real.print("   ->", argStr(real.unpack(res, 1, res.n)))
                        return real.unpack(res, 1, res.n)
                end
                cfuncs[w] = cfuncs[v]
                fnText[w] = fnText[v]
                traceCache[v] = w
                return w
        elseif real.type(v) == "table" and v ~= scriptEnv and not traceCache[v] then
                local proxyT = real.setmetatable({}, {
                        __index = function(_, k) return traceWrap(label .. "." .. real.tostring(k), v[k]) end,
                        __newindex = v,
                        __iter = function() return real.next, v end,
                })
                traceCache[v] = proxyT
                return proxyT
        elseif traceCache[v] then
                return traceCache[v]
        end
        return v
end

if not cfg.flat_env then
        local globals = scriptEnv
        scriptEnv = real.setmetatable({ script = globals.script }, {
                __index = cfg.getlog and function(_, k)
                        real.print("[get]", k)
                        return globals[k]
                end or globals,
                __newindex = function(w, k, v)
                        if real.type(k) == "string" then
                                seenGlobals[k] = true
                                if cfg.trace_globals and (k == "_bsdata0" or k == "superflow_bytecode") then
                                        real.print("[global-write]", k, real.type(v), debug.traceback())
                                end
                        end
                        real.rawset(w, k, v)
                end,
        })
end

if cfg.probe then
        local back = scriptEnv
        traceNames[back] = "ENV"
        for k, v in real.pairs(back) do
                if real.type(v) == "table" or real.type(v) == "function" then traceNames[v] = real.tostring(k) end
        end
        local hot = { buffer = true, bit32 = true, table = true, string = true, math = true, coroutine = true,
                unpack = true, setmetatable = true, select = true }
        scriptEnv = real.setmetatable({}, {
                __index = function(_, k)
                        local v = back[k]
                        real.print("[get]", k, real.type(v))
                        if hot[k] then return v end
                        local w = traceWrap(k, v)
                        if w ~= v and real.type(w) ~= "nil" then traceNames[w] = real.tostring(k) end
                        return w
                end,
                __newindex = function(_, k, v)
                        real.print("[set]", k, real.type(v))
                        back[k] = v
                end,
        })
end

if cfg.trace then
        local back = scriptEnv
        traceNames[back] = "ENV"
        for k, v in real.pairs(back) do
                if real.type(v) == "table" or real.type(v) == "function" then traceNames[v] = real.tostring(k) end
        end
        scriptEnv = real.setmetatable({}, {
                __metatable = nil,
                __index = function(_, k)
                        local v = back[k]
                        real.print("[get]", k, real.type(v))
                        local w = traceWrap(k, v)
                        if w ~= v and real.type(w) ~= "nil" then traceNames[w] = real.tostring(k) end
                        return w
                end,
                __newindex = function(_, k, v)
                        real.print("[set]", k, real.type(v))
                        back[k] = v
                end,
        })
end

local present = {}
local used = {}
local names = {}
local nameCount = {}

local function sanitize(h)
        h = real.tostring(h or "v")
        h = real.gsub(h, "[^%w_]", "")
        if h == "" or real.match(h, "^%d") then h = "v" .. h end
        if not isIdent(h) then h = h .. "_" end
        return h
end

local function uniqueName(h)
        h = sanitize(h)
        nameCount[h] = (nameCount[h] or 0) + 1
        return nameCount[h] == 1 and h or (h .. nameCount[h])
end

local function scanBlock(block, fn)
        for _, s in block.lines do
                fn(s)
                if s.block then scanBlock(s.block, fn) end
        end
end

local markText
local function markProxy(id)
        local p = byId[id]
        if not p then return end
        local info = infoOf[p]
        if used[id] then return end
        used[id] = true
        if info.parent then markProxy(infoOf[info.parent].id) end
        if info.text then markText(info.text) end
        if info.kind == "call" and info.stmt and present[info.stmt] then
                markText(info.stmt.call)
        end
end
function markText(text)
        for id in string.gmatch(text, "\1(%d+)\2") do
                markProxy(real.tonumber(id))
        end
        for fid in string.gmatch(text, "\3(%d+)\4") do
                local rec = frec[real.tonumber(fid)]
                if rec and not rec.marked then
                        rec.marked = true
                        local function mark(s)
                                if s.text then markText(s.text) end
                                if s.call then markText(s.call) end
                                if s.header then markText(s.header) end
                        end
                        scanBlock(rec.block, mark)
                        if rec.alt then scanBlock(rec.alt, mark) end
                end
        end
end

local exprOf
local resolve

hub.exprOf = function(p) return exprOf(p) end
function exprOf(p)
        local info = infoOf[p]
        if info.kind == "name" then return info.name end
        if info.kind == "index" then return exprOf(info.parent) .. keySuffix(info.key) end
        if info.kind == "expr" then return resolve(info.text, info.indent or 0) end
        if info.kind == "call" then
                if info.var then return info.var end
                return resolve(info.stmt.call, info.indent or 0)
        end
        return "nil"
end

local renderBlock

function resolve(text, ind)
        for _ = 1, 10 do
                if not real.find(text, "\1%d+\2") then break end
                text = real.gsub(text, "\1(%d+)\2", function(id)
                        local p = byId[real.tonumber(id)]
                        if not p then return "nil" end
                        infoOf[p].indent = ind
                        return exprOf(p)
                end)
        end
        local src = text
        text = real.gsub(text, "()\3(%d+)\4", function(pos, fid)
                local rec = frec[real.tonumber(fid)]
                local k = 0
                local ls = 1
                for i = pos - 1, 1, -1 do
                        if real.byte(src, i) == 10 then ls = i + 1 break end
                end
                if ls > 1 then
                        while real.byte(src, ls + k) == 9 do k += 1 end
                end
                local lines = { "function(" .. real.concat(rec.params, ", ") .. ")" }
                if rec.alt then
                        local a, b = {}, {}
                        local was = hub.markers
                        hub.markers = false
                        renderBlock(rec.block, ind + k + 1, a)
                        renderBlock(rec.alt, ind + k + 1, b)
                        hub.markers = was
                        local pad = real.rep("\t", ind + k + 1)
                        local function starts(t, i)
                                local l = t[i]
                                return l == nil or (real.sub(l, 1, #pad) == pad and real.byte(l, #pad + 1) ~= 9
                                        and not real.match(l, "^%s*[%)}]") and not real.match(l, "^%s*end%f[%W]")
                                        and not real.match(l, "^%s*else"))
                        end
                        local p = 0
                        local common = 0
                        while a[common + 1] ~= nil and a[common + 1] == b[common + 1] do
                                common += 1
                                if starts(a, common + 1) and starts(b, common + 1) then p = common end
                        end
                        local s = 0
                        common = 0
                        while common < #a - p and common < #b - p and a[#a - common] == b[#b - common] do
                                common += 1
                                if starts(a, #a - common + 1) and starts(b, #b - common + 1) then s = common end
                        end
                        for i = 1, p do real.insert(lines, a[i]) end
                        local st = rec.params[1]
                        local function shifted(t)
                                local out = {}
                                for i = p + 1, #t - s do real.insert(out, "\t" .. (real.gsub(t[i], "\n", "\n\t"))) end
                                return out
                        end
                        local sa, sb = shifted(a), shifted(b)
                        if #sa > 0 then
                                real.insert(lines, pad .. "if " .. st .. " then")
                                for _, l in sa do real.insert(lines, l) end
                                if #sb > 0 then
                                        real.insert(lines, pad .. "else")
                                        for _, l in sb do real.insert(lines, l) end
                                end
                                real.insert(lines, pad .. "end")
                        elseif #sb > 0 then
                                real.insert(lines, pad .. "if not " .. st .. " then")
                                for _, l in sb do real.insert(lines, l) end
                                real.insert(lines, pad .. "end")
                        end
                        for i = #a - s + 1, #a do real.insert(lines, a[i]) end
                else
                        renderBlock(rec.block, ind + k + 1, lines)
                end
                real.insert(lines, real.rep("\t", ind + k) .. "end")
                return real.concat(lines, "\n")
        end)
        return text
end

function renderBlock(block, ind, out)
        local pad = real.rep("\t", ind)
        for _, s in block.lines do
                local mark = hub.markers and #out + 1
                if mark then real.insert(out, false) end
                if s.header then
                        real.insert(out, pad .. resolve(s.header, ind))
                        renderBlock(s.block, ind + 1, out)
                        real.insert(out, pad .. "end")
                elseif s.call then
                        local p = s.res
                        local info = p and infoOf[p]
                        if info and info.var then
                                real.insert(out, pad .. "local " .. info.var .. " = " .. resolve(s.call, ind))
                        else
                                real.insert(out, pad .. resolve(s.call, ind))
                        end
                else
                        real.insert(out, pad .. resolve(s.text, ind))
                end
                if mark then
                        local n = 0
                        for i = mark + 1, #out do
                                n += 1
                                for _ in string.gmatch(out[i], "\n") do n += 1 end
                        end
                        out[mark] = pad .. "--@" .. n .. " " .. (s.chain or "")
                end
        end
end

local function render()
        hub.markers = cfg.fold ~= false and hub.pf ~= nil
        local function collect(block)
                for _, s in block.lines do
                        if s.call then present[s] = true end
                        if s.block then collect(s.block) end
                end
        end
        collect(rootTrace)
        for _, rec in frec do
                collect(rec.block)
                if rec.alt then collect(rec.alt) end
        end
        scanBlock(rootTrace, function(s)
                if s.text then markText(s.text) end
                if s.call then markText(s.call) end
                if s.header then markText(s.header) end
        end)
        for id = 1, nextId do
                local p = byId[id]
                local info = infoOf[p]
                if info.kind == "call" and info.stmt and present[info.stmt] and (used[id] or info.forceVar) then
                        info.var = uniqueName(info.hint)
                end
        end
        local out = {}
        renderBlock(rootTrace, 0, out)
        return real.concat(out, "\n")
end

trampEnv = scriptEnv
for _, t in tramps do real.setfenv(t, scriptEnv) end
local function runMain(resumeRunner)
local chunk, cerr
local runner, rs
local fetchwait = false
if resumeRunner then
        runner = urls.__lrm_runner
        urls.__lrm_runner = nil
        chunk = true
        if real.type(runner) ~= "thread" then
                chunk = nil
                cerr = "no suspended run"
        end
else
        chunk, cerr = real.loadstring(__source, "=Script")
end
local status
if not chunk then
        status = (resumeRunner and "resume error: " or "compile error: ") .. real.tostring(cerr)
else
        if not resumeRunner then
        if cfg.prelude then
                local pf = real.loadstring(cfg.prelude, "=prelude")
                real.setfenv(pf, { G = envTable._G, genv = genv, rawset = real.rawset, shared = envTable.shared, game = envTable.game, env = envTable,
                        setprop = function(p, k, v) infoOf[p].props[k] = v end })
                pf()
                for t, shadow in real.next, hub.genvShadow or {} do
                        for k, v in real.next, t do shadow[k] = v end
                end
        end
        if cfg.plugin_rt then
                local pf, perr = real.loadstring(cfg.plugin_rt, "=plugin_rt")
                if not pf then real.error("plugin runtime: " .. real.tostring(perr)) end
                pf({ env = envTable, hub = hub, real = real, cfg = cfg, isP = isP, info = infoOf })
        end
        for _, lib in { "string", "math", "table", "os", "debug", "buffer", "utf8", "task", "bit32", "coroutine", "vector" } do
                local t = real.rawget(envTable, lib)
                if real.type(t) == "table" and not table.isfrozen(t) then table.freeze(t) end
        end
        real.setfenv(chunk, scriptEnv)
        local handler = function(e)
                if e == loopMark or e == abort or e == tamper then return e end
                return real.tostring(e) .. "\n" .. debug.traceback()
        end
        runner = coroutine.create(function()
                real.setfenv(0, scriptEnv)
                return real.xpcall(chunk, handler)
        end)
end
deferred.runner = runner
deferred.running = false
while true do
        rs = table.pack(coroutine.resume(runner))
        if rs[1] and rs[2] == abort and coroutine.status(runner) == "suspended" then rs = { false, abort, n = 2 } end
        if rs[1] and real.type(rs[2]) == "string" and real.sub(rs[2], 1, 9) == "__LRMRES " then
                urls.__lrm_runner = runner
                fetchwait = true
        end
        break
end
if not fetchwait then
        real.pcall(hub.syncGenv)
        local mainOk = rs[1] and rs[2] ~= false or (rs[1] and coroutine.status(runner) == "suspended")
        local r2 = coroutine.create(function()
                real.setfenv(0, scriptEnv)
                if mainOk then runDeferred() end
                runHandlers()
        end)
        coroutine.resume(r2)
        local ok, err
        if not rs[1] then
                ok, err = false, rs[2]
        elseif coroutine.status(runner) == "suspended" then
                ok, err = true, nil
        else
                ok, err = rs[2], rs[3]
        end
        popTo(1)
        if cfg.inline_probe and not ok and err ~= tamper and envTable.__opdump then
                cfg.dump_last = cfg.dump_err or 3000
                envTable.__opdump()
        end
        if ok then
                status = "finished"
        elseif err == loopMark then
                status = "stopped in an endless loop (truncated)"
        elseif err == abort then
                status = "aborted: " .. real.tostring(abortReason)
        elseif err == tamper then
                status = "Luraph anti-tamper triggered in the main thread (run stopped)"
        else
                status = "script error: " .. real.tostring(err)
        end
        end
end

if fetchwait then
        real.print(servePad)
        return "fetchwait"
end

local body = render()
local header = {}
real.insert(header, "-- run status: " .. real.gsub(status, "\n", "\n--   "))
real.insert(header, real.fmt("-- %d statements recorded in %.2fs", stmtCount, real.clock() - startClock))
if #urls > 0 then
        real.insert(header, "-- URLs requested:")
        for _, u in real.ipairs(urls) do real.insert(header, "--   " .. u) end
end
if #remotes > 0 then
        real.insert(header, "-- remotes fired/invoked:")
        for _, rp in real.ipairs(remotes) do real.insert(header, "--   " .. exprOf(rp)) end
end
if #unknownGlobals > 0 then
        local names = unknownGlobals
        if #names > 12 then names = { real.unpack(names, 1, 12) } ; real.insert(names, "...") end
        real.insert(header, real.fmt("-- warning: %d unknown global(s) were answered by ever-callable proxies "
                .. "(guessed behaviour, see their call sites): %s", #unknownGlobals, real.concat(names, ", ")))
end
if assumedCmp > 0 then
        real.insert(header, real.fmt("-- warning: %d comparison(s) on opaque values were assumed "
                .. "('<' true, '<=' false); check the 'condition:' comments in the output", assumedCmp))
end

cfg.heartbeat = nil
real.print(markPrefix .. "ENVLOG-BEGIN")
if real.rawget(envTable, "__tr") then
        local tr = envTable.__tr
        local ringSize = tr.n
        for i = real.max(1, tr.total - ringSize + 1), tr.total do
                real.print(markPrefix .. "TR " .. real.tostring(tr[(i - 1) % ringSize + 1]))
        end
end
if trigger then real.print(markPrefix .. "TRIGGER " .. trigger) end
for _, line in real.ipairs(p2dLog) do real.print(markPrefix .. "P2D " .. line) end
if cfg.call_log then hub.dumpCallLog() end
if p2dMiss then real.print(markPrefix .. "P2DMISS") end
for _, hook in real.ipairs(hub.endHooks or {}) do
        local ok, text = real.pcall(hook)
        real.print(ok and text or (markPrefix .. "HOOKERR " .. real.tostring(text)))
end
if cfg.devirt then
        local ok, js = real.pcall(hub.dumpProtos)
        local fs = hub.forceStats
        if fs then
                real.print(real.fmt("%sFORCE calls=%d decoded=%d in %.1fs, %d buffer patches", markPrefix, fs.calls, fs.got,
                        real.clock() - fs.t0, fs.bufs or 0))
        end
        if (hub.unscrambled or 0) > 0 then real.print(markPrefix .. "UNSCRAMBLED " .. hub.unscrambled) end
        real.print(markPrefix .. "PROTOS " .. (ok and js or ("error: " .. real.tostring(js))))
end
for _, key in real.ipairs(newChunks) do
        real.print(markPrefix .. "CHUNK " .. key)
        real.print((real.gsub(newChunks[key], ".", function(c) return real.fmt("%02x", real.byte(c)) end)))
end
real.print(real.concat(header, "\n"))
real.print("")
real.print(body)
if cfg.dump_strings then
        real.print(markPrefix .. "ENVLOG-STRINGS")
        local seen = {}
        for _, s in collected do
                if not seen[s] then
                        seen[s] = true
                        real.print(quote(s))
                end
        end
end
if cfg.audit ~= false then
    for _, event in real.ipairs(real.auditState.events) do
        local ok, encoded = real.pcall(real.json.encode, event)

        if ok then
            real.print(markPrefix .. "AUDIT " .. encoded)
        end
    end

    real.print(markPrefix .. "AUDIT-DROPPED " ..
        real.tostring(real.auditState.dropped))
end
real.print(markPrefix .. "ENVLOG-END")
if cfg.serve then real.print(servePad) end
if native then
        for _, p in real.pairs(byId) do
                local r = realValues[p]
                if r ~= nil and real.typeof(r) == "Instance" then real.pcall(r.Destroy, r) end
        end
        return real.concat(outBuf, "\n")
end
end
if cfg.serve then
        servePad = real.rep(" ", 16384)
        hub.serve = function(req, buf, mode)
                if mode == "http" then
                        local ok2, decoded = real.pcall(function()
                                local m = {}
                                for k, v in real.next, real.json.decode(req) or {} do
                                        m[k] = (real.type(v) == "table" and v)
                                                or { status = 200, body = real.tostring(v) }
                                end
                                return m
                        end)
                        if ok2 then
                                cfg.http_map = decoded
                                for k, v in real.next, decoded do
                                        if real.type(v) == "table" and v.body then
                                                cfg.readfile_map = cfg.readfile_map or {}
                                                cfg.readfile_map["__lrm_session_response"] = v.body
                                        end
                                end
                        end
                        real.print(markPrefix .. "HTTPMAP " .. real.tostring(ok2) .. " keys="
                                .. (function()
                                        local n = 0
                                        if ok2 then
                                                for _ in real.next, decoded do n += 1 end
                                        end
                                        return n
                                end)())
                        real.print(servePad)
                        return
                end
                if mode == "start" and real.type(req) == "string" and #req > 0 then
                        cfg.readfile_map = cfg.readfile_map or {}
                        local bodyv, headerv = req, "{}"
                        local okp, parsed = real.pcall(function() return real.json.decode(req) end)
                        if okp and real.type(parsed) == "table" and real.type(parsed.body) == "string" then
                                bodyv = parsed.body
                                headerv = real.json.encode(parsed.headers or {})
                        end
                        cfg.readfile_map["__lrm_session_response"] = bodyv
                        cfg.readfile_map["__lrm_session_headers"] = headerv
                        real.print(markPrefix .. "RESP-PLANTED " .. real.tostring(#bodyv) .. " hdr=" .. real.tostring(#headerv))
                end
                if mode == "start" then
                        runMain()
                        return
                end
                if mode == "resume" then
                        runMain(true)
                        return
                end
                if mode == "plantdbg" then
                        local function chk(s)
                                local h = 0
                                for i = 1, #s do h = (h + real.byte(s, i) * i) % 65536 end
                                return h
                        end
                        local list = urls.__lrm_plant
                        if real.type(list) ~= "table" then
                                real.print(markPrefix .. "PLANTDBG none")
                        else
                                real.print(markPrefix .. "PLANTDBG entries=" .. real.tostring(#list))
                                for i = 1, #list do
                                        local e = list[i]
                                        if real.type(e) == "table" and real.type(e.body) == "string" then
                                                real.print(markPrefix .. "  [" .. i .. "] body=" .. real.tostring(#e.body)
                                                        .. " url=" .. (real.type(e.url) == "string"
                                                                and (real.tostring(#e.url) .. " chk=" .. real.tostring(chk(e.url))
                                                                        .. " " .. real.sub(e.url, 1, 48) .. ".." .. real.sub(e.url, -10))
                                                                or real.tostring(e.url)))
                                        else
                                                real.print(markPrefix .. "  [" .. i .. "] MALFORMED type=" .. real.type(e)
                                                        .. "/" .. real.type(e and e.body))
                                        end
                                end
                        end
                        real.print(servePad)
                        return
                end
                if mode == "plant" and (real.type(req) == "table"
                        or (real.type(req) == "string" and #req > 0)) then
                        local bodyv, headerv, urlv, reqbodyv
                        if real.type(req) == "table" then
                                bodyv = real.type(req.body) == "string" and req.body or nil
                                headerv = real.type(req.headers) == "table" and req.headers or {}
                                urlv = real.type(req.url) == "string" and req.url or nil
                                reqbodyv = real.type(req.reqbody) == "string" and req.reqbody or nil
                        else
                                local okp3, parsed3 = real.pcall(function() return real.json.decode(req) end)
                                bodyv, headerv, urlv = req, {}, nil
                                if okp3 and real.type(parsed3) == "table" and real.type(parsed3.body) == "string" then
                                        bodyv = parsed3.body
                                        urlv = parsed3.url
                                        if real.type(parsed3.headers) == "table" then headerv = parsed3.headers end
                                        if real.type(parsed3.reqbody) == "string" then reqbodyv = parsed3.reqbody end
                                end
                        end
                        local list = urls.__lrm_plant
                        if real.type(bodyv) ~= "string" then
                                real.print(markPrefix .. "PLANT-BAD (no body)")
                                real.print(servePad)
                                return
                        end
                        if real.type(list) ~= "table" then list = {}; urls.__lrm_plant = list end
                        local replaced = false
                        if real.type(urlv) == "string" then
                                for i = 1, #list do
                                        local e = list[i]
                                        if real.type(e) == "table" and e.url == urlv
                                                and (e.reqbody or nil) == (reqbodyv or nil) then
                                                list[i] = { body = bodyv, headers = headerv, url = urlv, reqbody = reqbodyv }
                                                replaced = true
                                                break
                                        end
                                end
                        end
                        if not replaced then
                                real.insert(list, { body = bodyv, headers = headerv, url = urlv, reqbody = reqbodyv })
                        end
                        real.print(markPrefix .. "PLANT-OK " .. real.tostring(#bodyv) .. " entries="
                                .. real.tostring(#list) .. " url=" .. real.tostring(urlv ~= nil and #urlv or -1))
                        real.print(servePad)
                        return
                end
                if mode == "fetch" then
                        real.print(markPrefix .. "ENVLOG-BEGIN")
                        local ok, js = real.pcall(function() return hub.fetch(req, buf) end)
                        real.print(markPrefix .. "FETCH " .. (ok and js or ("error: " .. real.tostring(js))))
                        real.print(markPrefix .. "ENVLOG-END")
                        real.print(servePad)
                        return
                end
                if hub.fetchEnd then
                        hub.fetchEnd()
                        hub.fetchEnd = nil
                end
                hub.fetch = nil
                cfg.force_req, cfg.force_buf = req, buf
                real.print(markPrefix .. "ENVLOG-BEGIN")
                local ok, js = real.pcall(hub.dumpProtos)
                local fs = hub.forceStats
                if fs then
                        real.print(real.fmt("%sFORCE calls=%d decoded=%d in %.1fs, %d buffer patches", markPrefix, fs.calls, fs.got,
                                real.clock() - fs.t0, fs.bufs or 0))
                end
                real.print(markPrefix .. "PROTOS " .. (ok and js or ("error: " .. real.tostring(js))))
                real.print(markPrefix .. "ENVLOG-END")
                real.print(servePad)
        end
        return hub.serve
end
return runMain()
