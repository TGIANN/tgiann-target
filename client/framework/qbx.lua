if not lib.checkDependency('qbx_core', '1.18.0', true) then return end

local QBX = exports.qbx_core
local player = require 'client.utils.player'

---@diagnostic disable-next-line: duplicate-set-field
function player.hasPlayerGotGroup(filter)
    return QBX:HasGroup(filter)
end
