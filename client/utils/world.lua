-- World/geometry helpers: streamed texture, model dimensions, option anchors and the
-- in-game ambient marker sprite.
local config = require 'client.config'

local world = {}

local GetEntityCoords = GetEntityCoords
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetModelDimensions = GetModelDimensions
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin

function world.getTexture()
    return lib.requestStreamedTextureDict('shared'), 'emptydot_32'
end

-- Cache model dimensions; GetModelDimensions is otherwise called every frame.
local modelDimsCache = {}

function world.getModelDims(model)
    local dims = modelDimsCache[model]

    if not dims then
        local min, max = GetModelDimensions(model)
        dims = { min, max }
        modelDimsCache[model] = dims
    end

    return dims[1], dims[2]
end

-- Resolve the world position an option should be drawn at (bone > offset > centre).
---@param option TargetOption
---@param entity number
---@param entityModel? number | false
---@return vector3
function world.getOptionAnchor(option, entity, entityModel)
    local bone = entityModel and option.bones or nil

    if bone then
        local _type = type(bone)

        if _type == 'string' then
            local boneId = GetEntityBoneIndexByName(entity, bone)
            if boneId ~= -1 then return GetEntityBonePosition_2(entity, boneId) end
        elseif _type == 'table' then
            -- Centre (average) of the option's valid bones; stays fixed and sits in
            -- the middle of the bone group (e.g. between door & seat).
            local sum = vec3(0, 0, 0)
            local count = 0

            for j = 1, #bone do
                local boneId = GetEntityBoneIndexByName(entity, bone[j])

                if boneId ~= -1 then
                    sum = sum + GetEntityBonePosition_2(entity, boneId)
                    count += 1
                end
            end

            if count > 0 then return sum / count end
        end
    end

    local offset = entityModel and option.offset or nil

    if offset then
        if not option.absoluteOffset then
            local min, max = world.getModelDims(entityModel)
            offset = (max - min) * offset + min
        end

        return GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    end

    -- No bone/offset: the entity's geometric centre (model bounding box) so the marker
    -- sits on the body/middle instead of at the feet/origin.
    if entityModel then
        local min, max = world.getModelDims(entityModel)
        local center = (min + max) / 2
        return GetOffsetFromEntityInWorldCoords(entity, center.x, center.y, center.z)
    end

    return GetEntityCoords(entity)
end

-- In-game ambient marker (original tgiann-target sprite system: SetDrawOrigin + DrawSprite).
local spriteWidth = config.ringSize
local spriteHeight = spriteWidth * GetAspectRatio(false)
local spriteDict, spriteTexture

SetTimeout(1000, function()
    spriteDict, spriteTexture = world.getTexture()
end)

---@param coords vector3
function world.drawMarker(coords)
    if not spriteDict then return end

    SetDrawOrigin(coords.x, coords.y, coords.z)
    DrawSprite(spriteDict, spriteTexture, 0, 0, spriteWidth, spriteHeight, 0, 155, 155, 155, 180)
    ClearDrawOrigin()
end

return world
