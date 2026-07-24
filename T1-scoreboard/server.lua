local ESX = exports['es_extended']:getSharedObject()
local announcements = {}
local nextId = 1
local hasOxMysql = GetResourceState('oxmysql') == 'started'
local jsonFile = 'announcements.json'

local function saveAnnouncementsFile()
    if hasOxMysql then return end
    SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode({
        nextId = nextId,
        announcements = announcements
    }, { indent = true }), -1)
end

local function loadAnnouncementsFile()
    local raw = LoadResourceFile(GetCurrentResourceName(), jsonFile)
    if not raw or raw == '' then return end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return end

    announcements = type(data.announcements) == 'table' and data.announcements or {}
    nextId = tonumber(data.nextId) or 1

    for _, ann in ipairs(announcements) do
        ann.id = tonumber(ann.id) or nextId
        ann.title = tostring(ann.title or '')
        ann.message = tostring(ann.message or '')
        ann.image = tostring(ann.image or '')
        if ann.id >= nextId then nextId = ann.id + 1 end
    end
end

local function tableExists()
    if not hasOxMysql then return end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS tmc_scoreboard_announcements (
            id INT NOT NULL AUTO_INCREMENT,
            title VARCHAR(120) NOT NULL,
            message TEXT NOT NULL,
            image TEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (id)
        )
    ]])
end

local function loadAnnouncements()
    if hasOxMysql then
        tableExists()
        local rows = MySQL.query.await('SELECT id, title, message, image FROM tmc_scoreboard_announcements ORDER BY id DESC') or {}
        announcements = rows
        nextId = 1
        for _, row in ipairs(rows) do
            if row.id >= nextId then nextId = row.id + 1 end
        end
    else
        loadAnnouncementsFile()
    end
end

CreateThread(function()
    Wait(1000)
    loadAnnouncements()
end)

local function isAdmin(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
    return Config.AdminGroups[group] == true
end

local function getServerTime()
    return os.date('%I:%M %p')
end

local function getCurrencyAmount(src, xPlayer, currency)
    if not currency or not currency.name then return 0 end

    if currency.type == 'account' and xPlayer and xPlayer.getAccount then
        local account = xPlayer.getAccount(currency.name)
        return tonumber(account and account.money) or 0
    end

    if GetResourceState('ox_inventory') == 'started' then
        local count = exports.ox_inventory:Search(src, 'count', currency.name)
        if type(count) == 'number' then return count end
    end

    if xPlayer and xPlayer.getInventoryItem then
        local item = xPlayer.getInventoryItem(currency.name)
        return tonumber(item and item.count) or 0
    end

    return 0
end

local function getPlayerCurrencies(src, xPlayer)
    local list = {}
    for _, currency in ipairs(Config.Currencies or {}) do
        list[#list + 1] = {
            key = currency.key or currency.name,
            label = currency.label or currency.name,
            name = currency.name,
            icon = currency.icon or ('nui://ox_inventory/web/images/' .. tostring(currency.name) .. '.png'),
            amount = getCurrencyAmount(src, xPlayer, currency)
        }
    end
    return list
end

local function getPlayersData()
    local players = {}
    local jobs = {}
    for _, src in ipairs(GetPlayers()) do
        local id = tonumber(src)
        local xPlayer = ESX.GetPlayerFromId(id)
        local name = GetPlayerName(id) or ('ID ' .. src)
        local jobName, jobLabel = 'unemployed', 'Unemployed'
        local group = 'user'

        if xPlayer then
            group = xPlayer.getGroup and xPlayer.getGroup() or 'user'
            if xPlayer.job then
                jobName = xPlayer.job.name or 'unemployed'
                jobLabel = xPlayer.job.label or Config.JobLabels[jobName] or jobName
            end
        end

        jobs[jobName] = jobs[jobName] or { name = jobName, label = jobLabel, count = 0 }
        jobs[jobName].count = jobs[jobName].count + 1

        local data = {
            id = id,
            name = name,
            job = jobLabel,
            group = group,
            ping = GetPlayerPing(id)
        }

        players[#players + 1] = data

    end

    local jobList = {}
    for _, job in pairs(jobs) do jobList[#jobList + 1] = job end
    table.sort(players, function(a, b) return a.id < b.id end)
    table.sort(jobList, function(a, b) return a.label < b.label end)

    return players, jobList
end

RegisterNetEvent('tmc-scoreboard:requestData', function()
    local src = source
    local players, jobs = getPlayersData()
    local xPlayer = ESX.GetPlayerFromId(src)
    TriggerClientEvent('tmc-scoreboard:openData', src, {
        playerCount = #players,
        playerId = src,
        players = players,
        jobs = jobs,
        currencies = getPlayerCurrencies(src, xPlayer),
        announcements = announcements
    })
end)

RegisterNetEvent('tmc-scoreboard:requestAdminMenu', function()
    local src = source
    if not isAdmin(src) then
        TriggerClientEvent('tmc-scoreboard:notify', src, 'You do not have permission.', 'error')
        return
    end
    TriggerClientEvent('tmc-scoreboard:adminMenu', src, announcements)
end)

RegisterNetEvent('tmc-scoreboard:addAnnouncement', function(title, message, image)
    local src = source
    if not isAdmin(src) then return end
    title = tostring(title or ''):sub(1, 120)
    message = tostring(message or '')
    image = tostring(image or '')
    if title == '' or message == '' then return end

    if hasOxMysql then
        local id = MySQL.insert.await('INSERT INTO tmc_scoreboard_announcements (title, message, image) VALUES (?, ?, ?)', { title, message, image })
        table.insert(announcements, 1, { id = id, title = title, message = message, image = image })
    else
        table.insert(announcements, 1, { id = nextId, title = title, message = message, image = image })
        nextId = nextId + 1
        saveAnnouncementsFile()
    end
    TriggerClientEvent('tmc-scoreboard:refreshAnnouncements', -1, announcements)
    TriggerClientEvent('tmc-scoreboard:notify', src, 'Announcement added.', 'success')
end)

RegisterNetEvent('tmc-scoreboard:editAnnouncement', function(id, title, message, image)
    local src = source
    if not isAdmin(src) then return end
    id = tonumber(id)
    title = tostring(title or ''):sub(1, 120)
    message = tostring(message or '')
    image = tostring(image or '')
    if not id or title == '' or message == '' then return end

    for _, ann in ipairs(announcements) do
        if tonumber(ann.id) == id then
            ann.title = title
            ann.message = message
            ann.image = image
            break
        end
    end

    if hasOxMysql then
        MySQL.update.await('UPDATE tmc_scoreboard_announcements SET title = ?, message = ?, image = ? WHERE id = ?', { title, message, image, id })
    else
        saveAnnouncementsFile()
    end
    TriggerClientEvent('tmc-scoreboard:refreshAnnouncements', -1, announcements)
    TriggerClientEvent('tmc-scoreboard:notify', src, 'Announcement updated.', 'success')
end)

RegisterNetEvent('tmc-scoreboard:removeAnnouncement', function(id)
    local src = source
    if not isAdmin(src) then return end
    id = tonumber(id)
    if not id then return end

    for i = #announcements, 1, -1 do
        if tonumber(announcements[i].id) == id then table.remove(announcements, i) end
    end

    if hasOxMysql then
        MySQL.update.await('DELETE FROM tmc_scoreboard_announcements WHERE id = ?', { id })
    else
        saveAnnouncementsFile()
    end
    TriggerClientEvent('tmc-scoreboard:refreshAnnouncements', -1, announcements)
    TriggerClientEvent('tmc-scoreboard:notify', src, 'Announcement removed.', 'success')
end)
