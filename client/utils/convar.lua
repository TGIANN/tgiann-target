-- Reads convars under the current resource name first, then "tgiann-target" as a fallback,
-- so the script keeps working under a renamed resource (e.g. tgiann-target) while still
-- honouring any existing tgiann-target:* convars.
local convar = {}

local prefixes = { cache.resource .. ':', 'tgiann-target:' }
-- A plain-string sentinel (a null byte gets truncated to "" through the native call,
-- which would make unset convars look set and break string/bool defaults).
local UNSET = '__target_convar_unset__'

---@param key string
---@return string?
local function raw(key)
    for i = 1, #prefixes do
        local value = GetConvar(prefixes[i] .. key, UNSET)
        if value ~= UNSET then return value end
    end

    return nil
end

---@param key string
---@param default integer
---@return integer
function convar.int(key, default)
    local v = raw(key)
    local value = v and tonumber(v)
    return value and math.floor(value) or default
end

---@param key string
---@param default number
---@return number
function convar.float(key, default)
    local v = raw(key)
    return v and tonumber(v) or default
end

---@param key string
---@param default string
---@return string
function convar.str(key, default)
    return raw(key) or default
end

---@param key string
---@param default boolean
---@return boolean
function convar.bool(key, default)
    local v = raw(key)
    if v == nil then return default end
    return v == '1' or v == 'true'
end

return convar
