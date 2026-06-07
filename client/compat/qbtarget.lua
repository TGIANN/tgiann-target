-- qb-target compatibility layer. Lets scripts written for qb-target work with this
-- resource by translating its exports into the tgiann-target API.

local api = require 'client.api'

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_qb-target_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

-- Merge qb-target job/gang requirements into tgiann-target groups.
---@param job? string | string[] | table<string, number>
---@param gang? string | string[] | table<string, number>
---@return table<string, number>?
local function buildGroups(job, gang)
    if not job and not gang then return nil end

    local groups = {}

    local function add(src)
        local t = type(src)

        if t == 'string' then
            groups[src] = 0
        elseif t == 'table' then
            if table.type(src) == 'array' then
                for i = 1, #src do groups[src[i]] = 0 end
            else
                for name, grade in pairs(src) do groups[name] = grade end
            end
        end
    end

    add(job)
    add(gang)

    return groups
end

-- Translate qb-target parameters/targetoptions into tgiann-target options.
---@param parameters table { options: table[], distance?: number } | table[]
---@return table
local function convert(parameters)
    local distance = parameters.distance
    local options = parameters.options or parameters

    -- People may pass options as a hashmap (or mixed, even).
    for k, v in pairs(options) do
        if type(k) ~= 'number' then
            table.insert(options, v)
        end
    end

    for id, v in pairs(options) do
        if type(id) ~= 'number' then
            options[id] = nil
            goto continue
        end

        v.onSelect = v.action
        v.distance = v.distance or v.drawDistance or distance
        v.name = v.name or v.label
        v.icon = v.icon or v.targeticon
        v.items = v.item or v.items
        v.groups = buildGroups(v.job, v.gang)

        if v.event and v.type and v.type ~= 'client' then
            if v.type == 'server' then
                v.serverEvent = v.event
            elseif v.type == 'command' then
                v.command = v.event
            end

            v.event = nil
        end

        v.action = nil
        v.type = nil
        v.job = nil
        v.gang = nil
        v.citizenid = nil
        v.item = nil
        v.targeticon = nil
        v.drawDistance = nil
        v.drawColor = nil
        v.successDrawColor = nil
        -- qb-target action callbacks receive the entity (not a data table).
        v.qtarget = true

        ::continue::
    end

    return options
end

exportHandler('AddCircleZone', function(name, center, radius, options, targetoptions)
    return api.addSphereZone({
        name = name,
        coords = center,
        radius = radius,
        debug = options.debugPoly,
        options = convert(targetoptions),
    })
end)

exportHandler('AddBoxZone', function(name, center, length, width, options, targetoptions)
    local z = center.z

    if not options.minZ then options.minZ = -100 end
    if not options.maxZ then options.maxZ = 800 end

    if not options.useZ then
        z = z + math.abs(options.maxZ - options.minZ) / 2
        center = vec3(center.x, center.y, z)
    end

    return api.addBoxZone({
        name = name,
        coords = center,
        size = vec3(width, length,
            (options.useZ or not options.maxZ) and center.z or math.abs(options.maxZ - options.minZ)),
        debug = options.debugPoly,
        rotation = options.heading,
        options = convert(targetoptions),
    })
end)

