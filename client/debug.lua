AddEventHandler('tgiann-target:debug', function(data)
    if data.entity and GetEntityType(data.entity) > 0 then
        data.archetype = GetEntityArchetypeName(data.entity)
        data.model = GetEntityModel(data.entity)
    end

    print(json.encode(data, { indent = true }))
end)

if not require('client.config').debug then return end

local tgiannTarget = exports[cache.resource]
local drawZones = false

-- A self-contained export so the `export` option type can be demonstrated below.
exports('debugExport', function(data)
    lib.notify({ title = cache.resource, description = 'export called (debugExport)', type = 'success' })
    print('[debugExport]', json.encode(data, { indent = true }))
end)

--#region Zones -----------------------------------------------------------------

-- Box zone with rotation.
tgiannTarget:addBoxZone({
    coords = vec3(442.5363, -1017.666, 28.85637),
    size = vec3(3, 3, 3),
    rotation = 45,
    debug = drawZones,
    drawSprite = true,
    options = {
        {
            name = 'debug_box',
            event = 'tgiann-target:debug',
            icon = 'fa-solid fa-cube',
            label = locale('debug_box'),
        }
    }
})

-- Sphere zone.
tgiannTarget:addSphereZone({
    coords = vec3(440.5363, -1015.666, 28.85637),
    radius = 3,
    debug = drawZones,
    drawSprite = true,
    options = {
        {
            name = 'debug_sphere',
            event = 'tgiann-target:debug',
            icon = 'fa-solid fa-circle',
            label = locale('debug_sphere'),
        }
    }
})

-- Poly zone (arbitrary shape defined by points + thickness).
tgiannTarget:addPolyZone({
    points = {
        vec3(435.0, -1020.0, 28.85),
        vec3(438.0, -1020.0, 28.85),
        vec3(438.0, -1023.0, 28.85),
        vec3(435.0, -1023.0, 28.85),
    },
    thickness = 3,
    debug = drawZones,
    drawSprite = true,
    options = {
        {
            name = 'debug_poly',
            event = 'tgiann-target:debug',
            icon = 'fa-solid fa-draw-polygon',
            iconColor = '#f59e0b',
            label = 'Poly Zone',
        }
    }
})

--#endregion
--#region Models & globals ------------------------------------------------------

tgiannTarget:addModel(`police`, {
    {
        name = 'debug_model',
        event = 'tgiann-target:debug',
        icon = 'fa-solid fa-handcuffs',
        label = locale('debug_police_car'),
    }
})

tgiannTarget:addGlobalPed({
    {
        name = 'debug_ped',
        event = 'tgiann-target:debug',
        icon = 'fa-solid fa-male',
        label = locale('debug_ped'),
    }
})

tgiannTarget:addGlobalVehicle({
    {
        name = 'debug_vehicle',
        event = 'tgiann-target:debug',
        icon = 'fa-solid fa-car',
        label = locale('debug_vehicle'),
    }
})

tgiannTarget:addGlobalObject({
    {
        name = 'debug_object',
        event = 'tgiann-target:debug',
        icon = 'fa-solid fa-bong',
        label = locale('debug_object'),
    }
})

-- Global option attached to every target, opening a sub-menu.
tgiannTarget:addGlobalOption({
    {
        name = 'debug_global',
        icon = 'fa-solid fa-globe',
        label = locale('debug_global'),
        openMenu = 'debug_global'
    }
})

tgiannTarget:addGlobalOption({
    {
        name = 'debug_global2',
        event = 'tgiann-target:debug',
        icon = 'fa-solid fa-globe',
        label = locale('debug_global') .. ' 2',
        menuName = 'debug_global'
    }
})

local debugPed

