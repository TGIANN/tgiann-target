if not lib.checkDependency('ox_core', '0.21.3', true) then return end

local Ox = require '@ox_core.lib.init' --[[@as OxClient]]
local player = require 'client.utils.player'
local oxPlayer = Ox.GetPlayer()

---@diagnostic disable-next-line: duplicate-set-field
function player.hasPlayerGotGroup(filter)
    return oxPlayer.getGroup(filter)
end
