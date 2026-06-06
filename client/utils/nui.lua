-- NUI messaging helper.
local nui = {}

---@param action string
---@param data? table | string | number | boolean
function nui.sendNui(action, data)
    SendNUIMessage({ action = action, data = data })
end

return nui
