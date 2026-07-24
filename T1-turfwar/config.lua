Config = {}
Config.CooldownTime = 10 -- Minutes players must wait AFTER a war is finished to start again
Config.WarDuration = 15   -- Minutes the actual Turf War lasts (Timer shown on UI)
Config.ShowCooldownNotification = true

-- Leaderboard bridge resource. Rename this if your leaderboard folder name is different.
Config.LeaderboardResource = 'T1-leaderboards'

-- Seconds before a player dies after leaving an active turfwar zone they already entered.
Config.LeaveZoneDeathTimer = 10

Config.RewardItems = {
    { item = 'ayuda1', count = 50 },
    { item = 'ayuda2', count = 50 },
    { item = 'ayuda3', count = 50 },
    { item = 'cash', count = 100000 },
    -- You can easily add more here:
}

Config.Turfs = {
    {
        name = "Kortz Center",
        coords = vector3(-2244.2229, 263.1041, 173.6154),
        radius = 250.0,
        isActive = false
    },
    {
        name = "Vinewood Hills",
        coords = vector3(689.6464, 599.4619, 129.0459),
        radius = 250.0,
        isActive = false
    },
    {
        name = "Pacific Ocean",
        coords = vector3(3541.3850, 3738.6082, 36.6801),
        radius = 250.0,
        isActive = false
    },
    {
        name = "N.O.O.S.E",
        coords = vector3(2505.8389, -384.4409, 94.1199),
        radius = 250.0,
        isActive = false
    },
    {
        name = "Stab City",
        coords = vector3(58.7818, 3712.7107, 38.7549),
        radius = 250.0,
        isActive = false
    }
}