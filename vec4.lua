local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end

local lib, mt
lib = {
	new = function(x, y, z, w)
        if isn(x) and isn(y) and isn(z) and isn(w) then
            return setmetatable({x = x, y = y, z = z, w = w}, mt)
        end
    end,
	is = function(v) return type(v) == "table" and isn(v.x) and isn(v.y) and isn(v.z) and isn(v.w) and getmetatable(v) == mt end,
	unpack = function(v)
		if lib.is(v) then
			return v.x, v.y, v.z, v.w
		end
	end,
	clone = function(v)
		if lib.is(v) then
			return lib.new(v.x, v.y, v.z, v.w)
		end
	end,
	fromString = function(s)
		if type(s) == 'string' then
			local x, y, z, w = s:match('[%(%{%[]?(.-)[,;](.-)[,;](.-)[,;](.-)[%)%}%]]?')
			if tonumber(x) and tonumber(y) and tonumber(z) and tonumber(w) then
				return lib.new(tonumber(x), tonumber(y), tonumber(z), tonumber(w))
			end
		end
	end,
	convertArray = function(a)
        if type(a) ~= "table" then return end
        local t = {}
        for i,v in ipairs(a) do
            if not lib.is(v) then break end
            table.insert(t, v.x)
            table.insert(t, v.y)
            table.insert(t, v.z)
            table.insert(t, v.w)
        end
        return t
	end,
	normal = function(v)
		if lib.is(v) then
			return v.len > 0 and v/v.len or lib.new(0, 0, 0, 0)
		end
	end,
	dot = function(a, b)
		if lib.is(a) and lib.is(b) then
			return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w
		end
	end,
	lerp = function(a, b, t)
		if lib.is(a) and lib.is(b) and isn(t) then
			return a + (b - a) * t
		end
	end,
	moveTo = function(a, b, d)
		if lib.is(a) and lib.is(b) and isn(d) then
			return a + (b - a):normal() * d
		end
	end,
	project = function(a, b)
        if lib.is(a) and lib.is(b) then
			return a:dot(b) / b.sqrLen * b
		end
	end,
    maxLen = function(v, l)
        if lib.is(v) and isn(l) then
            return v.norm * math.min(v.len, l)
        end
    end,
    minLen = function(v, l)
        if lib.is(v) and isn(l) then
            return v.norm * math.max(v.len, l)
        end
    end,
    clampLen = function(v, a, b)
        if lib.is(v) and isn(a) and isn(b) then
            a, b = math.min(a, b), math.max(a, b)
            return v.norm * math.max(a, math.min(b, v.len))
        end
    end
}

mt = {
	__add = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x+b.x, a.y+b.y, a.z+b.z, a.w+b.w)
		end
	end,
	__sub = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x-b.x, a.y-b.y, a.z-b.z, a.w-b.w)
		end
	end,
	__mul = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x*b.x, a.y*b.y, a.z*b.z, a.w*b.w)
		elseif lib.is(a) and isn(b) then
			return lib.new(a.x*b, a.y*b, a.z*b, a.w*b)
		elseif isn(a) and lib.is(b) then
			return lib.new(a*b.x, a*b.y, a*b.z, a*b.w)
		end
	end,
	__div = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x/b.x, a.y/b.y, a.z/b.z, a.w/b.w)
		elseif lib.is(a) and isn(b) then
			return lib.new(a.x/b, a.y/b, a.z/b, a.w/b)
		elseif isn(a) and lib.is(b) then
			return lib.new(a/b.x, a/b.y, a/b.z, a/b.w)
		end
	end,
	__pow = function(a, b)
        if lib.is(a) and isn(b) then
            return lib.new(a.x^b, a.y^b, a.z^b, a.w^b)
        elseif lib.is(a) and lib.is(b) then
            return lib.new(a.x^b.x, a.y^b.y, a.z^b.z, a.w^b.w)
        end
	end,
    __mod = function(a, b)
        if lib.is(a) and isn(b) then
            return lib.new(a.x%b, a.y%b, a.z%b, a.w%b)
        elseif lib.is(a) and lib.is(b) then
            return lib.new(a.x%b.x, a.y%b.y, a.z%b.z, a.w%b.w)
        end
    end,
	__unm = function(v) return lib.new(-v.x, -v.y, -v.z, -v.w) end,
	__len = function(v) return v.len end,
	__tostring = function(v) return fstr('%f,%f,%f,%f', v.x, v.y, v.z, v.w) end,
	__index = function(v, k) if k == "len" then return sqrt(v.len) elseif k == "sqrLen" then return v:dot(v) elseif k == "norm" then return v:normal() else return lib[k] end end
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<4D vector module>' end
})