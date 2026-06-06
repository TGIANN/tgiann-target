-- Player/framework helpers: item & group queries, and the framework loader. Frameworks
-- (client/framework/*) override `player.hasPlayerGotGroup` on this table.
local shared = require 'client.utils.shared'

local player = {}
local playerItems = {}

function player.getItems()
    return playerItems
end

---@param filter string | string[] | table<string, number>
---@param hasAny boolean?
---@return boolean
function player.hasPlayerGotItems(filter, hasAny)
    if not playerItems then return true end

    local _type = type(filter)

    if _type == 'string' then
        return (playerItems[filter] or 0) > 0
    elseif _type == 'table' then
        local tabletype = table.type(filter)

        if tabletype == 'hash' then
            for name, amount in pairs(filter) do
                local hasItem = (playerItems[name] or 0) >= amount

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        elseif tabletype == 'array' then
            for i = 1, #filter do
                local hasItem = (playerItems[filter[i]] or 0) > 0

                if hasAny then
                    if hasItem then return true end
                elseif not hasItem then
                    return false
                end
            end
        end
    end

    return not hasAny
end

---stub; overridden by the active framework module
---@param filter string | string[] | table<string, number>
---@return boolean
function player.hasPlayerGotGroup(filter)
    return true
end

SetTimeout(0, function()
    if shared.hasExport('ox_inventory.Items') then
        setmetatable(playerItems, {
            __index = function(self, index)
                self[index] = exports.ox_inventory:Search('count', index) or 0
                return self[index]
            end
        })

        AddEventHandler('ox_inventory:itemCount', function(name, count)
            playerItems[name] = count
        end)
    end

    if shared.hasExport('ox_core.GetPlayer') then
        require 'client.framework.ox'
    elseif shared.hasExport('es_extended.getSharedObject') then
        require 'client.framework.esx'
    elseif shared.hasExport('qb-core.GetCoreObject') then
        require 'client.framework.qb'
    elseif shared.hasExport('qbx_core.HasGroup') then
        require 'client.framework.qbx'
    elseif shared.hasExport('ND_Core.getPlayer') then
        require 'client.framework.nd'
    end
end)

return player
