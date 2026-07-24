local function notify(msg, msgType)
    lib.notify({
        title = 'TMC Welcomer',
        description = msg,
        type = msgType or 'inform'
    })
end

RegisterNetEvent('welcomer:client:show', function(data)
    SendNUIMessage({
        type = 'show',
        name = data.name,
        badge = data.badge,
        image = data.image,
        sound = data.sound,
        duration = data.duration or Config.DisplayTime
    })
end)

local function openAdminMenu()
    local allowed = lib.callback.await('welcomer:server:isAdmin', false)
    if not allowed then
        return notify('No permission.', 'error')
    end

    lib.registerContext({
        id = 'tmc_welcomer_admin',
        title = 'Admin Welcomer',
        options = {
            {
                title = 'Add / Update Access',
                description = 'Set Discord, display name, and badge.',
                icon = 'user-plus',
                onSelect = function()
                    local input = lib.inputDialog('Add / Update Welcomer Access', {
                        { type = 'input', label = 'Discord ID', description = 'Example: 1394982497544044637 or discord:1394982497544044637', required = true },
                        { type = 'input', label = 'Name', description = 'This replaces the old message text.', required = true, max = 64 },
                        { type = 'input', label = 'Badge', description = 'Example: OWNER / DEVELOPER / VIP', required = true, max = 64 },
                    })
                    if not input then return end

                    local ok, msg = lib.callback.await('welcomer:server:addAccess', false, {
                        discord = input[1],
                        name = input[2],
                        badge = input[3]
                    })

                    notify(msg or (ok and 'Saved.' or 'Failed.'), ok and 'success' or 'error')

                    if ok then
                        TriggerServerEvent('welcomer:server:previewAdmin', {
                            name = input[2],
                            badge = input[3]
                        })
                    end
                end
            },
            {
                title = 'Remove Access',
                description = 'Select from saved identifiers made by admins.',
                icon = 'user-minus',
                onSelect = function()
                    local accessList = lib.callback.await('welcomer:server:getAccessList', false) or {}

                    if #accessList < 1 then
                        return notify('No saved identifiers found.', 'error')
                    end

                    local removeOptions = {}
                    for _, data in ipairs(accessList) do
                        removeOptions[#removeOptions + 1] = {
                            title = data.discord or 'Unknown Identifier',
                            description = ('Name: %s | Badge: %s'):format(data.name or 'N/A', data.badge or 'N/A'),
                            icon = 'id-card',
                            onSelect = function()
                                local confirm = lib.alertDialog({
                                    header = 'Remove Welcomer Access',
                                    content = ('Remove access for %s?'):format(data.discord or 'this identifier'),
                                    centered = true,
                                    cancel = true
                                })

                                if confirm ~= 'confirm' then return end

                                local ok, msg = lib.callback.await('welcomer:server:removeAccess', false, data.discord)
                                notify(msg or (ok and 'Removed.' or 'Failed.'), ok and 'success' or 'error')
                            end
                        }
                    end

                    lib.registerContext({
                        id = 'tmc_welcomer_remove_list',
                        title = 'Remove Welcomer Access',
                        menu = 'tmc_welcomer_admin',
                        options = removeOptions
                    })

                    lib.showContext('tmc_welcomer_remove_list')
                end
            },
            {
                title = 'Preview Mine',
                description = 'Preview your current saved welcomer card.',
                icon = 'eye',
                onSelect = function()
                    TriggerServerEvent('welcomer:server:previewOwn')
                end
            }
        }
    })

    lib.showContext('tmc_welcomer_admin')
end

local function openPlayerMenu()
    local hasAccess, data = lib.callback.await('welcomer:server:hasAccess', false)
    if not hasAccess then
        return notify('You do not have welcomer access.', 'error')
    end

    lib.registerContext({
        id = 'tmc_welcomer_player',
        title = 'Exclusive Welcomer',
        options = {
            {
                title = 'Set Image & Sound Links',
                description = 'Add your image link and sound link.',
                icon = 'image',
                onSelect = function()
                    local input = lib.inputDialog('Welcomer Links', {
                        { type = 'input', label = 'Image Link', description = 'Direct http/https image link', required = false, default = data and data.image or '' },
                        { type = 'input', label = 'Sound Link', description = 'Direct http/https audio link', required = false, default = data and data.sound or '' },
                    })
                    if not input then return end

                    local ok, msg = lib.callback.await('welcomer:server:updateLinks', false, {
                        image = input[1],
                        sound = input[2]
                    })

                    notify(msg or (ok and 'Saved.' or 'Failed.'), ok and 'success' or 'error')

                    if ok then
                        TriggerServerEvent('welcomer:server:previewOwn')
                    end
                end
            },
            {
                title = 'Preview',
                description = 'Preview at the same welcomer position.',
                icon = 'eye',
                onSelect = function()
                    TriggerServerEvent('welcomer:server:previewOwn')
                end
            }
        }
    })

    lib.showContext('tmc_welcomer_player')
end

RegisterCommand('adminwc', openAdminMenu, false)
RegisterCommand('excluwc', openPlayerMenu, false)
