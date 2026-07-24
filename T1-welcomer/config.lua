Config = {}

-- ESX groups allowed to use /adminwc.
-- This works with ESX /setgroup, example: /setgroup 1 admin
Config.AdminGroups = {
    admin = true,
    superadmin = true,
    owner = true,
    management = true
}

-- Optional ACE fallback. Leave as-is or set to '' if you do not use ACE.
Config.AdminAce = 'tmcwelcomer.admin'

-- How long the welcome card stays on screen (milliseconds)
Config.DisplayTime = 5000

-- Delay before showing welcome card after player joins (milliseconds)
Config.JoinDelay = 5000
