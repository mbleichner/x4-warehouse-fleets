local MODULE = "WarehouseFleets Map UIX"
local CALLBACK_ID = "warehousefleets"

local mapMenu = nil
local registered = false

local function debug(message)
    DebugError("[" .. MODULE .. "] " .. tostring(message))
end

local function getOrderDefID(order)
    if not order then
        return nil
    end
    if order.orderdefref and order.orderdefref.id then
        return order.orderdefref.id
    end
    return order.orderdef or order.id
end

local function isAssignedWarehouseFleetDefault(orderidx, order, instance)
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

    local defaultOrderID = getOrderDefID(infoTableData.defaultorder) or getOrderDefID(order)
    if defaultOrderID ~= "WarehouseFleet" then
        return false
    end

    local ok, assignment = pcall(GetComponentData, mapMenu.infoSubmenuObject, "assignment")
    return ok and assignment == "warehousefleet"
end

local function changeParamActive(ftable, orderidx, order, paramidx, param, listidx, instance, paramactive)
    if paramactive then
        return nil
    end

    if isAssignedWarehouseFleetDefault(orderidx, order, instance) then
        return { paramactive = true }
    end

    return nil
end

local function changeBehaviourActive(behaviouractive)
    if behaviouractive then
        return nil
    end
    if not mapMenu or not mapMenu.infoTableData then
        return nil
    end

    for _, instance in ipairs({ "left", "right" }) do
        local infoTableData = mapMenu.infoTableData[instance]
        if infoTableData and infoTableData.commander and getOrderDefID(infoTableData.defaultorder) == "WarehouseFleet" then
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

    mapMenu.registerCallback("displayOrderParam_change_paramactive", changeParamActive, CALLBACK_ID)
    mapMenu.registerCallback("displayDefaultBehaviour_change_param_behaviouractive", changeBehaviourActive, CALLBACK_ID)
    registered = true
end

if type(Register_OnLoad_Init) == "function" then
    Register_OnLoad_Init(init, "extensions.warehousefleets.ui.warehousefleet_map_uix")
end

init()

