local abs, min, max = math.abs, math.min, math.max
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end
local eq, lt, gt = function(a, b) return a == b end, function(a, b) return a < b end, function(a, b) return a > b end

local lib = {
    new = function(exp, seq, env)
        exp = exp or "x"
        if type(exp) == "table" and not seq then exp, seq = "x", exp end
        if type(exp) ~= "string" then return end
        local v, e = exp:match("(.-)=>(.+)")
        v, e = v or "x", e or exp
        local s, f = pcall(loadstring, ("seq, env = seq or {}, env or {} return setfenv(function(%s) return %s end, setmetatable({seq = seq}, {__index = function(t, k) return env[k] or _G[k] or math[k] or string[k] end}))"):format(v, e))
        if s then
            if type(seq) == "table" then
                getfenv(f).seq = seq
            end
            if type(env) == "table" then
                getfenv(f).env = env
            end
            return f()
        end
    end
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<lambda module>' end
})