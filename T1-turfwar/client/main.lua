local ESX = exports["es_extended"]:getSharedObject()

local isInsideMarker = false

local enteredActiveTurf = {}
local leaveCountdown = {}
local leaveWarningOpen = false
local leaveDeathHandled = {}
local lastLeaveNotifySecond = {}

local function stopLeaveCountdown(turfIndex)
    leaveCountdown[turfIndex] = nil
    lastLeaveNotifySecond[turfIndex] = nil
    if leaveWarningOpen then
        lib.hideTextUI()
        leaveWarningOpen = false
    end
end

local function notifyLeaveCountdown(seconds)
    lib.notify({
        title = 'Leaving Turfwar',
        description = ('Go back inside the redzone in %s seconds or you will die.'):format(seconds),
        type = 'error',
        position = 'bottom-right',
        duration = 1000,
        icon = 'skull',
        iconColor = '#ff1a1a',
        style = { borderRadius = 5, backgroundColor = 'rgba(0, 0, 0, 0.75)', color = '#f0f0f0' }
    })
end

local function killPlayerForLeavingZone()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) and not IsEntityDead(ped) then
        SetEntityHealth(ped, 0)
    end
end


Citizen.CreateThread(function()
    for i, turf in ipairs(Config.Turfs) do
        local blip = AddBlipForCoord(turf.coords)
        SetBlipSprite(blip, 84)
        SetBlipColour(blip, 1)  
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Turf: " .. turf.name)
        EndTextCommandSetBlipName(blip)
    end
end)

local activeUI = nil 

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local currentUI = nil 

        for i, turf in ipairs(Config.Turfs) do
            local dist = #(playerCoords - turf.coords)
            local displayRadius = turf.radius or 250.0 

            if turf.isActive then
                local timeLeft = math.max(0, math.floor((turf.endTime - GetGameTimer()) / 1000))
                
                if timeLeft > 0 then
                    if dist < displayRadius then
                        sleep = 0
                        -- REMOVED timeLeft from the ID so the UI doesn't refresh/flicker
                        currentUI = 'timer_' .. i 
                        
                        local minutes = math.floor(timeLeft / 60)
                        local seconds = timeLeft % 60
                        
                        -- We update the text, but since currentUI matches activeUI, 
                        -- ox_lib handles the text swap smoothly without re-animating.
                        lib.showTextUI(string.format('Turfwar: %s %02d:%02d', turf.name, minutes, seconds), {
                            position = "bottom-center",
                            icon = 'skull',
                            iconColor = '#ff1a1a',
                            style = { backgroundColor = 'rgba(0, 0, 0, 0.6)', color = '#f0f0f0' }
                        })
                        activeUI = currentUI
                    end
                else
                    -- Logic for when timer hits 0
                    if dist < 20.0 then
                        sleep = 0
                        DrawMarker(2, turf.coords.x, turf.coords.y, turf.coords.z + 1.0, 0, 0, 0, 0, 180.0, 0, 0.6, 0.6, 0.6, 0, 255, 0, 200, true, true, 2, nil, nil, false)
                        
                        if dist < 1.5 then
                            currentUI = 'claim_' .. i 
                            if activeUI ~= currentUI then
                                lib.showTextUI('[E] - Claim Rewards', {
                                    position = "bottom-center",
                                    icon = 'hand-holding-dollar',
                                    style = { backgroundColor = 'rgba(0, 0, 0, 0.6)', color = 'white' }
                                })
                                activeUI = currentUI
                            end

                            if IsControlJustReleased(0, 38) then
                                -- FIXED: Changed event name to match your server script (t1software)
                                TriggerServerEvent('t1software:claimRewards', i)
                            end
                        else
                            currentUI = 'ready_' .. i
                            if activeUI ~= currentUI then
                                lib.showTextUI("Turfwar: Ready to Claim", {
                                    position = "bottom-center",
                                    icon = 'check',
                                    iconColor = '#00ff00',
                                    style = { backgroundColor = 'rgba(0, 0, 0, 0.6)', color = '#f0f0f0' }
                                })
                                activeUI = currentUI
                            end
                        end
                    end
                end

            elseif dist < 20.0 then
                sleep = 0
                DrawMarker(2, turf.coords.x, turf.coords.y, turf.coords.z + 1.0, 0, 0, 0, 0, 180.0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 150, true, true, 2, nil, nil, false)
                
                if dist < 1.5 then
                    currentUI = 'lockpick_' .. i
                    if activeUI ~= currentUI then
                        lib.showTextUI('[E] - Start Turfwar', {
                            position = "bottom-center",
                            icon = 'lock',
                            style = { backgroundColor = 'rgba(0, 0, 0, 0.6)', color = 'white' }
                        })
                        activeUI = currentUI
                    end

                    if IsControlJustReleased(0, 38) then
                        local success = lib.skillCheck({'easy', 'medium'}, {'w', 'a', 's', 'd'})
                        if success then
                            TriggerServerEvent('t1software:startTurf', i)
                        end
                    end
                end
            end
        end

        -- Hide UI if we move away from all points
        if not currentUI and activeUI and not leaveWarningOpen then
            lib.hideTextUI()
            activeUI = nil
        end
        
        Citizen.Wait(sleep)
    end
