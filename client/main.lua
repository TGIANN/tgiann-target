if not lib.checkDependency('ox_lib', '3.30.0', true) then return end

lib.locale()

local world = require 'client.utils.world'
local player = require 'client.utils.player'
local nui = require 'client.utils.nui'
local state = require 'client.state'
local api = require 'client.api'
local config = require 'client.config'
local runCanInteract = require 'client.canInteract'
local options = api.getTargetOptions()

require 'client.debug'
require 'client.defaults'
require 'client.compat.qbtarget'

local GetEntityCoords = GetEntityCoords
local GetEntityType = GetEntityType
local GetEntityModel = GetEntityModel
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local IsControlPressed = IsControlPressed
local GetGameTimer = GetGameTimer
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity

-- World/geometry helpers (see client/utils/world.lua).
local getModelDims = world.getModelDims
local getOptionAnchor = world.getOptionAnchor
local drawMarker = world.drawMarker

-- Settings (see client/config.lua).
local checkInterval = config.checkInterval
local holdDuration = config.holdDuration
local interactControl = config.interactControl
local maxDistance = config.maxDistance
local focusRadiusSq = config.focusRadius * config.focusRadius
local debug = config.debug
local themeColor = config.themeColor -- mutable; updated by the tgiann colour sync
local themeTextColor = config.themeTextColor

local sendNui = nui.sendNui
local ebox = require 'client.utils.dui'

-- Centre crosshair: sent only on transition (one message when it appears, one when it
-- hides) rather than every frame.
local crosshairShown = false

---@param show boolean
local function setCrosshair(show)
    if show == crosshairShown then return end
    crosshairShown = show
    sendNui('setCrosshair', show)
end

---Push the current theme colour to both the NUI page and the DUI prompt.
---@param background? string
---@param color? string
local function sendTheme(background, color)
    local data = { background = background or themeColor, color = color or themeTextColor }
    sendNui('setThemeColor', data)
    ebox.setTheme(data)
end

-- Sync with tgiann-core's live colour changes when present.
RegisterNetEvent('tgiann-lumihud:setLumiHudColor', function(colour)
    if type(colour) ~= 'table' then return end
    themeColor = colour.background or themeColor
    themeTextColor = colour.color or themeTextColor
    sendTheme()
end)

-- Shared state ----------------------------------------------------------------
local currentTarget = {}
local currentMenu
local menuHistory = {}
local nearbyZones = {}
local locations = {}
local lastEntity = 0
local activeKey -- persisted focus key (for hysteresis)

-- Menu state (shown when the active target has more than one option)
local menuOpen = false
---@type table?
local menuTarget

---@param option TargetOption
---@param distance number
---@param endCoords vector3
---@param entityHit? number
---@param _? number -- entityType
---@param entityModel? number | false
local function shouldHide(option, distance, endCoords, entityHit, _, entityModel)
    if option.menuName ~= currentMenu then
        return true
    end

    if distance > (option.distance or 7) then
        return true
    end

    if option.groups and not player.hasPlayerGotGroup(option.groups) then
        return true
    end

    if option.items and not player.hasPlayerGotItems(option.items, option.anyItem) then
        return true
    end

    local bone = entityModel and option.bones or nil

    if bone then
        ---@cast entityHit number
        -- ---@cast entityType number
        ---@cast entityModel number

        local _type = type(bone)

        if _type == 'string' then
            local boneId = GetEntityBoneIndexByName(entityHit, bone)

            if boneId ~= -1 and #(endCoords - GetEntityBonePosition_2(entityHit, boneId)) <= 2 then
                bone = boneId
            else
                return true
            end
        elseif _type == 'table' then
            local closestBone, boneDistance

            for j = 1, #bone do
                local boneId = GetEntityBoneIndexByName(entityHit, bone[j])

                if boneId ~= -1 then
                    local dist = #(endCoords - GetEntityBonePosition_2(entityHit, boneId))

                    if dist <= (boneDistance or 1) then
                        closestBone = boneId
                        boneDistance = dist
                    end
                end
            end

            if closestBone then
                bone = closestBone
            else
                return true
            end
        end
    end

    local offset = entityModel and option.offset or nil

    if offset then
        ---@cast entityHit number
        -- ---@cast entityType number
        ---@cast entityModel number

        if not option.absoluteOffset then
            local min, max = getModelDims(entityModel)
            offset = (max - min) * offset + min
        end

        offset = GetOffsetFromEntityInWorldCoords(entityHit, offset.x, offset.y, offset.z)

        if #(endCoords - offset) > (option.offsetSize or 1) then
            return true
        end
    end

    if option.canInteract then
        return not runCanInteract(option, entityHit, distance, endCoords, bone)
    end
