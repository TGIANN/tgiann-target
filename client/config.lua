-- Resolved convar settings, shared across the client modules. Convars resolve under the
-- current resource name first, then tgiann-target (see client/utils/convar.lua).
local convar = require 'client.utils.convar'

local checkInterval = convar.int('checkInterval', 250)

return {
    -- Detection cadence (ms); targets are re-scanned this often.
    checkInterval = checkInterval,
    -- How long the interact key must be held (ms) before it triggers.
    holdDuration = convar.int('holdDuration', 600),
    -- Control index used to interact (38 = "E" / INPUT_PICKUP).
    interactControl = convar.int('interactKey', 38),
    -- Label shown inside the on-screen key button.
    interactKeyLabel = convar.str('interactKeyLabel', 'E'),
    -- Distance (m) over which ambient markers/targets are considered.
    maxDistance = convar.float('maxDistance', 10.0),
    -- Reticle radius (0..1 screen) within which a coordinate target focuses.
    focusRadius = convar.float('focusRadius', 0.1),
    -- On-screen height (0..1) of the DUI E-prompt sprite.
    duiScale = convar.float('duiScale', 0.05),
    -- On-screen width (0..1) of the in-game ambient ring sprite.
    ringSize = convar.float('ringSize', 0.015),
    -- How often (ms) canInteract results may be re-evaluated.
    canInteractInterval = convar.int('canInteractInterval', checkInterval),
    -- Theme colours (match tgiann-core; synced live via tgiann-lumihud).
    themeColor = convar.str('themeColor', '#36ff9f'),
    themeTextColor = convar.str('themeTextColor', '#252525'),
    -- Keybind that opens the global option menu.
    defaultHotkey = convar.str('defaultHotkey', 'LMENU'),
    debug = convar.bool('debug', false),
}
