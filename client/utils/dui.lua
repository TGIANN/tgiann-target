-- The focused "E" prompt rendered as a DUI texture, drawn in-game with DrawSprite so
-- its position updates without a NUI message every frame. Only its content/theme go
-- over a message. Exposes draw/set/setTheme; manages the DUI lifecycle internally.
local config = require 'client.config'

local DrawSprite = DrawSprite

local ebox = {}

local duiObj
local ready = false
local lastSig
local pendingTheme

-- Wide enough that long labels don't clip; only the left part holds the box+label,
-- the rest is transparent. Must match #dui-root in css/dui.css.
local DUI_W, DUI_H = 1024, 160
local RATIO = DUI_W / DUI_H
local BTN_FX = (20 + 48) / DUI_W -- key box centre as a fraction of canvas width
local scale = config.duiScale
local aspect = GetAspectRatio(false)

CreateThread(function()
    duiObj = lib.dui:new({
        url = ('nui://%s/web/build/dui.html'):format(cache.resource),
        width = DUI_W,
        height = DUI_H,
    })

    -- Fallback in case the page's eboxReady callback never arrives.
    SetTimeout(3000, function() ready = true end)
end)

---Send/refresh the accent theme colour to the DUI page.
---@param data { background: string, color: string }
function ebox.setTheme(data)
    pendingTheme = data
    if duiObj then duiObj:sendMessage({ action = 'setThemeColor', data = data }) end
end

-- The page signals when it has loaded so the theme reaches it and content re-sends.
RegisterNUICallback('eboxReady', function(_, cb)
    cb('ok')
    ready = true
    lastSig = nil
    if pendingTheme then ebox.setTheme(pendingTheme) end
end)

---Update the prompt content. De-duplicated: only sends when it actually changes.
---@param visible boolean
---@param label? string
---@param holding? boolean
function ebox.set(visible, label, holding)
    if not duiObj then return end

    local sig = visible and ('%s|%s'):format(label or '', tostring(holding)) or 'none'
    if sig == lastSig then return end
    lastSig = sig

    duiObj:sendMessage({
        action = 'setEbox',
        data = {
            visible = visible,
            key = config.interactKeyLabel,
            label = label or '',
            holding = holding or false,
            holdDuration = config.holdDuration,
        },
    })
end

---Draw the prompt at the given (normalised) screen position. No-op until loaded.
---@param sx number
---@param sy number
function ebox.draw(sx, sy)
    if not (duiObj and ready) then return end

    local h = scale
    local w = h * RATIO / aspect
    DrawSprite(duiObj.dictName, duiObj.txtName, sx + w * (0.5 - BTN_FX), sy, w, h, 0.0, 255, 255, 255, 255)
end

return ebox
