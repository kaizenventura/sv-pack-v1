local ESX = exports["es_extended"]:getSharedObject()
local activeZones = {} 
local zoneBlips = {}
local usedPoints = {} 
currentStatus = "outside" 
local trapStartedAt = 0
local trapDuration = (Config.ActiveDuration or 0)
local currentTrapName = "None"

local function formatTrapTime(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format('%02d:%02d', mins, secs)
end

local function buildTrapName()
    if #activeZones == 0 then return "None" end
    local names = ""
    for i, zone in ipairs(activeZones) do
        names = names .. zone.name .. (i < #activeZones and " & " or "")
    end
    return names ~= "" and names or "None"
end

local function getTrapRemainingSeconds()
    if #activeZones == 0 or trapStartedAt <= 0 then return 0 end
    local elapsed = GetGameTimer() - trapStartedAt
    local remaining = math.floor((trapDuration - elapsed) / 1000)
    return math.max(0, remaining)
end

local function getTrapHudText()
    if #activeZones == 0 then return "" end
    local name = currentTrapName ~= "None" and currentTrapName or buildTrapName()
    return name .. " - " .. formatTrapTime(getTrapRemainingSeconds())
end


local function getPlayerActiveTrapData()
    if #activeZones == 0 then
        return false, nil
    end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return false, nil
    end

    local pCoords = GetEntityCoords(ped)
    local closestData = nil

    for _, zone in ipairs(activeZones) do
        local dist = #(pCoords - zone.coords)
        local inside = dist <= (zone.radius or 0.0)

        if inside then
            return true, {
                active = true,
                inside = true,
                name = zone.name,
                distance = dist,
                radius = zone.radius
            }
        end

        if not closestData or dist < closestData.distance then
            closestData = {
                active = true,
                inside = false,
                name = zone.name,
                distance = dist,
                radius = zone.radius
            }
        end
    end

    return false, closestData
end

exports('IsPlayerInsideActiveTrap', function()
    local inside = getPlayerActiveTrapData()
    return inside == true
end)

exports('GetPlayerActiveTrapData', function()
    local inside, data = getPlayerActiveTrapData()
    if data then
        data.inside = inside == true
        data.active = #activeZones > 0
        return data
    end

    return {
        active = false,
        inside = false,
        name = 'None',
        distance = 0.0,
        radius = 0.0
    }
end)

exports('GetTrapStatus', function()
    local remaining = getTrapRemainingSeconds()
    local text = getTrapHudText()
    return {
        active = #activeZones > 0,
        name = currentTrapName,
        seconds = remaining,
        time = formatTrapTime(remaining),
        text = text
    }
end)


RegisterNetEvent('t1software:activate')
AddEventHandler('t1software:activate', function(zones)
    activeZones = zones
    trapStartedAt = GetGameTimer()
    trapDuration = (Config.ActiveDuration or trapDuration or 0)
    currentTrapName = buildTrapName()
    local names = ""

    for i, zone in ipairs(activeZones) do

        names = names .. zone.name .. (i < #activeZones and " & " or "")

        local warningRadius = zone.radius + 50.0 
        local yellowBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, warningRadius)
        SetBlipHighDetail(yellowBlip, true)
        SetBlipColour(yellowBlip, 46) 
        SetBlipAlpha(yellowBlip, 30)

        local redBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipHighDetail(redBlip, true)
        SetBlipColour(redBlip, 1) 
        SetBlipAlpha(redBlip, 128) 
        
        table.insert(zoneBlips, yellowBlip)
        table.insert(zoneBlips, redBlip)
    end

    currentTrapName = names ~= "" and names or currentTrapName

    lib.notify({
        title = 'Traphouse Started:',
        description = names,
        position = 'top',
        icon = 'skull',
        iconColor = '#ff1a1a',
        style = {
            borderRadius = 5,
            backgroundColor = 'rgba(0, 0, 0, 0.8)',
            color = '#f0f0f0'
        }
    })
end)

RegisterNetEvent('t1software:deactivate')
AddEventHandler('t1software:deactivate', function()

    if #activeZones > 0 then
        local names = ""
        for i, zone in ipairs(activeZones) do
            names = names .. zone.name .. (i < #activeZones and " & " or "")
        end

        lib.notify({
            title = 'Traphouse Ended:',
            description = names,
            position = 'top',
            icon = 'check-circle',
            iconColor = '#FFD700',
            style = {
                borderRadius = 5,
                backgroundColor = 'rgba(0, 0, 0, 0.8)',
                color = '#f0f0f0'
            }
        })
    end

    activeZones = {}
    currentStatus = "outside"
    trapStartedAt = 0
    currentTrapName = "None"
    for _, blip in ipairs(zoneBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    zoneBlips = {}
    lib.hideTextUI()
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if #activeZones > 0 then
            local pCoords = GetEntityCoords(PlayerPedId())
            local closestZone = nil
            local minDistance = 999999.0

            for _, zone in ipairs(activeZones) do
                local dist = #(pCoords - zone.coords)
                if dist < minDistance then
                    minDistance = dist
                    closestZone = zone
                end
            end

            if closestZone then
                local warningRadius = closestZone.radius + 50.0

                if minDistance <= closestZone.radius then
                    if currentStatus ~= "inside" then
                        currentStatus = "inside"
                        lib.showTextUI('Trap House Zone: **' .. closestZone.name .. '**', {
                            position = "bottom-center",
                            icon = 'house',
                            iconColor = '#ff1a1a', 
                            style = { borderRadius = 5, backgroundColor = 'rgba(0, 0, 0, 0.8)', color = '#f0f0f0' }
                        })
                    end
                elseif minDistance <= warningRadius then
                    if currentStatus ~= "warning" then
                        currentStatus = "warning"
                        lib.showTextUI('Warning Near Trap House Zone: **' .. closestZone.name .. '**', {
                            position = "bottom-center",
                            icon = 'triangle-exclamation',
                            iconColor = '#FFD700',
                            style = { borderRadius = 5, backgroundColor = 'rgba(0, 0, 0, 0.8)', color = '#f0f0f0' }
                        })
                    end
                else
                    if currentStatus ~= "outside" then
                        currentStatus = "outside"
                        lib.hideTextUI()
                    end
                end
                sleep = 500
            end
        end
        Citizen.Wait(sleep)
    end
end)


-- Disable shooting only while the player is inside the yellow warning zone.
-- Red active traphouse zone remains shootable.
Citizen.CreateThread(function()
    while true do
        local sleep = 750

        if currentStatus == "warning" then
            sleep = 0
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)  -- INPUT_ATTACK
            DisableControlAction(0, 25, true)  -- INPUT_AIM
            DisableControlAction(0, 68, true)  -- INPUT_VEH_ATTACK
            DisableControlAction(0, 69, true)  -- INPUT_VEH_ATTACK
            DisableControlAction(0, 70, true)  -- INPUT_VEH_ATTACK2
            DisableControlAction(0, 91, true)  -- INPUT_VEH_PASSENGER_AIM
            DisableControlAction(0, 92, true)  -- INPUT_VEH_PASSENGER_ATTACK
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
        end

        Citizen.Wait(sleep)
    end
end)

local function teleportLogic(locName)
    local allPoints = Config.TeleportLocations[locName]
    if not allPoints then return end

    if not usedPoints[locName] then usedPoints[locName] = {} end
    local availableIndices = {}
    for i = 1, #allPoints do
        if not usedPoints[locName][i] then table.insert(availableIndices, i) end
    end

    if #availableIndices == 0 then
        usedPoints[locName] = {}
        for i = 1, #allPoints do table.insert(availableIndices, i) end
    end

    local randomIndex = availableIndices[math.random(1, #availableIndices)]
    usedPoints[locName][randomIndex] = true 
    local target = allPoints[randomIndex]

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local entity = (vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped) and vehicle or ped

    DoScreenFadeOut(500)
    
    Wait(500) 

    SetEntityCoords(entity, target.coords.x, target.coords.y, target.coords.z, false, false, false, false)
    SetEntityHeading(entity, target.heading)

    if entity == vehicle then
        RequestCollisionAtCoord(target.coords.x, target.coords.y, target.coords.z)

        local timeout = 0
        while not HasCollisionLoadedAroundEntity(entity) and timeout < 100 do
            Wait(10) 
            timeout = timeout + 1
        end
    end

    Wait(500) 
    DoScreenFadeIn(500)
    
    lib.notify({
        title = 'System',
        description = ('You Teleported!'):format(locName, randomIndex),
        type = 'success'
    })
end

local function genericTeleport(coords, heading)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local entity = (vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped) and vehicle or ped

    DoScreenFadeOut(500)
    Wait(500) 

    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(entity, heading)

    if entity == vehicle then
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        local timeout = 0
        while not HasCollisionLoadedAroundEntity(entity) and timeout < 100 do
            Wait(10) 
            timeout = timeout + 1
        end
    end

    Wait(500) 
    DoScreenFadeIn(500)
end

RegisterCommand('tp', function()
    -- Check if the player is currently inside a Trap House Zone
    if currentStatus == "inside" then
        return lib.notify({
            title = 'System',
            description = 'You cannot teleport while inside a Trap House zone!',
            type = 'error',
            icon = 'ban'
        })
    end

    -- Base options that are always available
    local mainOptions = {
        {
            title = 'City Hall',
            icon = 'building-columns',
            iconColor = '#4db8ff',
            description = 'Government center and legal services',
            onSelect = function()
                genericTeleport(Config.StaticLocations['City Hall'].coords, Config.StaticLocations['City Hall'].heading)
            end
        },
        {
            title = 'Gang Base',
            icon = 'skull',
            iconColor = '#43cf27',
            description = 'Head back to your territory',
            metadata = {
                {label = 'Access', value = 'Authorized Personnel Only'}
            },
            onSelect = function()
                local playerJob = ESX.GetPlayerData().job.name
                local gangData = Config.GangBases[playerJob]

                if gangData then
                    genericTeleport(gangData.coords, gangData.heading)
                else
                    lib.notify({
                        title = 'Access Denied',
                        description = 'No gang affiliated',
                        type = 'error',
                        icon = 'lock'
                    })
                end
            end
        }
    }

    -- Insert Active Traphouse at the top ONLY if it's running
    if #activeZones > 0 then
        local zoneOptions = {}
        for _, zone in ipairs(activeZones) do
            table.insert(zoneOptions, {
                title = zone.name,
                icon = 'location-dot',
                iconColor = '#ff0000', 
                description = 'Instant travel to this active zone',
                onSelect = function()
                    teleportLogic(zone.name)
                end
            })
        end

        lib.registerContext({
            id = 'trap_locations_menu',
            title = 'Select Active Trap',
            menu = 'trap_main_menu', 
            options = zoneOptions
        })

        table.insert(mainOptions, 1, {
            title = 'Active Traphouse',
            icon = 'house',
            iconColor = '#ff0000', 
            description = 'Teleport to available traphouse!',
            menu = 'trap_locations_menu',
            arrow = true
        })
    end

    lib.registerContext({
        id = 'trap_main_menu',
        title = 'Fast Travel Network',
        options = mainOptions
    })

    lib.showContext('trap_main_menu')
end, false)