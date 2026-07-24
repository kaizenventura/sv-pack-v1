Config = {}

Config.RespawnTimer = 30

-- Respawn penalty
Config.RespawnFee = 0 -- no cash/bank payment required
Config.RemoveItemsOnRespawn = true -- uses ox_inventory ClearInventory

-- Traphouse bridge: kapag namatay sa active traphouse red zone, 5 seconds lang respawn timer.
Config.TraphouseBridge = {
    enabled = true,
    resource = 'T1-traphouse-v1',
    respawnTimer = 5
}

Config.MenuOpenDelay = 5000 -- 5 seconds before full menu opens, timer starts agad -- seconds before Respawn Now can be clicked
Config.OpenKey = 'G' -- while dead, press this to open/minimize menu
Config.DisableAutoOpen = false -- set true if you only want to open using command/key

-- Set each ESX job gang/base respawn here.
-- Job name must match xPlayer.job.name / esx:setJob name.
-- If player is unemployed, Gang Base will not show.
Config.GangBaseLocations = {
    police = {
        label = 'Police Base',
        description = 'Spawn at Police Department',
        image = 'logo.png',
        coords = vec4(448.9391, -1017.0063, 28.5426, 85.4142)
    },

    -- Example gang jobs, edit/add more here.
    gang1 = {
        label = 'Gang Base',
        description = 'Spawn at Gang Base',
        image = 'logo.png',
        coords = vec4(-1501.4525, 865.9074, 181.7371, 113.6078)
    },
    wf = {
        label = 'Gang Base',
        description = 'Spawn at Gang Base',
        image = 'logo.png',
        coords = vec4(-318.3441, 171.3542, 87.9180, 354.1476)
    },
    sn = {
        label = 'Gang Base',
        description = 'Spawn at Gang Base',
        image = 'logo.png',
        coords = vec4(-427.8385, 1115.6877, 326.7759, 340.2949)
    },
    zg = {
        label = 'Gang Base',
        description = 'Spawn at Gang Base',
        image = 'logo.png',
        coords = vec4(-1893.9375, 2052.2246, 140.9823, 161.6492)
    },
    sns = {
        label = 'Gang Base',
        description = 'Spawn at Gang Base',
        image = 'logo.png',
        coords = vec4(-368.2661, 40.6011, 51.0591, 94.1703)
    },
    bbl = {
        label = 'Gang Base',
        description = 'Spawn at Gang Base',
        image = 'logo.png',
        coords = vec4(-3145.3362, 1094.4634, 20.6954, 68.4298)
    }
}

-- Public respawn locations. Do not put Gang Base here; it is added automatically from Config.GangBaseLocations.
Config.Locations = {
    {
        label = 'City Hall',
        description = 'Spawn at City Hall',
        image = 'logo.png',
        coords = vec4(-307.2602, -1008.7294, 30.3851, 69.7270)
    },
    {
        label = 'Hospital',
        description = 'Spawn at Hospital',
        image = 'logo.png',
        coords = vec4(-978.0415, -797.9454, 17.6878, 354.2555)
    },
    {
        label = 'Tabing Ilog',
        description = 'Spawn at Tabing Ilog',
        image = 'logo.png',
        coords = vec4(464.5871, 3566.2424, 33.2386, 342.9038)
    }
}