end

---@generic T
---@param option T
---@param server? boolean
---@return T
local function getResponse(option, server)
    local response = table.clone(option)
    response.entity = currentTarget.entity
    response.zone = currentTarget.zone
    response.coords = currentTarget.coords
    response.distance = currentTarget.distance

    if server then
        response.entity = response.entity ~= 0 and NetworkGetEntityIsNetworked(response.entity) and
            NetworkGetNetworkIdFromEntity(response.entity) or 0
    end

    response.icon = nil
    response.groups = nil
    response.items = nil
    response.canInteract = nil
    response.onSelect = nil
    response.export = nil
    response.event = nil
    response.serverEvent = nil
    response.command = nil

    return response
end

-- Collect every currently-visible option for a target -------------------------
---Adds the "go back" entry while navigating a sub-menu.
---@param list table
local function addGoBack(list)
    if currentMenu then
        table.insert(list, 1, {
            builtin = 'goback',
            label = locale('go_back'),
            icon = 'fa-solid fa-circle-chevron-left',
        })
    end
end

---@param target table menuTarget describing which entity/zone the options belong to
---@return table options list with { label, icon, typeKey?, optionIndex, zoneIndex? }
local function collectOptions(target)
    local list = {}

    if target.zoneIndex then
        local zone = nearbyZones[target.zoneIndex]

        if zone then
            for i = 1, #zone.options do
                local option = zone.options[i]

                -- Same as ox: raycast distance + crosshair hit + raycast entity.
                if not shouldHide(option, target.dist, target.coords, target.entity or 0) then
                    list[#list + 1] = {
                        label = option.label,
                        icon = option.icon or 'fa-solid fa-circle',
                        arrow = option.openMenu and true or nil,
                        iconColor = option.iconColor,
                        zoneIndex = target.zoneIndex,
                        optionIndex = i,
                    }
                end
            end
        end
    elseif target.global then
        -- Global options (addGlobalOption). Not tied to a location, so they are accessed
        -- through the ALT menu rather than the proximity rings.
        local group = options.__global

        for i = 1, #group do
            local option = group[i]

            if not shouldHide(option, 0, target.coords, 0) then
                list[#list + 1] = {
                    label = option.label,
                    icon = option.icon or 'fa-solid fa-circle',
                    arrow = option.openMenu and true or nil,
                    iconColor = option.iconColor,
                    typeKey = '__global',
                    optionIndex = i,
                }
            end
        end
    else
        -- Entity options. __global is skipped here (it lives in the ALT menu instead).
        for typeKey, group in pairs(options) do
            if typeKey ~= '__global' then
                for i = 1, #group do
                    local option = group[i]

                    if not shouldHide(option, target.dist, target.coords, target.entity, target.entityType, target.entityModel) then
                        list[#list + 1] = {
                            label = option.label,
                            icon = option.icon or 'fa-solid fa-circle',
                            arrow = option.openMenu and true or nil,
                            iconColor = option.iconColor,
                            typeKey = typeKey,
                            optionIndex = i,
                        }
                    end
                end
            end
        end
    end

    addGoBack(list)

    return list
end