CreateThread(function()
    local model = `a_m_y_business_01`

    if not lib.requestModel(model, 10000) then
        return lib.print.warn('failed to load debug ped model')
    end

    local coords = vec4(448.7148, -1019.7668, 27.4950, 272.2927)
    debugPed = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)

    SetEntityInvincible(debugPed, true)
    FreezeEntityPosition(debugPed, true)
    SetBlockingOfNonTemporaryEvents(debugPed, true)
    SetModelAsNoLongerNeeded(model)

    tgiannTarget:addLocalEntity(debugPed, {
        -- 1) Simple: triggers an event, has a coloured icon.
        {
            name = 'debug_ped_talk',
            icon = 'fa-solid fa-comment',
            iconColor = '#22c55e',
            label = 'Talk',
            onSelect = function(data)
                lib.notify({ title = 'NPC', description = 'Hello traveller!', type = 'info' })
                print('[debug_ped_talk]', json.encode(data, { indent = true }))
            end
        },

        -- 2) Distance-limited option (only shows when very close).
        {
            name = 'debug_ped_search',
            icon = 'fa-solid fa-hand',
            label = 'Search (close range)',
            distance = 1.5,
            event = 'tgiann-target:debug',
        },

        -- 3) canInteract: only shown while on foot (not in a vehicle).
        {
            name = 'debug_ped_onfoot',
            icon = 'fa-solid fa-person-walking',
            label = 'On foot only',
            canInteract = function()
                return cache.vehicle == nil
            end,
            onSelect = function()
                lib.notify({ description = 'On-foot interaction', type = 'success' })
            end
        },

        -- 4) Requires an item (ox_inventory): only shows if the player has 'water'.
        {
            name = 'debug_ped_item',
            icon = 'fa-solid fa-bottle-water',
            label = 'Give water (requires water item)',
            items = 'water',
            event = 'tgiann-target:debug',
        },

        -- 5) Requires a group/job (framework): only police can see this.
        {
            name = 'debug_ped_group',
            icon = 'fa-solid fa-shield-halved',
            label = 'Police only',
            groups = 'police',
            event = 'tgiann-target:debug',
        },

        -- 6) export type (calls debugExport defined above).
        {
            name = 'debug_ped_export',
            icon = 'fa-solid fa-plug',
            label = 'Call export',
            export = cache.resource .. '.debugExport',
        },

        -- 7) Runs a command.
        {
            name = 'debug_ped_command',
            icon = 'fa-solid fa-terminal',
            label = 'Run command (/coords)',
            command = 'coords',
        },

        -- 8) Triggers a server event (must be handled server-side).
        {
            name = 'debug_ped_serverevent',
            icon = 'fa-solid fa-server',
            label = 'Trigger server event',
            serverEvent = 'tgiann-target:debug',
        },

        -- 9) Main option that opens a sub-menu.
        {
            name = 'debug_ped_actions',
            icon = 'fa-solid fa-list',
            label = 'Actions',
            openMenu = 'ped_actions',
        },
    })

    -- Sub-menu: 'ped_actions' (linked to this menu via menuName).
    tgiannTarget:addLocalEntity(debugPed, {
        {
            name = 'ped_action_wave',
            menuName = 'ped_actions',
            icon = 'fa-solid fa-hand-spock',
            label = 'Wave',
            onSelect = function()
                lib.notify({ description = 'You waved', type = 'info' })
            end
        },
        {
            name = 'ped_action_give',
            menuName = 'ped_actions',
            icon = 'fa-solid fa-gift',
            label = 'Give item',
            event = 'tgiann-target:debug',
        },
        -- Opens a deeper sub-menu.
        {
            name = 'ped_action_more',
            menuName = 'ped_actions',
            icon = 'fa-solid fa-ellipsis',
            label = 'More',
            openMenu = 'ped_more',
        },
    })

    -- Second-level sub-menu: 'ped_more'.
    tgiannTarget:addLocalEntity(debugPed, {
        {
            name = 'ped_more_secret',
            menuName = 'ped_more',
            icon = 'fa-solid fa-user-secret',
            label = 'Secret action',
            iconColor = '#ef4444',
            event = 'tgiann-target:debug',
        },
    })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if debugPed and DoesEntityExist(debugPed) then
        DeleteEntity(debugPed)
    end
end)
