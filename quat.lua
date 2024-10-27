local _PATH = (...):match("(.-)[^%.]+$")

local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local isn, nbetween = function(x) return type(x) == 'number' end, function(x, a, b) return x >= a and x <= b end

local vec3 = require(_PATH.."vec3")

local lib, mt
lib = {
	new = function(x, y, z, w)
        if isn(x) and isn(y) and isn(z) and isn(w) then
            return setmetatable({x = x, y = y, z = z, w = w}, mt)
        end
    end,
	is = function(q) return type(q) == "table" and isn(q.x) and isn(q.y) and isn(q.z) and isn(q.w) and getmetatable(q) == mt end,
	unpack = function(q)
		if lib.is(q) then
			return q.x, q.y, q.z, q.w
		end
	end,
	clone = function(q)
		if lib.is(q) then
			return lib.new(q.x, q.y, q.z, q.w)
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
    identity = function()
        return lib.new(0, 0, 0, 1)
    end,
    normal = function(v)
		if lib.is(v) then
			return v.len > 0 and v/v.len or lib.new(0, 0, 0, 0)
		end
	end,
    conjugate = function(q)
        if lib.is(q) then
            return lib.new(-q.x, -q.y, -q.z, q.w)
        end
    end,
    dot = function(a, b)
		if lib.is(a) and lib.is(b) then
			return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w
		end
	end,
    axisAngle = function(v, a)
        if vec3.is(v) and isn(a) then
            v = v.norm
            return lib.new(v.x * sin(a/2), v.y * sin(a/2), v.z * sin(a/2), cos(a/2))
        end
    end,
    toAxisAngle = function(q)
        if lib.is(q) then
            local v = vec3(q.x, q.y, q.z)
            return v.norm, 2*atan2(v.len, q.w)
        end
    end,
    fromEuler = function(x, y, z)
        local r = vec3.is(x) and x or vec3(x, y, z)
        if vec3.is(r) then
            local cx, sx = cos(x/2), sin(x/2)
            local cy, sy = cos(y/2), sin(y/2)
            local cz, sz = cos(z/2), sin(z/2)
            return lib.new(
                sz * cx * cy - cz * sx * sy,
                cz * sx * cy + sz * cx * sy,
                cz * cx * sy - sz * sx * cy,
                cz * cx * cy + sz * sx * sy
            )
        end
    end,
    euler = function(q)
        if lib.is(q) then
            return vec3(
                2*atan2(sqrt(1 + 2*(q.w * q.y - q.x * q.z)), sqrt(1 - 2*(q.w * q.y - q.x * q.z))) - math.pi/2,
                atan2(2*(q.w * q.z + q.x * q.y), 1 - 2*(q.y * q.y + q.z * q.z)),
                atan2(2*(q.w * q.x + q.y * q.z), 1 - 2*(q.x * q.x + q.y * q.y))
            )
        end
    end,
    between = function(a, b)
        if vec3.is(a) and vec3.is(b) then
            return lib.axisAngle(a:cross(b).norm, a:angle(b))
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
			return lib.new(
                a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y,
                a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x,
                a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w,
                a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z
            )
		elseif lib.is(a) and vec3.is(b) then
			return vec3(
                a.w*b.x + a.y*b.z - a.z*b.y,
                a.w*b.y + a.z*b.x - a.x*b.z,
                a.w*b.z + a.x*b.y - a.y*b.x
            )
        elseif lib.is(a) and isn(b) then
            return lib.new(a.x*b, a.y*b, a.z*b, a.w*b)
        end
	end,
    __div = function(a, b)
        if lib.is(a) and isn(b) then
            return lib.new(a.x/b, a.y/b, a.z/b, a.w/b)
        end
    end,
	__unm = function(v) return lib.new(-v.x, -v.y, -v.z, -v.w) / v.sqrLen end,
	__len = function(v) return v.len end,
	__tostring = function(v) return fstr('%f,%f,%f,%f', v.x, v.y, v.z, v.w) end,
	__index = function(v, k) if k == "len" then return sqrt(v.len) elseif k == "sqrLen" then return v:dot(v) elseif k == "norm" then return v:normal() elseif k == "conj" then return v:conjugate() else return lib[k] end end
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__call = function(t,...) return lib.new(...) end,
	__metatable = {},
	__tostring = function() return '<quaternion module>' end
})