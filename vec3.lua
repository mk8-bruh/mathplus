local _PATH = (...):match("(.-)[^%.]+$")

local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local ntostr = function(n) return tostring(n):match("^(.-%..-)0000.*$") or tostring(n) end
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end
local ang = function(x) return math.pi - ((math.pi - x) % (2*math.pi)) end

local lib, mt
lib = {
	new = function(x, y, z)
        if isn(x) and isn(y) and isn(z) then
            return setmetatable({x = x, y = y, z = z}, mt)
        end
    end,
	is = function(v) return type(v) == "table" and isn(v.x) and isn(v.y) and isn(v.z) and getmetatable(v) == mt end,
	unpack = function(v)
		if lib.is(v) then
			return v.x, v.y, v.z
		end
	end,
	clone = function(v)
		if lib.is(v) then
			return lib.new(v.x, v.y, v.z)
		end
	end,
	fromString = function(s)
		if type(s) == 'string' then
			local x, y, z = s:match('^%s*[%(%{%[]?(.-)[,;](.-)[,;](.-)[%)%}%]]?%s*$')
			if tonumber(x) and tonumber(y) and tonumber(z) then
				return lib.new(tonumber(x), tonumber(y), tonumber(z))
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
        end
        return t
	end,
	zero    = function() return lib.new( 0,  0,  0) end,
	one     = function() return lib.new( 1,  1,  1) end,
	left    = function() return lib.new(-1,  0,  0) end,
	right   = function() return lib.new( 1,  0,  0) end,
	up      = function() return lib.new( 0, -1,  0) end,
	down    = function() return lib.new( 0,  1,  0) end,
	back    = function() return lib.new( 0,  0, -1) end,
	forward = function() return lib.new( 0,  0,  1) end,
	normal = function(v)
		if lib.is(v) then
			return v.len > 0 and v/v.len or lib.new(0, 0, 0)
		end
	end,
	dot = function(a, b)
		if lib.is(a) and lib.is(b) then
			return a.x*b.x + a.y*b.y + a.z*b.z
		end
	end,
	cross = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)
		end
	end,
	angle = function(a, b)
		if lib.is(a) and lib.is(b) then
			return (a.len > 0 and b.len > 0) and acos(a:dot(b) / a.len / b.len) or 0
		end
	end,
    signedAngle = function(a, b, n)
        if lib.is(a) and lib.is(b) then
			if not n then
				n = a:cross(b)
			end
			if lib.is(n) then
            	return sign(a:cross(b):dot(n)) * ang(atan2(a:cross(b).len, a:dot(b)))
			end
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
	collinear = function(a, b)
		if lib.is(a) and lib.is(b) then
			local q = b/a
			if q.x == q.y == q.z then
				return q.x
			end
		end
	end,
	project = function(a, b)
        if lib.is(a) and lib.is(b) then
			return a:dot(b) / b.sqrLen * b
		end
	end,
	projectOnPlane = function(a, b)
		if lib.is(a) and lib.is(b) then
			return a - a:project(b)
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
			return lib.new(a.x + b.x, a.y + b.y, a.z + b.z)
		end
	end,
	__sub = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x - b.x, a.y - b.y, a.z - b.z)
		end
	end,
	__mul = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x * b.x, a.y * b.y, a.z * b.z)
		elseif lib.is(a) and isn(b) then
			return lib.new(a.x * b, a.y * b, a.z * b)
		elseif isn(a) and lib.is(b) then
			return lib.new(a * b.x, a * b.y, a * b.z)
		end
	end,
	__div = function(a, b)
		if lib.is(a) and lib.is(b) then
			return lib.new(a.x / b.x, a.y / b.y, a.z / b.z)
		elseif lib.is(a) and isn(b) then
			return lib.new(a.x / b, a.y / b, a.z / b)
		elseif isn(a) and lib.is(b) then
			return lib.new(a / b.x, a / b.y, a / b.z)
		end
	end,
	__pow = function(a, b)
        if lib.is(a) and isn(b) then
            return lib.new(a.x ^ b, a.y ^ b, a.z ^ b)
        elseif lib.is(a) and lib.is(b) then
            return lib.new(a.x ^ b.x, a.y ^ b.y, a.z ^ b.z)
        end
	end,
    __mod = function(a, b)
        if lib.is(a) and isn(b) then
            return lib.new(a.x % b, a.y % b, a.z % b)
        elseif lib.is(a) and lib.is(b) then
            return lib.new(a.x % b.x, a.y % b.y, a.z % b.z)
        end
    end,
	__unm = function(v) return lib.new(-v.x, -v.y, -v.z) end,
	__len = function(v) return v.len end,
	__tostring = function(v) return fstr('(%s, %s, %s)', ntostr(v.x), ntostr(v.y), ntostr(v.z)) end,
	__index = function(v, k) if k == "len" then return sqrt(v.sqrLen) elseif k == "sqrLen" then return v:dot(v) elseif k == "norm" then return v:normal() else return lib[k] end end
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<3D vector module>' end
})