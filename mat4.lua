local _PATH = (...):match("(.-)[^%.]+$")

local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end

local seq  = require(_PATH.."seq" )
local vec2 = require(_PATH.."vec2")
local vec3 = require(_PATH.."vec3")
local vec4 = require(_PATH.."vec4")

local lib, mt
lib = {
	new = function(...)
        local t, r = {...}, {}
        if #t == 0 then return setmetatable({0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}, mt)
        elseif #t == 1 and type(t[1]) == "table" then t = t[1] end
        for i = 1, 16 do if isn(t[i]) then r[i] = t[i] else return end end
        return setmetatable(r, mt)
    end,
	is = function(m) if type(m) == "table" and getmetatable(m) == mt then for i = 1, 16 do if not isn(m[i]) then return false end end else return false end return true end,
	unpack = function(m)
		if lib.is(m) then
			return table.unpack(m)
		end
	end,
	clone = function(m)
		if lib.is(m) then
			return lib.new(m)
		end
	end,
	fromString = function(s)
		if type(s) == 'string' then
			local t = {}
            for p in s:gmatch("[^%(%{%[%)%}%],;]+") do
                if tonumber(p) then table.insert(t, tonumber(p)) else break end
            end
            if #t == 16 then return lib.new(t) end
		end
	end,
    identity = function()
        return lib.new(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
    end,
    get = function(m, x, y)
        if lib.is(m) and isn(x) and isn(y) and nbetween(x, 1, 4) and nbetween(y, 1, 4) then
            return m[x+(y-1)*4]
        end
    end,
    set = function(m, x, y, v)
        if lib.is(m) and isn(x) and isn(y) and nbetween(x, 1, 4) and nbetween(y, 1, 4) and isn(v) then
            m[x+(y-1)*4] = v
            return m
        end
    end,
    getRow = function(m, y)
        if lib.is(m) and isn(y) and nbetween(y, 1, 4) then
            local r = seq()
            for x = 1, 4 do r[x] = m[x+(y-1)*4] end
            return r
        end
    end,
    setRow = function(m, y, r)
        if lib.is(m) and isn(y) and nbetween(y, 1, 4) then
            r = type(r) == "table" and r or m:getRow(r)
            for i = 1, 4 do if not isn(r[i]) then return end end
            for x = 1, 4 do m:set(x, y, r[x]) end
            return m
        end
    end,
    swapRows = function(m, y1, y2)
        if lib.is(m) and isn(y1) and isn(y2) and nbetween(y1, 1, 4) and nbetween(y2, 1, 4) then
            if y1 ~= y2 then
                local r = m:getRow(y1)
                m:setRow(y1, y2):setRow(y2, r)
            end
            return m
        end
    end,
    getColumn = function(m, x)
        if lib.is(m) and isn(x) and nbetween(x, 1, 4) then
            local c = seq()
            for y = 1, 4 do c[y] = m[x+(y-1)*4] end
            return c
        end
    end,
    setColumn = function(m, x, c)
        if lib.is(m) and isn(x) and nbetween(x, 1, 4) then
            c = type(c) == "table" and c or m:getColumn(c)
            for i = 1, 4 do if not isn(c[i]) then return end end
            for y = 1, 4 do m:set(x, y, c[y]) end
            return m
        end
    end,
    swapColumns = function(m, x1, x2)
        if lib.is(m) and isn(x1) and isn(x2) and nbetween(x1, 1, 4) and nbetween(x2, 1, 4) then
            if x1 ~= x2 then
                local c = m:getColumn(x1)
                m:setColumn(x1, x2):setColumn(x2, c)
            end
            return m
        end
    end
}

mt = {
	__add = function(a, b)
		if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, 16 do r[i] = a[i] + b[i] end
            return r
		end
	end,
	__sub = function(a, b)
		if lib.is(a) and lib.is(b) then
			local r = lib.new()
            for i = 1, 16 do r[i] = a[i] - b[i] end
            return r
		end
	end,
	__mul = function(a, b)
        if lib.is(a) then
			if lib.is(b) then
                local r = lib.new()
                for x = 1, 4 do
                    for y = 1, 4 do
                        r:set(x, y, (a:getRow(y) * b:getColumn(x)):sum())
                    end
                end
                return r
            elseif vec2.is(b) then
                local s = seq(b.x, b.y, 0, 1)
                return vec2((a:getRow(1) * s):sum(), (a:getRow(2) * s):sum())
            elseif vec3.is(b) then
                local s = seq(b.x, b.y, b.z, 1)
                return vec3((a:getRow(1) * s):sum(), (a:getRow(2) * s):sum(), (a:getRow(3) * s):sum())
            elseif vec4.is(b) then
                local s = seq(b.x, b.y, b.z, b.w)
                return vec4((a:getRow(1) * s):sum(), (a:getRow(2) * s):sum(), (a:getRow(3) * s):sum(), (a:getRow(4) * s):sum())
            end
        end
	end,
	__tostring = function(v)
        local maxl = {0, 0, 0, 0}
        for i = 0, 12, 4 do
            for j = 1, 4 do
                maxl[j] = math.max(maxl[j], #tostring(v[i+j]))
            end
        end
        local s = ""
        for i = 0, 12, 4 do
            for j = 1, 4 do
                s = s .. string.rep(" ", maxl[j] - #tostring(v[i+j])) .. tostring(v[i+j]) .. (j~=4 and ", " or "")
            end
            if i < 12 then s = s .. ",\n" end
        end
        return s
    end,
	__index = function(v, k) return lib[k] end
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<4x4 matrix module>' end
})