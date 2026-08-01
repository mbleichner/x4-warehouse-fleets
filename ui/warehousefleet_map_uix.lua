-- Map menu patch for the "Subordinates of warehouse" fleet organization mode.
-- The base game greys out the default behaviour and its parameters for any ship that has a
-- commander, and it doesn't know the custom "warehousefleet" assignment. Both are fixed here
-- through kuertee's UI Extensions callbacks, which run while the map builds the info panel.

local MODULE = "WarehouseFleets Map UIX"
local CALLBACK_ID = "warehousefleets"

local mapMenu = nil
local registered = false

local function debug(message)
    DebugError("[" .. MODULE .. "] " .. tostring(message))
end

-- True only for the ships we want to unlock: default behaviour is WarehouseFleet and the ship is
-- anchored under a station via warehousefleet assignment. Everything else keeps vanilla UI behaviour.
local function isAssignedWarehouseFleetDefault(orderidx, instance)
    if orderidx ~= "default" then
        return false
    end
    if not mapMenu or not instance or not mapMenu.infoTableData or not mapMenu.infoTableData[instance] then
        return false
    end

    local infoTableData = mapMenu.infoTableData[instance]
    if not infoTableData.commander then
        return false
    end

    local defaultorder = infoTableData.defaultorder
    if not defaultorder or defaultorder.orderdef ~= "WarehouseFleet" then
        return false
    end

    local ok, assignment = pcall(GetComponentData, mapMenu.infoSubmenuObject, "assignment")
    return ok and assignment == "warehousefleet"
end

-- Adds "WarehouseFleet" to the "Current Role" dropdown. The base game builds that list from a
-- hardcoded set of assignments, so our assignment would otherwise be displayed as "--".
-- vanilla ref: unpacked - ui/addons/ego_detailmonitor/menu_map.lua:11743-11790.
-- UIX has a callback for exactly this (aegs_map_ship_assignments_insert), but it only fires while
-- the option list is being built for a ship commander - but we need a station.
-- Without it the only way in is to find the already-built dropdown row and append to its options,
-- which is why this is done from the param callback: it's the first hook that fires after the row
-- exists. The flag on the ftable keeps that to one pass, since the callback runs per param row.
local function ensureWarehouseFleetAssignmentOption(ftable)
    if not ftable or type(ftable.rows) ~= "table" or ftable.warehousefleetPatched == true then
        return
    end

    for _, row in ipairs(ftable.rows) do
        if type(row.rowdata) == "table" and row.rowdata[1] == "assignment" then
            local cell = row[5]
            local options = cell and cell.properties and cell.properties.options
            if type(options) ~= "table" then
                ftable.warehousefleetPatched = true
                return
            end

            table.insert(options, {
                id = "warehousefleet",
                text = "WarehouseFleet",
                icon = "",
                displayremoveoption = false,
            })

            ftable.warehousefleetPatched = true
            return
        end
    end
end

-- Called per behaviour parameter row: re-enables editing of the WarehouseFleet settings.
local function changeParamActive(ftable, orderidx, order, paramidx, param, listidx, instance, paramactive)
    if isAssignedWarehouseFleetDefault(orderidx, instance) then
        ensureWarehouseFleetAssignmentOption(ftable)
        if not paramactive then
            return { paramactive = true }
        end
    end

    return nil
end

-- Re-enables the "Add <param>" button of list parameters, so target lists can still be edited.
-- This callback gets no instance argument, so both info panels are checked.
local function changeBehaviourActive(behaviouractive)
    if behaviouractive then
        return nil
    end
    if not mapMenu or not mapMenu.infoTableData then
        return nil
    end

    for _, instance in ipairs({ "left", "right" }) do
        local infoTableData = mapMenu.infoTableData[instance]
        local defaultorder = infoTableData and infoTableData.defaultorder
        if infoTableData and infoTableData.commander and defaultorder and defaultorder.orderdef == "WarehouseFleet" then
            local ok, assignment = pcall(GetComponentData, mapMenu.infoSubmenuObject, "assignment")
            if ok and assignment == "warehousefleet" then
                return { behaviouractive = true }
            end
        end
    end

    return nil
end

local function init()
    if registered then
        return
    end
    if not Helper or type(Helper.getMenu) ~= "function" then
        debug("Helper.getMenu is unavailable; UIX callback not registered.")
        return
    end

    mapMenu = Helper.getMenu("MapMenu")
    if not mapMenu or type(mapMenu.registerCallback) ~= "function" then
        debug("MapMenu/UIX callback API is unavailable; UIX callback not registered.")
        return
    end

    -- Gives the assignment a display name in the ship list / property menus.
    local config = type(mapMenu.uix_getConfig) == "function" and mapMenu.uix_getConfig() or nil
    if config and config.assignments then
        config.assignments["warehousefleet"] = { name = "WarehouseFleet" }
    end

    mapMenu.registerCallback("displayOrderParam_change_paramactive", changeParamActive, CALLBACK_ID)
    mapMenu.registerCallback("displayDefaultBehaviour_change_param_behaviouractive", changeBehaviourActive, CALLBACK_ID)
    registered = true
end

init()

