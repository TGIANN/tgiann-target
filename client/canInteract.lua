-- canInteract guard. Callbacks run on the detection thread, so a heavy one would
-- stutter targeting. Results are memoised per option+entity for a short window using
-- ox_lib's shared cache (cache(key, func, timeout)), so the callback isn't re-run on
-- every detection pass.
local config = require 'client.config'

local ttl = config.canInteractInterval

---@param option TargetOption
---@param entity? number
---@param distance number
---@param coords vector3
---@param bone? number
---@return boolean canInteract
return function(option, entity, distance, coords, bone)
    return cache(('ci:%s:%s'):format(option, entity or 0), function()
        local ok, resp = pcall(option.canInteract, entity, distance, coords, option.name, bone)
        return (ok and resp) and true or false
    end, ttl)
end
