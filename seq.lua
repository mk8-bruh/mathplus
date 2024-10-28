local _PATH = (...):match("(.-)[^%.]+$")

local abs, min, max = math.abs, math.min, math.max
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end
local eq, lt, gt = function(a, b) return a == b end, function(a, b) return a < b end, function(a, b) return a > b end

local lambda = require(_PATH.."lambda")

local lib, mt
lib = {
	new = function(...)
        local t, r = {...}, {}
        if #t == 0 then return setmetatable({}, mt)
        elseif #t == 1 and type(t[1]) == "table" then t = t[1] end
        for i = 1, #t do r[i] = t[i] end
        return setmetatable(r, mt)
    end,
	is = function(s) return type(s) == "table" and getmetatable(s) == mt end,
	unpack = function(s)
		if lib.is(s) then
			return table.unpack(s)
		end
	end,
	clone = function(s)
		if lib.is(s) then
			return lib.new(s)
		end
	end,
	fromString = function(s)
		if type(s) == 'string' then
			local t = {}
            for p in s:gmatch("[^%(%{%[%)%}%],;]+") do
                if tonumber(p) then table.insert(t, tonumber(p)) else break end
            end
            return lib.new(t)
		end
	end,
    set = function(s, i, v)
        if lib.is(s) and isn(i) and nbetween(i, 1, #s) then
            s[i] = v
            return s
        end
    end,
    add = function(s, v)
        if lib.is(s) then
            table.insert(s, v)
            return s
        end
    end,
    remove = function(s, i)
        if lib.is(s) and isn(i) and nbetween(i, 1, #s) then
            table.remove(s, i)
            return s
        end
    end,
    sub = function(s, a, b)
        if lib.is(s) and isn(a) and isn(b) then
            if a == b and a == 0 then return lib.new() end
            a, b = (a > 0 and a - 1 or a) % #s + 1, (b > 0 and b - 1 or b) % #s + 1
            if a > b then return lib.new() end
            local r = lib.new()
            for i = a, b do r[i-a+1] = s[i] end
            return r
        end
    end,
    sum = function(s, l)
        if lib.is(s) then
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            local v = 0
            for i = 1, #s do if isn(l(s[i])) then v = v + l(s[i]) else return end end
            return v
        end
    end,
    product = function(s, l)
        if lib.is(s) then
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            local v = 0
            for i = 1, #s do if isn(l(s[i])) then v = v * l(s[i]) else return end end
            return v
        end
    end,
    average = function(s, l)
        if lib.is(s) then
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            return s:sum(l) and s:sum(l)/#s or nil
        end
    end,
    min = function(s, l)
        if lib.is(s) then
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            local v = math.huge
            for i = 1, #s do if isn(l(s[i])) then v = math.min(v, l(s[i])) end end
            return v
        end
    end,
    max = function(s, l)
        if lib.is(s) then
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            local v = -math.huge
            for i = 1, #s do if isn(l(s[i])) then v = math.max(v, l(s[i])) end end
            return v
        end
    end,
    sort = function(s, l)
        if lib.is(s) then
            local r = s:clone()
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            table.sort(r, function(a, b) return (isn(l(b)) and l(b) or math.huge) > (isn(l(a)) and l(a) or math.huge)  end)
            return r
        end
    end,
    trans = function(s, l)
        if lib.is(s) then
            local r = lib.new()
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            for i = 1, #s do r[i] = l(s[i]) end
            return r
        end
    end,
    median = function(s, l)
        if lib.is(s) then
            l = (type(l) == "function" and l) or lambda(l, s, getfenv(2)) or lambda("x", s, getfenv(2))
            local r = s:sort(l)
            if r then return #s%2 == 0 and (r[#s/2] + r[#s/2+1])/2 or r[math.ceil(#s/2)] end
        end
    end,
    iter = function(...)
        local t = {...}
        for i = 1, #t do if not lib.is(t[i]) then return end end
        
        return function(t, i)
            i = i + 1
            local v = {}
            for j = 1, #t do if i <= #t[j] then v[j] = t[j][i] else return end end
            return i, table.unpack(v)
        end, t, 0
    end,
    range = function(a, b, s)
        s = s or 1
        if not b then a, b = 1, a end
        if isn(a) and isn(b) and isn(s) then
            local r = lib.new()
            if sign(b - a) ~= sign(s) then return r end
            local x = a
            repeat
                r:add(x)
                x = x + s
            until (b - x) / sign(s) < 0
            return r
        end
    end,
    forrange = function(l, a, b, s)
        s = s or 1
        if not b then a, b = 1, a end
        if isn(a) and isn(b) and isn(s) then
            local r = lib.new()
            l = (type(l) == "function" and l) or lambda(l, r, getfenv(2)) or lambda("x", r, getfenv(2))
            if not l then return end
            if sign(b - a) ~= sign(s) then return r end
            local x = a
            repeat
                r:add(isn(l(x)) and l(x) or x)
                x = x + s
            until (b - x) / sign(s) < 0
            return r
        end
    end,
    segment = function(a, b, s)
        if isn(a) and isn(b) then s = s or math.floor(abs(b - a) + 0.5) end
        if isn(a) and isn(b) and isn(s) then
            s = abs(s)
            local r = lib.new()
            for i = 0, s do
                r:add(a + (b - a)*i/s)
            end
            return r
        end
    end,
    forsegment = function(l, a, b, s)
        if isn(a) and isn(b) then s = s or math.floor(abs(b - a) + 0.5) end
        if isn(a) and isn(b) and isn(s) then
            s = abs(s)
            local r = lib.new()
            l = (type(l) == "function" and l) or lambda(l, r, getfenv(2)) or lambda("x", r, getfenv(2))
            if not l then return end
            for i = 0, s do
                local x = a + (b - a)*i/s
                r:add(isn(l(x)) and l(x) or x)
            end
            return r
        end
    end
}

mt = {
    __concat = function(a, b)
        local r = lib.new()
        for i = 1, #a do r[i] = a[i] end
        for i = 1, #b do r[i + #a] = b[i] end
        return r
    end,
	__add = function(a, b)
		if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, #a --[[math.max(#a, #b)]] do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) + (b[i] or 0) end
            return r
		elseif lib.is(a) and isn(b) then
			local r = lib.new()
            for i = 1, #a do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) + b end
            return r
        end
	end,
	__sub = function(a, b)
		if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, #a --[[math.max(#a, #b)]] do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) - (b[i] or 0) end
            return r
		elseif lib.is(a) and isn(b) then
			local r = lib.new()
            for i = 1, #a do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) - b end
            return r
        end
	end,
	__mul = function(a, b)
		if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, #a --[[math.max(#a, #b)]] do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) * (b[i] or 0) end
            return r
		elseif lib.is(a) and isn(b) then
			local r = lib.new()
            for i = 1, #a do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) * b end
            return r
        end
	end,
	__div = function(a, b)
		if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, #a --[[math.max(#a, #b)]] do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) / (b[i] or 0) end
            return r
		elseif lib.is(a) and isn(b) then
			local r = lib.new()
            for i = 1, #a do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) / b end
            return r
        end
	end,
	__pow = function(a, b)
        if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, #a --[[math.max(#a, #b)]] do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) ^ (b[i] or 0) end
            return r
		elseif lib.is(a) and isn(b) then
			local r = lib.new()
            for i = 1, #a do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) ^ b end
            return r
        end
	end,
    __mod = function(a, b)
        if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, #a --[[math.max(#a, #b)]] do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) % (b[i] or 0) end
            return r
		elseif lib.is(a) and isn(b) then
			local r = lib.new()
            for i = 1, #a do if not (isn(a[i]) and isn(b[i])) then return end r[i] = (a[i] or 0) % b end
            return r
        end
    end,
	__unm = function(s)
        local r = lib.new()
        for i = 1, #s do if not isn(s[i]) then return end r[i] = -s[i] end
        return r
    end,
	__tostring = function(s)
        local r = ""
        for i = 1, #s do r = r .. tostring(s[i]) .. (i < #s and ", " or "") end
        return r
    end,
	__index = function(s, k) return lib[k] end
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<sequence module>' end
})