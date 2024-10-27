local _NAME = ...

local lib = {
    vec2   = require(_NAME..".vec2"  ),
    vec3   = require(_NAME..".vec3"  ),
    vec4   = require(_NAME..".vec4"  ),
    mat4   = require(_NAME..".mat4"  ),
    quat   = require(_NAME..".quat"  ),
    seq    = require(_NAME..".seq"   ),
    lambda = require(_NAME..".lambda"),
}

return setmetatable({}, {
	__index = lib,
	__newindex = function() end,
	__metatable = {},
	__tostring = function() return '<math library>' end
})