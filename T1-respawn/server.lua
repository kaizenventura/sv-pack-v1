ESX = exports['es_extended']:getSharedObject()


local AllowedDiscordIDs = {
    ['1394982497544044637'] = true,
    ['1363689259789451385'] = true,
    ['1343041534940938321'] = true,
    ['693742027954847794'] = true,
    ['1303925016643239937'] = true,
    ['1148007992747372594'] = true,
    ['1175317658355380306'] = true
}

local function HasReviveAccess(source)
    if source == 0 then return true end

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        local discord = identifier:match('discord:(%d+)')
        if discord and AllowedDiscordIDs[discord] then
            return true
        end
    end

    return false
end


local function Notify(source, title, description, notifyType)
    TriggerClientEvent('t1_respawn:notify', source, {
        title = title,
        description = description,
        type = notifyType or 'inform'
    })
end

local function GetAccountMoney(xPlayer, accountName)
    local account = xPlayer.getAccount(accountName)
    return account and account.money or 0
end

local function ChargeRespawnFee(xPlayer, fee)
    if fee <= 0 then
        return true, 'free'
    end

    local cash = xPlayer.getMoney()
    if cash >= fee then
        xPlayer.removeMoney(fee)
        return true, 'cash'
    end

    local bank = GetAccountMoney(xPlayer, 'bank')
    if bank >= fee then
        xPlayer.removeAccountMoney('bank', fee)
        return true, 'bank'
    end

    return false, nil
end

local function ClearPlayerInventory(source)
    if GetResourceState('ox_inventory') ~= 'started' then
        return false
    end

    exports.ox_inventory:ClearInventory(source)
    return true
end

ESX.RegisterServerCallback('t1_respawn:payAndClearInventory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    local fee = tonumber(Config.RespawnFee) or 0
    local paid, paymentType = ChargeRespawnFee(xPlayer, fee)

    if not paid then
        Notify(source, 'Respawn', ('You need $%s cash or bank to respawn.'):format(fee), 'error')
        cb(false)
        return
    end

    if Config.RemoveItemsOnRespawn ~= false then
        ClearPlayerInventory(source)
    end

    if fee > 0 then
        Notify(source, 'Respawn', ('Respawn fee paid: $%s from %s. Inventory cleared.'):format(fee, paymentType), 'success')
    else
        Notify(source, 'Respawn', 'Inventory cleared.', 'success')
    end

    cb(true)
end)

RegisterCommand('revive', function(source, args)
    if not HasReviveAccess(source) then
        return
    end

    local target = tonumber(args[1])
    if not target then return end

    TriggerClientEvent('t1_respawn:forceRevive', target)
end, false)