end)


Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local activeTurfFound = false

        for i, turf in ipairs(Config.Turfs) do
            if turf.isActive then
                activeTurfFound = true
                local radius = turf.radius or 250.0
                local dist = #(playerCoords - turf.coords)
                local inside = dist <= radius

                if inside then
                    enteredActiveTurf[i] = true
                    leaveDeathHandled[i] = nil

                    if leaveCountdown[i] then
                        stopLeaveCountdown(i)
                        lib.notify({
                            title = 'Turfwar',
                            description = 'You came back inside the redzone. Countdown cancelled.',
                            type = 'success',
                            position = 'bottom-right',
                            duration = 2500,
                            icon = 'shield',
                            style = { borderRadius = 5, backgroundColor = 'rgba(0, 0, 0, 0.6)', color = '#f0f0f0' }
                        })
                    end
                elseif IsEntityDead(playerPed) then
                    -- If player is already dead, stop the timer so it will not keep repeating while dead/respawning.
                    stopLeaveCountdown(i)
                elseif enteredActiveTurf[i] and not leaveDeathHandled[i] then
                    sleep = 0

                    if not leaveCountdown[i] then
                        leaveCountdown[i] = GetGameTimer() + ((Config.LeaveZoneDeathTimer or 10) * 1000)
                    end

                    local seconds = math.ceil((leaveCountdown[i] - GetGameTimer()) / 1000)

                    if seconds <= 0 then
                        stopLeaveCountdown(i)
                        leaveDeathHandled[i] = true
                        enteredActiveTurf[i] = nil
                        killPlayerForLeavingZone()
                    else
                        if lastLeaveNotifySecond[i] ~= seconds then
                            lastLeaveNotifySecond[i] = seconds
                            notifyLeaveCountdown(seconds)
                        end
                    end
                end
            else
                enteredActiveTurf[i] = nil
                leaveDeathHandled[i] = nil
                stopLeaveCountdown(i)
            end
        end

        if not activeTurfFound then
            enteredActiveTurf = {}
            leaveCountdown = {}
            leaveDeathHandled = {}
            lastLeaveNotifySecond = {}
            if leaveWarningOpen then
                lib.hideTextUI()
                leaveWarningOpen = false
            end
        end

        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent('t1software:syncZone')
AddEventHandler('t1software:syncZone', function(turfIndex, status, duration)
    local turf = Config.Turfs[turfIndex]
    turf.isActive = status
    
    if status then
        -- duration is now coming from Config.WarDuration (sent by server)
        turf.endTime = GetGameTimer() + (duration * 1000)
        turf.radiusBlip = AddBlipForRadius(turf.coords, turf.radius)
        SetBlipColour(turf.radiusBlip, 1)
        SetBlipAlpha(turf.radiusBlip, 128)

        lib.notify({
            title = 'Turfwar Started:',
            description = turf.name,
            position = 'top',
            icon = 'skull',
            iconColor = '#ff1a1a',
            style = { borderRadius = 5, backgroundColor = 'rgba(0, 0, 0, 0.6)', color = '#f0f0f0' }
        })
    else
        if turf.radiusBlip then RemoveBlip(turf.radiusBlip) turf.radiusBlip = nil end
        turf.isActive = false
        if lib.isTextUIOpen() then lib.hideTextUI() end
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        for _, turf in ipairs(Config.Turfs) do
            if turf.isActive then
                sleep = 0

                DrawMarker(28, turf.coords.x, turf.coords.y, turf.coords.z, 0, 0, 0, 0, 0, 0, turf.radius or 250.0, turf.radius or 250.0, turf.radius or 250.0, 255, 0, 0, 60, false, false, 2, nil, nil, false)
            end
        end
        Citizen.Wait(sleep)
    end
end)