-- Build ring locations for one entity's options (excluding __global) and append them
-- to `result`, grouped by anchor. `hideCoords`/`distance` feed shouldHide; the visual
-- anchor comes from getOptionAnchor (bone/offset/centre).
---@param result table
---@param entity number
---@param entityType number
---@param model number | false
---@param hideCoords vector3
---@param distance number
---@param aimed boolean true when the crosshair is on this entity (raycast hit)
local function collectEntityRings(result, entity, entityType, model, hideCoords, distance, aimed)
    options:set(entity, entityType, model or nil)

    local groups = {}
    local order = {}

    for typeKey, group in pairs(options) do
        if typeKey ~= '__global' then
            for i = 1, #group do
                local option = group[i]

                if not shouldHide(option, distance, hideCoords, entity, entityType, model) then
                    local anchor = getOptionAnchor(option, entity, model)
                    local gkey = ('%s:%d:%d:%d'):format(entity,
                        math.floor(anchor.x / 0.25),
                        math.floor(anchor.y / 0.25),
                        math.floor(anchor.z / 0.25))
                    local g = groups[gkey]

                    if not g then
                        g = { coords = anchor, optionRef = option, options = {} }
                        groups[gkey] = g
                        order[#order + 1] = gkey
                    end

                    g.options[#g.options + 1] = {
                        label = option.label,
                        icon = option.icon or 'fa-solid fa-circle',
                        arrow = option.openMenu and true or nil,
                        iconColor = option.iconColor,
                        typeKey = typeKey,
                        optionIndex = i,
                    }
                end
            end
        end
    end

    for idx = 1, #order do
        local g = groups[order[idx]]

        result[#result + 1] = {
            key = 'e:' .. order[idx],
            entity = entity,
            entityModel = model,
            optionRef = g.optionRef,
            coords = g.coords,
            dist = distance,
            aimed = aimed,
            target = {
                coords = hideCoords,
                dist = distance,
                entity = entity,
                entityType = entityType,
                entityModel = model,
            },
            options = g.options,
        }
    end
end

-- Build the list of nearby interactable locations -----------------------------
---@param playerCoords vector3
local function rebuildLocations(playerCoords)
    local hit, entityHit, endCoords = lib.raycast.fromCamera(511, 4, 20)
    entityHit = hit and entityHit or 0
    endCoords = endCoords or playerCoords
    local distance = #(playerCoords - endCoords)
    local entityType, entityModel = 0, 0

    if entityHit > 0 then
        local okType, t = pcall(GetEntityType, entityHit)
        entityType = okType and t or 0

        local okModel, m = pcall(GetEntityModel, entityHit)
        entityModel = okModel and m or 0
    end

    if debug and entityHit ~= lastEntity then
        if lastEntity and lastEntity > 0 then SetEntityDrawOutline(lastEntity, false) end
        if entityHit > 0 and entityType ~= 1 then SetEntityDrawOutline(entityHit, true) end
        lastEntity = entityHit
    end

    currentTarget.entity = entityHit
    currentTarget.coords = endCoords
    currentTarget.distance = distance
    currentTarget.entityType = entityType
    currentTarget.entityModel = entityModel
    currentTarget.zone = nil

    local result = {}

    -- Proximity: registered local/networked entities (intentional targets, e.g.
    -- addLocalEntity) show ambient rings whenever the player is near -- no aiming needed.
    local nearby = api.getNearbyEntities(playerCoords, maxDistance)

    for i = 1, #nearby do
        local entity = nearby[i]

        if entity ~= entityHit then
            local coords = GetEntityCoords(entity)
            collectEntityRings(result, entity, GetEntityType(entity), GetEntityModel(entity),
                coords, #(playerCoords - coords), false)
        end
    end

    -- Aimed entity: uses the precise crosshair hit so bone/offset/canInteract (vehicle
    -- doors etc.) work, and so generic global/model targets appear on what you look at.
    if entityHit > 0 then
        collectEntityRings(result, entityHit, entityType, entityModel, endCoords, distance, true)
    end

    -- Zones: proximity based (shown whenever the player is close enough).
    if Zones then
        local zones = lib.zones.getNearbyZones()
        nearbyZones = zones

        for i = 1, #zones do
            local zone = zones[i]

            if zone.options then
                local inside = zone:contains(playerCoords)
                local zdist = inside and 0 or #(playerCoords - zone.coords)

                if zdist <= maxDistance then
                    local target = { zoneIndex = i, dist = zdist, coords = zone.coords, entity = entityHit }
                    local opts = collectOptions(target)

                    if #opts > 0 then
                        result[#result + 1] = {
                            key = 'zone:' .. i,
                            coords = zone.coords,
                            dist = zdist,
                            isZone = true,
                            target = target,
                            options = opts,
                        }
                    end
                end
            end
        end
    else
        nearbyZones = {}
    end

    return result
end

-- Menu handling ---------------------------------------------------------------
local function closeMenu()
    if not menuOpen then return end

    menuOpen = false
    menuTarget = nil
    currentMenu = nil
    table.wipe(menuHistory)
    state.setNuiFocus(false)
    sendNui('closeMenu')
end

---Opens the clickable option menu for a target that has multiple options.
---@param loc table
local function openMenu(loc)
    menuOpen = true
    menuTarget = loc.target
    currentMenu = nil
    table.wipe(menuHistory)

    state.setNuiFocus(true, true)
    sendNui('clearTargets')
    sendNui('openMenu', {
        title = locale('interact'),
        options = loc.options,
    })
end

local function refreshMenu()
    if not menuOpen or not menuTarget then return end

    local opts = collectOptions(menuTarget)
    sendNui('openMenu', {
        options = opts,
        keepPosition = true,
    })
end

-- Opens the ALT menu listing the global options (addGlobalOption). In ox these were
-- reached by holding ALT; the proximity rings don't show them, so ALT opens them here.
local function openGlobalMenu()
    if menuOpen or state.isDisabled() or IsPauseMenuActive() or IsNuiFocused() then return end

    local playerCoords = GetEntityCoords(cache.ped)
    local target = { global = true, coords = playerCoords }
    local opts = collectOptions(target)

    if #opts == 0 then return end

    currentTarget.entity = 0
    currentTarget.coords = playerCoords
    currentTarget.distance = 0
    currentTarget.entityType = 0
    currentTarget.entityModel = false
    currentTarget.zone = nil

    menuOpen = true
    menuTarget = target
    currentMenu = nil
    table.wipe(menuHistory)

    state.setNuiFocus(true, true)
    sendNui('clearTargets')
    sendNui('openMenu', { title = locale('open_global_menu'), options = opts })
end

---Runs the action attached to a single option (shared by E-trigger and menu click).
---@param ref table { typeKey?, optionIndex, zoneIndex?, builtin? }
---@return boolean openedSubMenu
local function runOption(ref)
    if ref.builtin == 'goback' then
        local menuDepth = #menuHistory
        currentMenu = menuHistory[menuDepth]
        if menuDepth > 0 then menuHistory[menuDepth] = nil end
        refreshMenu()
        return true
    end

    local zone = ref.zoneIndex and nearbyZones[ref.zoneIndex]
    ---@type TargetOption?
    local option = zone and zone.options[ref.optionIndex]
        or (ref.typeKey and options[ref.typeKey] and options[ref.typeKey][ref.optionIndex])

    if not option then return false end

    currentTarget.zone = zone and zone.id or nil

    if option.openMenu then
        menuHistory[#menuHistory + 1] = currentMenu
        currentMenu = option.openMenu ~= 'home' and option.openMenu or nil

        if not menuOpen then
            -- A single-option target whose option opens a menu: promote to a menu view.
            menuTarget = ref.zoneIndex and { zoneIndex = ref.zoneIndex, dist = currentTarget.distance, coords = currentTarget.coords }
                or {
                    coords = currentTarget.coords,
                    dist = currentTarget.distance,
                    entity = currentTarget.entity,
                    entityType = currentTarget.entityType,
                    entityModel = currentTarget.entityModel or false,
                }
            menuOpen = true
            state.setNuiFocus(true, true)
        end

        refreshMenu()
        return true
    end

    local ok, err = pcall(function()
        if option.onSelect then
            option.onSelect(option.qtarget and currentTarget.entity or getResponse(option))
        elseif option.export then
            exports[option.resource or zone.resource][option.export](nil, getResponse(option))
        elseif option.event then
            TriggerEvent(option.event, getResponse(option))
        elseif option.serverEvent then
            TriggerServerEvent(option.serverEvent, getResponse(option, true))
        elseif option.command then
            ExecuteCommand(option.command)
        end
    end)

    if not ok then
        lib.print.error(('error running option "%s": %s'):format(option.name or '?', err))
    end

    return false
end

RegisterNUICallback('select', function(data, cb)
    cb(1)

    local openedSubMenu = runOption(data)

    if not openedSubMenu then
        closeMenu()
    end
end)

RegisterNUICallback('closeMenu', function(_, cb)
    cb("ok")
    closeMenu()
end)

RegisterNUICallback('uiReady', function(_, cb)
    cb("ok")
    sendTheme()
end)

---@type KeybindProps
lib.addKeybind({
    name = 'ox_target_globals',
    defaultKey = config.defaultHotkey,
    defaultMapper = 'keyboard',
    description = locale('open_global_menu'),
    onPressed = openGlobalMenu
})

-- Interact handling -----------------------------------------------------------
local holdStart
local holdConsumed = false

-- Point currentTarget (and the options metatable) at the location being interacted
-- with, so getResponse and runOption resolve against the right entity/zone -- the
-- focused location may be a proximity target that is not the one under the crosshair.
---@param loc table
local function setContext(loc)
    local t = loc.target

    if t.zoneIndex then
        local zone = nearbyZones[t.zoneIndex]
        currentTarget.entity = t.entity or 0
        currentTarget.coords = t.coords
        currentTarget.distance = loc.dist
        currentTarget.entityType = 0
        currentTarget.entityModel = false
        currentTarget.zone = zone and zone.id or nil
    else
        currentTarget.entity = t.entity or 0
        currentTarget.coords = loc.renderCoords or loc.coords
        currentTarget.distance = loc.dist
        currentTarget.entityType = t.entityType
        currentTarget.entityModel = t.entityModel
        currentTarget.zone = nil

        if t.entity and t.entity > 0 then
            options:set(t.entity, t.entityType, t.entityModel or nil)
        end
    end
end

---@param loc table active location
local function handleInteract(loc)
    if IsControlPressed(0, interactControl) then
        if holdConsumed then return end

        holdStart = holdStart or GetGameTimer()

        if GetGameTimer() - holdStart >= holdDuration then
            holdConsumed = true
            holdStart = nil

            setContext(loc)

            if #loc.options > 1 then
                openMenu(loc)
            else
                runOption(loc.options[1])
            end
        end
    else
        holdStart = nil
        holdConsumed = false
    end
end

-- Per-frame render (runs only while there are targets, via a SetInterval) ------
-- Projects locations to screen, picks the focus, draws the ambient sprites + DUI
-- prompt and handles the interact key. Heavy detection stays in the slower loop below.
local function render()
    local playerCoords = GetEntityCoords(cache.ped)
    local candidateIndex, candidateBest
    local anyOnScreen = false

    for i = 1, #locations do
        local loc = locations[i]
        local coords = loc.optionRef
            and getOptionAnchor(loc.optionRef, loc.entity, loc.entityModel)
            or loc.coords
        loc.renderCoords = coords

        local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
        loc.onScreen = onScreen
        loc.sx = x
        loc.sy = y
        loc.dist = #(playerCoords - coords)

        if onScreen then
            anyOnScreen = true
            local dx, dy = x - 0.5, y - 0.5
            loc.d2 = dx * dx + dy * dy

            local focusable = loc.aimed or (loc.isZone and loc.d2 <= focusRadiusSq)

            if focusable and (not candidateBest or loc.d2 < candidateBest) then
                candidateBest = loc.d2
                candidateIndex = i
            end
        else
            loc.d2 = nil
        end
    end

    -- Hysteresis: keep the current focus unless the new candidate is clearly closer.
    local currentIndex
    if activeKey then
        for i = 1, #locations do
            local loc = locations[i]
            if loc.key == activeKey and loc.onScreen and loc.d2
                and (loc.aimed or (loc.isZone and loc.d2 <= focusRadiusSq * 1.8)) then
                currentIndex = i
                break
            end
        end
    end

    local chosenIndex = candidateIndex
    if currentIndex and candidateIndex and currentIndex ~= candidateIndex
        and locations[candidateIndex].d2 >= locations[currentIndex].d2 * 0.7 then
        chosenIndex = currentIndex
    elseif currentIndex and not candidateIndex then
        chosenIndex = currentIndex
    end

    activeKey = chosenIndex and locations[chosenIndex].key or nil

    local effectiveHolding = IsControlPressed(0, interactControl) and not holdConsumed

    -- Ambient markers: in-game sprite for every non-focused location, skipping any
    -- marker right behind the focused E prompt so no ring peeks out from behind it.
    local fx, fy
    if chosenIndex and locations[chosenIndex].onScreen then
        fx, fy = locations[chosenIndex].sx, locations[chosenIndex].sy
    end

    for i = 1, #locations do
        if i ~= chosenIndex then
            local loc = locations[i]
            local behindPrompt = false

            if fx and loc.onScreen then
                local dx, dy = loc.sx - fx, loc.sy - fy
                behindPrompt = (dx * dx + dy * dy) < 0.0009
            end

            if not behindPrompt then
                drawMarker(loc.renderCoords)
            end
        end
    end

    -- Focused E prompt (DUI drawn in-game at the target; content de-duplicated inside).
    local active = chosenIndex and locations[chosenIndex]

    if active and active.onScreen then
        local single = #active.options == 1
        ebox.draw(active.sx, active.sy)
        ebox.set(true, single and active.options[1].label or '', effectiveHolding)
    else
        ebox.set(false)
    end

    setCrosshair(anyOnScreen)

    if chosenIndex then
        handleInteract(locations[chosenIndex])
    end
end

-- Detection loop --------------------------------------------------------------
-- Rebuilds the target list at checkInterval; the per-frame render runs in an interval
-- that only exists while there are targets (no work every frame when idle).
local renderInterval

local function stopRender()
    if not renderInterval then return end -- already stopped; cleanup ran once

    ClearInterval(renderInterval)
    renderInterval = nil
    setCrosshair(false)
    ebox.set(false)
    activeKey = nil
end

CreateThread(function()
    while true do
        if menuOpen then
            sleep = 500
            stopRender()
        elseif not state.isDisabled() and not IsPauseMenuActive() and not lib.progressActive() then
            locations = rebuildLocations(GetEntityCoords(cache.ped))

            if #locations > 0 then
                if not renderInterval then renderInterval = SetInterval(render, 0) end
            elseif renderInterval then
                stopRender()
            end
        elseif renderInterval then
            stopRender()
            locations = {}
        end

        Wait(checkInterval)
    end
end)

if debug then
    CreateThread(function()
        while true do
            for i = 1, #locations do
                local loc = locations[i]
                if loc.renderCoords then
                    DrawMarker(28, loc.renderCoords.x, loc.renderCoords.y, loc.renderCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.0, 0.15, 0.15, 0.15, 255, 42, 24, 100, false, false, 0, true,
                        ---@diagnostic disable-next-line: param-type-mismatch
                        false, false,
                        false)
                end
            end
            Wait(0)
        end
    end)
end
