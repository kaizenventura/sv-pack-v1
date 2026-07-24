local ESX = exports['es_extended']:getSharedObject()

local isDead = false
local menuOpen = false
local selectedIndex = 1
local timerDone = false
local playerJob = 'unemployed'
local availableLocations = {}

local function GetRespawnTimer()
    local defaultTimer = tonumber(Config.RespawnTimer) or 30
    local bridge = Config.TraphouseBridge or {}

    if not bridge.enabled then
        return defaultTimer
    end

    local resourceName = bridge.resource or 'T1-traphouse-v1'

    if GetResourceState(resourceName) ~= 'started' then
        return defaultTimer
    end

    local ok, result = pcall(function()
        return exports[resourceName]:IsPlayerInsideActiveTrap()
    end)

    if ok and result == true then
        return tonumber(bridge.respawnTimer) or 5
    end

    return defaultTimer
end

local function CloneLocation(loc)
    if not loc then return nil end

    return {
        label = loc.label,
        description = loc.description,
        image = loc.image,
        coords = loc.coords
    }
end

local function RefreshPlayerJob()
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.job and playerData.job.name then
        playerJob = playerData.job.name
    else
        playerJob = 'unemployed'
    end
end

local function BuildAvailableLocations()
    RefreshPlayerJob()

    local list = {}
    local base = Config.GangBaseLocations and Config.GangBaseLocations[playerJob]

    if playerJob ~= 'unemployed' and base and base.coords then
        list[#list + 1] = CloneLocation(base)
    end

    for _, loc in ipairs(Config.Locations or {}) do
        list[#list + 1] = CloneLocation(loc)
    end

    availableLocations = list

    if selectedIndex > #availableLocations then
        selectedIndex = 1
    end

    return availableLocations
end

CreateThread(function()
    while not ESX.IsPlayerLoaded() do
        Wait(250)
    end

    RefreshPlayerJob()
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    if xPlayer and xPlayer.job and xPlayer.job.name then
        playerJob = xPlayer.job.name
    else
        RefreshPlayerJob()
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    playerJob = (job and job.name) or 'unemployed'

    if isDead then
        BuildAvailableLocations()
        if menuOpen then
            SendNUIMessage({
                action = 'setData',
                show = true,
                locations = availableLocations,
                selected = selectedIndex,
                timer = GetRespawnTimer(),
                resetTimer = false
            })
        end
    end
end)

local function SendTextUI(show)
    SendNUIMessage({
        action = show and 'showTextUI' or 'hideTextUI',
        key = Config.OpenKey or 'G',
        text = 'view full death screen'
    })
end


RegisterNetEvent('t1_respawn:notify', function(data)
    if exports.ox_lib then
        exports.ox_lib:notify({
            title = data.title or 'Respawn',
            description = data.description or '',
            type = data.type or 'inform'
        })
    else
        ESX.ShowNotification(data.description or data.title or 'Respawn')
    end
end)

local function SendMenuData(show, resetTimer)
    BuildAvailableLocations()

    SendNUIMessage({
        action = 'setData',
        show = show,
        locations = availableLocations,
        selected = selectedIndex,
        timer = GetRespawnTimer(),
        resetTimer = resetTimer == true
    })
end

local function StartRespawnTimerHidden()
    -- Start timer agad kahit hindi pa open ang full death menu.
    SendMenuData(false, true)
end

local function OpenRespawnMenu(resetTimer)
    if not isDead then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendTextUI(false)
    SendMenuData(true, resetTimer)
end

local function CloseRespawnMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })

    if isDead then
        SendTextUI(true)
    else
        SendTextUI(false)
    end
end

function HandleRespawn(coords)
    local ped = PlayerPedId()

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local x, y, z = coords.x, coords.y, coords.z
    local heading = coords.heading or coords.w or 0.0

    NetworkResurrectLocalPlayer(x, y, z, heading, true, false)

    ped = PlayerPedId()

    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false, true)
    SetEntityHeading(ped, heading)

    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedTasksImmediately(ped)

    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')

    if exports.ox_lib then
        exports.ox_lib:hideTextUI()
    end

    isDead = false
    timerDone = false
    SendTextUI(false)
    SendNUIMessage({ action = 'resetAll' })

    Wait(1000)
    DoScreenFadeIn(500)
end

local function DoRespawn()
    if not isDead or not timerDone then return end

    BuildAvailableLocations()

    local loc = availableLocations[selectedIndex]
    if not loc or not loc.coords then return end

    ESX.TriggerServerCallback('t1_respawn:payAndClearInventory', function(success)
        if not success then return end

        CloseRespawnMenu()
        HandleRespawn(loc.coords)
    end)
end

RegisterNetEvent('esx:onPlayerDeath', function()
    isDead = true
    timerDone = false
    selectedIndex = 1
    BuildAvailableLocations()
    SendTextUI(false)
    SendNUIMessage({ action = 'resetAll' })

    StartRespawnTimerHidden()

    if not Config.DisableAutoOpen then
        SendTextUI(true)
        Wait(Config.MenuOpenDelay or 5000)
        if isDead and not menuOpen then
            OpenRespawnMenu(false)
        end
    else
        SendTextUI(true)
    end
end)

AddEventHandler('playerSpawned', function()
    if not isDead then return end
    isDead = false
    timerDone = false
    CloseRespawnMenu()
    SendTextUI(false)
    SendNUIMessage({ action = 'resetAll' })
end)

RegisterCommand('respawnmenu', function()
    if not isDead then return end
    if menuOpen then
        CloseRespawnMenu()
    else
        OpenRespawnMenu(false)
    end
end, false)

RegisterKeyMapping('respawnmenu', 'Open / minimize respawn menu', 'keyboard', Config.OpenKey)

RegisterNUICallback('selectLocation', function(data, cb)
    local index = tonumber(data.index)
    BuildAvailableLocations()

    if index and availableLocations[index] then
        selectedIndex = index
        SendNUIMessage({ action = 'selected', selected = selectedIndex })
    end

    cb('ok')
end)

RegisterNUICallback('timerDone', function(_, cb)
    timerDone = true
    cb('ok')
end)

RegisterNUICallback('respawn', function(_, cb)
    DoRespawn()
    cb('ok')
end)

RegisterNUICallback('minimize', function(_, cb)
    CloseRespawnMenu()
    cb('ok')
end)

-- Recap system disabled for now.
RegisterNUICallback('recap', function(_, cb)
    cb('ok')
end)

RegisterNUICallback('stuck', function(_, cb)
    if isDead then
        local ped = PlayerPedId()
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)
        SetPedToRagdoll(ped, 700, 700, 0, false, false, false)
        -- No OpenRespawnMenu() here para hindi mag-reset ang timer.
    end
    cb('ok')
end)

RegisterNetEvent('t1_respawn:forceRevive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    HandleRespawn({x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped)})
end)
