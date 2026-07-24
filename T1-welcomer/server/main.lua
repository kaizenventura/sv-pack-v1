local ESX = nil

local function getESX()
    if ESX then return ESX end

    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok and obj then
        ESX = obj
    end

    return ESX
end

local function normalizeDiscord(discord)
    if not discord then return nil end
    discord = tostring(discord):gsub('%s+', '')
    discord = discord:gsub('discord:', '')
    if discord == '' then return nil end
    return 'discord:' .. discord
end

local function getDiscordIdentifier(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'discord:' then
            return identifier
        end
    end
    return nil
end

local function isAdmin(src)
    if src == 0 then return true end

    -- ESX /setgroup support. Any group listed in Config.AdminGroups can use /adminwc.
    local esx = getESX()
    if esx then
        local xPlayer = esx.GetPlayerFromId(src)
        if xPlayer then
            local group = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group
            if group and Config.AdminGroups and Config.AdminGroups[group] then
                return true
            end
        end
    end

    -- ACE fallback, optional.
    if Config.AdminAce and Config.AdminAce ~= '' and IsPlayerAceAllowed(src, Config.AdminAce) then
        return true
    end

    return false
end

local function notify(src, msg, msgType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'TMC Welcomer',
        description = msg,
        type = msgType or 'inform'
    })
end

local function getAccessByDiscord(discord)
    return MySQL.single.await('SELECT * FROM tmc_welcomer_access WHERE discord = ?', { discord })
end

local function showWelcome(target, playerName, data)
    if not data then return end

    TriggerClientEvent('welcomer:client:show', target, {
        name = data.name or playerName,
        badge = data.badge or '',
        image = data.image or '',
        sound = data.sound or '',
        duration = Config.DisplayTime
    })
end

lib.callback.register('welcomer:server:isAdmin', function(source)
    return isAdmin(source)
end)

lib.callback.register('welcomer:server:hasAccess', function(source)
    local discord = getDiscordIdentifier(source)
    if not discord then return false, nil end

    local data = getAccessByDiscord(discord)
    if not data then return false, nil end

    return true, data
end)

lib.callback.register('welcomer:server:addAccess', function(source, input)
    if not isAdmin(source) then return false, 'No permission.' end
    if type(input) ~= 'table' then return false, 'Invalid input.' end

    local discord = normalizeDiscord(input.discord)
    local name = tostring(input.name or ''):sub(1, 64)
    local badge = tostring(input.badge or ''):sub(1, 64)

    if not discord then return false, 'Discord ID is required.' end
    if name == '' then return false, 'Name is required.' end
    if badge == '' then return false, 'Badge is required.' end

    MySQL.insert.await([[
        INSERT INTO tmc_welcomer_access (discord, name, badge)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE name = VALUES(name), badge = VALUES(badge)
    ]], { discord, name, badge })

    return true, ('Access saved for %s.'):format(discord)
end)


lib.callback.register('welcomer:server:getAccessList', function(source)
    if not isAdmin(source) then return {} end

    local rows = MySQL.query.await([[
        SELECT discord, name, badge
        FROM tmc_welcomer_access
        ORDER BY updated_at DESC, created_at DESC
    ]]) or {}

    return rows
end)

lib.callback.register('welcomer:server:removeAccess', function(source, discordInput)
    if not isAdmin(source) then return false, 'No permission.' end

    local discord = normalizeDiscord(discordInput)
    if not discord then return false, 'Discord ID is required.' end

    local affected = MySQL.update.await('DELETE FROM tmc_welcomer_access WHERE discord = ?', { discord })
    if affected and affected > 0 then
        return true, ('Access removed for %s.'):format(discord)
    end

    return false, 'No data found for that Discord ID.'
end)

lib.callback.register('welcomer:server:updateLinks', function(source, input)
    if type(input) ~= 'table' then return false, 'Invalid input.' end

    local discord = getDiscordIdentifier(source)
    if not discord then return false, 'Discord identifier not found.' end

    local data = getAccessByDiscord(discord)
    if not data then return false, 'You do not have welcomer access.' end

    local image = tostring(input.image or '')
    local sound = tostring(input.sound or '')

    if image ~= '' and not image:match('^https?://') then
        return false, 'Image must be a direct http/https link.'
    end

    if sound ~= '' and not sound:match('^https?://') then
        return false, 'Sound must be a direct http/https link.'
    end

    MySQL.update.await('UPDATE tmc_welcomer_access SET image = ?, sound = ? WHERE discord = ?', {
        image, sound, discord
    })

    data.image = image
    data.sound = sound

    return true, 'Links saved.', data
end)

RegisterNetEvent('welcomer:server:previewOwn', function()
    local src = source
    local discord = getDiscordIdentifier(src)
    if not discord then return notify(src, 'Discord identifier not found.', 'error') end

    local data = getAccessByDiscord(discord)
    if not data then return notify(src, 'You do not have welcomer access.', 'error') end

    showWelcome(src, GetPlayerName(src), data)
end)

RegisterNetEvent('welcomer:server:previewAdmin', function(input)
    local src = source
    if not isAdmin(src) then return notify(src, 'No permission.', 'error') end
    if type(input) ~= 'table' then return end

    showWelcome(src, GetPlayerName(src), {
        name = tostring(input.name or GetPlayerName(src)),
        badge = tostring(input.badge or 'PREVIEW'),
        image = tostring(input.image or ''),
        sound = tostring(input.sound or '')
    })
end)

RegisterCommand('welcome', function(source)
    if source == 0 then return end

    local discord = getDiscordIdentifier(source)
    if not discord then return notify(source, 'Discord identifier not found.', 'error') end

    local data = getAccessByDiscord(discord)
    if not data then return notify(source, 'You are not authorized to use this command.', 'error') end

    showWelcome(-1, GetPlayerName(source), data)
end, false)

AddEventHandler('playerJoining', function()
    local src = source

    CreateThread(function()
        Wait(Config.JoinDelay)

        local discord = getDiscordIdentifier(src)
        if not discord then return end

        local data = getAccessByDiscord(discord)
        if data then
            showWelcome(-1, GetPlayerName(src), data)
        end
    end)
end)
