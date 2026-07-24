local ESX = exports["es_extended"]:getSharedObject()

local turfCooldowns = {}


local function addLeaderboardTurfwarWin(jobName, jobLabel)
    if not jobName or jobName == '' or jobName == 'unemployed' then return end

    local leaderboardResource = Config.LeaderboardResource or 'T1-leaderboards'
    if GetResourceState(leaderboardResource) == 'started' then
        local ok = pcall(function()
            exports[leaderboardResource]:AddTurfwarWin(jobName, jobLabel)
        end)
        if ok then return end
    end

    -- Fallback bridge if you renamed the resource and use the event instead.
    TriggerEvent('t1_leaderboard:addTurfwarWin', jobName, jobLabel)
end


RegisterServerEvent('t1software:startTurf')
AddEventHandler('t1software:startTurf', function(turfIndex)
    local src = source
    local currentTime = os.time()
    local turf = Config.Turfs[turfIndex]

    -- Cooldown logic: War duration + the Cooldown buffer
    local totalWait = (Config.WarDuration + Config.CooldownTime) * 60
    
    if turfCooldowns[turfIndex] and (currentTime - turfCooldowns[turfIndex] < totalWait) then
        local rem = math.ceil((totalWait - (currentTime - turfCooldowns[turfIndex])) / 60)
        
        lib.notify(src, {
            title = 'Turfwar Error!',
            description = 'This zone is on cooldown. Wait ' .. rem .. ' more minutes.',
            type = 'error',
            position = 'top',
            icon = 'clock',
            style = { borderRadius = 5, backgroundColor = 'rgba(0, 0, 0, 0.6)', color = '#f0f0f0' }
        })
        return
    end

    -- Item requirement removed: anyone can start the turfwar after the skill check/cooldown.
    turfCooldowns[turfIndex] = currentTime
    
    -- We trigger the client sync using Config.WarDuration specifically
    TriggerClientEvent('t1software:syncZone', -1, turfIndex, true, Config.WarDuration * 60)
end)

RegisterServerEvent('t1software:claimRewards')
AddEventHandler('t1software:claimRewards', function(turfIndex)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
    if not xPlayer then return end

    local jobName = xPlayer.job.name
    local jobLabel = xPlayer.job.label -- Gets the name of the job (e.g., "Ballas", "Police")
    local turf = Config.Turfs[turfIndex]

    -- 1. Give the rewards to the player
    for _, data in ipairs(Config.RewardItems) do
        exports.ox_inventory:AddItem(src, data.item, data.count)
    end

    -- 2. Add +1 Turfwar Win to the leaderboard for the winning job.
    addLeaderboardTurfwarWin(jobName, jobLabel)

    -- 3. Broadcast to EVERYONE (-1)
    TriggerClientEvent('ox_lib:notify', -1, {
        title = 'TURF WAR OVER',
        description = string.format('%s wins the Turfwar at %s!', jobLabel, turf.name),
        type = 'inform',
        position = 'top',
        duration = 20000, -- 20 seconds
        icon = 'trophy',
        style = { 
            borderRadius = 5, 
            backgroundColor = 'rgba(0, 0, 0, 0.6)', -- Gold-ish background
            color = 'white' 
        }
    })

    -- 4. Sync the zone to turn it off for everyone
    TriggerClientEvent('t1software:syncZone', -1, turfIndex, false)
end)