exportHandler('AddPolyZone', function(name, points, options, targetoptions)
    local newPoints = table.create(#points, 0)
    local thickness = math.abs(options.maxZ - options.minZ)

    for i = 1, #points do
        local point = points[i]
        newPoints[i] = vec3(point.x, point.y, options.maxZ - (thickness / 2))
    end

    return api.addPolyZone({
        name = name,
        points = newPoints,
        thickness = thickness,
        debug = options.debugPoly,
        options = convert(targetoptions),
    })
end)

exportHandler('AddEntityZone', function(_, entity, _, targetoptions)
    local options = convert(targetoptions)

    if NetworkGetEntityIsNetworked(entity) then
        api.addEntity(NetworkGetNetworkIdFromEntity(entity), options)
    else
        api.addLocalEntity(entity, options)
    end
end)

exportHandler('AddComboZone', function()
    lib.print.warn('qb-target compat: AddComboZone is not supported and was ignored.')
end)

exportHandler('RemoveZone', function(id)
    api.removeZone(id, true)
end)

exportHandler('AddTargetEntity', function(entities, parameters)
    if type(entities) ~= 'table' then entities = { entities } end
    local options = convert(parameters)

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            api.addEntity(NetworkGetNetworkIdFromEntity(entity), options)
        else
            api.addLocalEntity(entity, options)
        end
    end
end)

exportHandler('RemoveTargetEntity', function(entities, labels)
    if type(entities) ~= 'table' then entities = { entities } end

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            api.removeEntity(NetworkGetNetworkIdFromEntity(entity), labels)
        else
            api.removeLocalEntity(entity, labels)
        end
    end
end)

exportHandler('AddTargetModel', function(models, parameters)
    api.addModel(models, convert(parameters))
end)

exportHandler('RemoveTargetModel', function(models, labels)
    api.removeModel(models, labels)
end)

exportHandler('AddTargetBone', function(bones, parameters)
    if type(bones) ~= 'table' then bones = { bones } end
    local options = convert(parameters)

    for _, v in pairs(options) do
        v.bones = bones
    end

    api.addGlobalVehicle(options)
end)

exportHandler('RemoveTargetBone', function(_, labels)
    api.removeGlobalVehicle(labels)
end)

exportHandler('AddGlobalPed', function(parameters)
    api.addGlobalPed(convert(parameters))
end)

exportHandler('RemoveGlobalPed', function(labels)
    api.removeGlobalPed(labels)
end)

exportHandler('AddGlobalVehicle', function(parameters)
    api.addGlobalVehicle(convert(parameters))
end)

exportHandler('RemoveGlobalVehicle', function(labels)
    api.removeGlobalVehicle(labels)
end)

exportHandler('AddGlobalObject', function(parameters)
    api.addGlobalObject(convert(parameters))
end)

exportHandler('RemoveGlobalObject', function(labels)
    api.removeGlobalObject(labels)
end)

exportHandler('AddGlobalPlayer', function(parameters)
    api.addGlobalPlayer(convert(parameters))
end)

exportHandler('RemoveGlobalPlayer', function(labels)
    api.removeGlobalPlayer(labels)
end)

-- qb-target type ids: 1 = ped, 2 = vehicle, 3 = object, 4 = player.
exportHandler('RemoveGlobalTypeOptions', function(_type, labels)
    if _type == 1 then
        api.removeGlobalPed(labels)
    elseif _type == 2 then
        api.removeGlobalVehicle(labels)
    elseif _type == 3 then
        api.removeGlobalObject(labels)
    elseif _type == 4 then
        api.removeGlobalPlayer(labels)
    end
end)

exportHandler('AllowTargeting', function(allow)
    api.disableTargeting(not allow)
end)

exportHandler('RaycastCamera', function(flag)
    local hit, entity, coords, normal, material = lib.raycast.fromCamera(flag or 511, 4, 20)
    return coords, entity, hit, normal, material
end)

local spawnedPeds = {}

exportHandler('SpawnPed', function(data)
    if data.model then data = { data } end

    local result = {}

    for i = 1, #data do
        local ped = data[i]
        local model = type(ped.model) == 'number' and ped.model or joaat(ped.model)

        if lib.requestModel(model, 10000) then
            local coords = ped.coords
            local heading = ped.heading or coords.w or 0.0
            local entity = CreatePed(0, model, coords.x, coords.y, coords.z, heading,
                ped.networkPed or false, true)

            if ped.freeze ~= false then FreezeEntityPosition(entity, true) end
            if ped.invincible ~= false then SetEntityInvincible(entity, true) end
            if ped.blockevents ~= false then SetBlockingOfNonTemporaryEvents(entity, true) end
            SetModelAsNoLongerNeeded(model)

            if ped.animDict and ped.anim then
                if lib.requestAnimDict(ped.animDict, 5000) then
                    TaskPlayAnim(entity, ped.animDict, ped.anim, 8.0, 0, -1, ped.flag or 1, 0, false, false, false)
                end
            elseif ped.scenario then
                TaskStartScenarioInPlace(entity, ped.scenario, 0, true)
            end

            if ped.target then
                api.addLocalEntity(entity, convert(ped.target))
            end

            spawnedPeds[#spawnedPeds + 1] = entity
            result[#result + 1] = entity
        end
    end

    return result
end)

exportHandler('RemoveSpawnedPed', function(peds)
    if type(peds) ~= 'table' then peds = { peds } end

    for i = 1, #peds do
        local entity = peds[i]

        if entity and DoesEntityExist(entity) then
            api.removeLocalEntity(entity)
            DeleteEntity(entity)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #spawnedPeds do
        if DoesEntityExist(spawnedPeds[i]) then
            DeleteEntity(spawnedPeds[i])
        end
    end
end)
