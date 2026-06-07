local api = require 'client.api'

---@param exportName string
---@param func function
local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_ox_target_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

-- Alias every api function under the ox_target name. Iterating the api table keeps
-- this list in sync automatically when functions are added or removed.
for name, func in pairs(api) do
    if type(func) == 'function' then
        exportHandler(name, func)
    end
end
