local _PATH = (...):match("(.-)[^%.]+$")

local sqrt, abs, sin, cos, asin, acos, atan2 = math.sqrt, math.abs, math.sin, math.cos, math.asin, math.acos, math.atan2
local sign = function(x) return x ~= 0 and x / abs(x) or 0 end
local fstr = string.format
local ntostr = function(n) return tostring(n):match("^(.-%..-)0000.*$") or tostring(n) end
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
            local x, y, z, w = s:match('^%s*[%(%{%[]?(.-)[,;](.-)[,;](.-)[,;](.-)[%)%}%]]?^%s*')
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
            return v.len > 0 and v / v.len or lib.new(0, 0, 0, 0)
        end
    end,
    conjugate = function(q)
        if lib.is(q) then
            return lib.new(-q.x, -q.y, -q.z, q.w)
        end
    end,
    inverse = function(q)
        if lib.is(q) then
            return q:conjugate() / q.sqrLen
        end
    end,
    dot = function(a, b)
        if lib.is(a) and lib.is(b) then
            return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
        end
    end,
    axisAngle = function(v, a)
        if vec3.is(v) and isn(a) then
            v = v.norm
            return lib.new(v.x * sin(a / 2), v.y * sin(a / 2), v.z * sin(a / 2), cos(a / 2))
        end
    end,
    toAxisAngle = function(q)
        if lib.is(q) then
            local v = vec3(q.x, q.y, q.z)
            return v.norm, 2 * atan2(v.len, q.w)
        end
    end,
    fromEuler = function(x, y, z)
        local r = vec3.is(x) and x or vec3(x, y, z)
        if vec3.is(r) then
            local cx, sx = cos(r.x / 2), sin(r.x / 2)
            local cy, sy = cos(r.y / 2), sin(r.y / 2)
            local cz, sz = cos(r.z / 2), sin(r.z / 2)
            return lib.new(0, 0, sz, cz) * lib.new(sx, 0, 0, cx) * lib.new(0, sy, 0, cy)
        end
    end,
    toEuler = function(q)
        if lib.is(q) then
            local s = 2 * (q.w * q.x - q.y * q.z)
            return vec3(
                abs(s) >= 1 and sign(x) * math.pi/2 or asin(s),
                atan2(2 * (q.w * q.y + q.x * q.z), 1 - 2 * (q.x * q.x + q.y * q.y)),
                atan2(2 * (q.w * q.z + q.x * q.y), 1 - 2 * (q.x * q.x + q.z * q.z))
            )
        end
    end,
    between = function(a, b)
        if vec3.is(a) and vec3.is(b) then
            return lib.axisAngle(a:cross(b), a:angle(b))
        end
    end,
    rotate = function(q, v)
        if lib.is(q) and vec3.is(v) then
            local qn = q.norm
            local qc = qn.conj
            return vec3(lib.unpack(qn * v * qc))
        end
    end
}

mt = {
    __add = function(a, b)
        if lib.is(a) and lib.is(b) then
            return lib.new(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
        end
    end,
    __sub = function(a, b)
        if lib.is(a) and lib.is(b) then
            return lib.new(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
        end
    end,
    __mul = function(a, b)
        if lib.is(a) and lib.is(b) then
            return lib.new(
                a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
                a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
                a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
            )
        elseif lib.is(a) and vec3.is(b) then
            return a * lib.new(b.x, b.y, b.z, 0)
        elseif vec3.is(a) and lib.is(b) then
            return lib.new(a.x, a.y, a.z, 0) * b
        elseif lib.is(a) and isn(b) then
            return lib.new(a.x * b, a.y * b, a.z * b, a.w * b)
        elseif isn(a) and lib.is(b) then
            return lib.new(a * b.x, a * b.y, a * b.z, a * b.w)
        end
    end,
    __div = function(a, b)
        if lib.is(a) and isn(b) then
            return lib.new(a.x / b, a.y / b, a.z / b, a.w / b)
        end
    end,
    __unm = function(q) return lib.new(-q.x, -q.y, -q.z, -q.w) end,
    __len = function(q) return q.len end,
    __tostring = function(q) return fstr('<%s, %s, %s, %s>', ntostr(q.x), ntostr(q.y), ntostr(q.z), ntostr(q.w)) end,
    __index = function(q, k)
        if k == "len" then return sqrt(q.sqrLen)
        elseif k == "sqrLen" then return q:dot(q)
        elseif k == "norm" then return q:normal()
        elseif k == "conj" then return q:conjugate()
        elseif k == "inv" then return q:inverse()
        else return lib[k]
        end
    end
}

return setmetatable({}, {
    __index = lib,
    __newindex = function() end,
    __call = function(t, ...) return lib.new(...) end,
    __metatable = {},
    __tostring = function() return '<quaternion module>' end
})
