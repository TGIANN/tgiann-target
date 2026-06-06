---@meta

---@class TargetOption
---@field label string
---@field name? string
---@field icon? string
---@field iconColor? string
---@field distance? number
---@field groups? string | string[] | table<string, number>
---@field items? string | string[] | table<string, number>
---@field anyItem? boolean
---@field canInteract? fun(entity?: number, distance: number, coords: vector3, name?: string, bone?: number): boolean?
---@field onSelect? fun(data: self | number)
---@field export? string
---@field event? string
---@field serverEvent? string
---@field command? string
---@field openMenu? string
---@field menuName? string
---@field resource? string
---@field [string] any

---@class TargetEntity : TargetOption
---@field bones? string | string[]
---@field offset? vector3
---@field offsetAbsolute? vector3
---@field offsetSize? number

---@class TargetSphereZone
---@field coords vector3
---@field radius? number
---@field debug? boolean
---@field drawSprite? boolean
---@field options TargetOption[]

---@class TargetBoxZone
---@field coords vector3
---@field size? vector3
---@field rotation? number
---@field debug? boolean
---@field drawSprite? boolean
---@field options TargetOption[]

---@class TargetPolyZone
---@field points vector3[]
---@field thickness? number
---@field debug? boolean
---@field drawSprite? boolean
---@field options TargetOption[]

---@param data TargetSphereZone
---@return number
local function addSphereZone(data) end

---@param data TargetBoxZone
---@return number
local function addBoxZone(data) end

---@param data TargetPolyZone
---@return number
local function addPolyZone(data) end

---@param zone number | string
---@param suppressWarning? boolean
local function removeZone(zone, suppressWarning) end

---@param options TargetEntity | TargetEntity[]
local function addGlobalPed(options) end

---@param options TargetEntity | TargetEntity[]
local function addGlobalVehicle(options) end

---@param options TargetEntity | TargetEntity[]
local function addGlobalObject(options) end

---@param options TargetEntity | TargetEntity[]
local function addGlobalPlayer(options) end

---@param options string | string[]
local function removeGlobalPed(options) end

---@param options string | string[]
local function removeGlobalVehicle(options) end

---@param options string | string[]
local function removeGlobalObject(options) end

---@param options string | string[]
local function removeGlobalPlayer(options) end

---@param options TargetOption | TargetOption[]
local function addGlobalOption(options) end

---@param options string | string[]
local function removeGlobalOption(options) end

---@param models (number | string) | (number | string)[]
---@param options TargetEntity | TargetEntity[]
local function addModel(models, options) end

---@param models (number | string) | (number | string)[]
---@param options? string | string[]
local function removeModel(models, options) end

---@param netIds number | number[]
---@param options TargetEntity | TargetEntity[]
local function addEntity(netIds, options) end

---@param netIds number | number[]
---@param options? string | string[]
local function removeEntity(netIds, options) end

---@param entityIds number | number[]
---@param options TargetEntity | TargetEntity[]
local function addLocalEntity(entityIds, options) end

---@param entityIds number | number[]
---@param options? string | string[]
local function removeLocalEntity(entityIds, options) end

---@param state boolean
local function disableTargeting(state) end

---@class target
exports["tgiann-target"] = {
    addSphereZone = addSphereZone,
    addBoxZone = addBoxZone,
    addPolyZone = addPolyZone,
    removeZone = removeZone,
    addGlobalPed = addGlobalPed,
    addGlobalVehicle = addGlobalVehicle,
    addGlobalObject = addGlobalObject,
    addGlobalPlayer = addGlobalPlayer,
    removeGlobalPed = removeGlobalPed,
    removeGlobalVehicle = removeGlobalVehicle,
    removeGlobalObject = removeGlobalObject,
    removeGlobalPlayer = removeGlobalPlayer,
    addGlobalOption = addGlobalOption,
    removeGlobalOption = removeGlobalOption,
    addModel = addModel,
    removeModel = removeModel,
    addEntity = addEntity,
    removeEntity = removeEntity,
    addLocalEntity = addLocalEntity,
    removeLocalEntity = removeLocalEntity,
    disableTargeting = disableTargeting
}
