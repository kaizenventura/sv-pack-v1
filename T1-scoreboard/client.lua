local ESX = exports['es_extended']:getSharedObject()
local scoreboardOpen = false

local function openScoreboard()
    if scoreboardOpen then return end
    scoreboardOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('tmc-scoreboard:requestData')
end

local function closeScoreboard()
    scoreboardOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.Command, openScoreboard, false)
RegisterKeyMapping(Config.Command, 'Open TMC Scoreboard', 'keyboard', Config.Key)

RegisterNUICallback('close', function(_, cb)
    closeScoreboard()
    cb('ok')
end)

RegisterNUICallback('runCommand', function(data, cb)
    local command = data and data.command
    local allowed = {
        exclucam = true,
        excluwc = true,
        exclukillfeed = true,
        myexclu = true
    }

    if command and allowed[command] then
        closeScoreboard()
        Wait(100)
        ExecuteCommand(command)
    end

    cb('ok')
end)

RegisterNetEvent('tmc-scoreboard:openData', function(data)
    data.logo = Config.Logo
    data.banner = Config.Banner
    data.commands = Config.Commands
    data.rules = Config.Rules
    data.maxPlayers = Config.MaxPlayers
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNetEvent('tmc-scoreboard:refreshAnnouncements', function(announcements)
    SendNUIMessage({ action = 'announcements', announcements = announcements })
end)

-- Admin announcement manager using ox_lib context/input dialogs
local function openAnnouncementManage(id)
    lib.registerContext({
        id = 'tmc_sc_manage_' .. tostring(id),
        title = 'Manage Announcement',
        menu = 'tmc_sc_admin_announcements',
        options = {
            {
                title = 'Edit Announcement',
                icon = 'pen-to-square',
                onSelect = function()
                    local input = lib.inputDialog('Edit Announcement', {
                        { type = 'input', label = 'Title', required = true },
                        { type = 'textarea', label = 'Message', required = true, autosize = true },
                        { type = 'input', label = 'Image Link', required = false }
                    })
                    if not input then return end
                    TriggerServerEvent('tmc-scoreboard:editAnnouncement', id, input[1], input[2], input[3] or '')
                end
            },
            {
                title = 'Remove Announcement',
                icon = 'trash',
                iconColor = '#ff4d6d',
                onSelect = function()
                    TriggerServerEvent('tmc-scoreboard:removeAnnouncement', id)
                end
            }
        }
    })
    lib.showContext('tmc_sc_manage_' .. tostring(id))
end

RegisterNetEvent('tmc-scoreboard:adminMenu', function(announcements)
    local options = {
        {
            title = 'Add Announcement',
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog('Add Announcement', {
                    { type = 'input', label = 'Title', required = true },
                    { type = 'textarea', label = 'Message', required = true, autosize = true },
                    { type = 'input', label = 'Image Link', required = false }
                })
                if not input then return end
                TriggerServerEvent('tmc-scoreboard:addAnnouncement', input[1], input[2], input[3] or '')
            end
        }
    }

    for _, ann in ipairs(announcements or {}) do
        options[#options + 1] = {
            title = ann.title,
            description = ann.message,
            icon = 'bullhorn',
            onSelect = function()
                openAnnouncementManage(ann.id)
            end
        }
    end

    lib.registerContext({
        id = 'tmc_sc_admin_announcements',
        title = 'Scoreboard Announcements',
        options = options
    })
    lib.showContext('tmc_sc_admin_announcements')
end)

RegisterCommand(Config.AdminCommand, function()
    TriggerServerEvent('tmc-scoreboard:requestAdminMenu')
end, false)

RegisterNetEvent('tmc-scoreboard:notify', function(msg, type)
    lib.notify({ title = 'TMC Scoreboard', description = msg, type = type or 'inform' })
end)
