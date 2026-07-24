Config = {}

Config.ActiveDuration = 30 * 60 * 1000
Config.CooldownDuration = 10 * 1000   

Config.TwoTrapHouses = false 

Config.AutoDeleteVehicle = true
Config.DisableExitRagdoll = false

-- New: Define your Gang Jobs and their Base Coords here
Config.GangBases = {
    ['gang1'] = { coords = vector3(-1497.7917, 866.0629, 181.5945), heading = 114.2124 },
    ['wf'] = { coords = vector3(-318.3441, 171.3542, 87.9180), heading = 354.1476 },
    ['sn'] = { coords = vector3(-427.8385, 1115.6877, 326.7759), heading = 340.2949 },
    ['bbl'] = { coords = vector3(-3145.4055, 1094.6259, 20.6955), heading = 158.4721 },
    ['zg'] = { coords = vector3(-1893.9375, 2052.2246, 140.9823), heading = 161.6492 },
    ['sns'] = { coords = vector3(-368.2663, 40.6010, 51.0591), heading = 93.2868 },
    ['police'] = { coords = vector3(448.3755, -1016.5302, 28.5475), heading = 88.1300 },
    -- Add more jobs as needed
}

Config.StaticLocations = {
    ['City Hall'] = { coords = vector3(-304.0320, -976.7987, 31.0806), heading = 248.4718 }
}

Config.Zones = {
    {coords = vector3(1212.8112, -552.9476, 69.1677), radius = 250.0, name = 'Mirror Park'},
    {coords = vector3(-1273.8007, 316.0552, 65.5118), radius = 250.0, name = 'GWC'},
    {coords = vector3(-3037.2466, 559.2155, 7.5077), radius = 250.0, name = 'Great Ocean'},
    {coords = vector3(-1661.2380, -533.3576, 36.0240), radius = 250.0, name = 'Banner Hotel'},
    {coords = vector3(-135.4233, 6266.1240, 32.8072), radius = 250.0, name = 'Paleto'},
    {coords = vector3(989.9638, -3054.8944, 5.9005), radius = 250.0, name = 'Docs'}
}

Config.TeleportLocations = {
    ['Mirror Park'] = {
        { coords = vector3(1163.8461, -876.9563, 53.2082), heading = 342.8044 },
        { coords = vector3(1064.0144, -228.3266, 69.2170), heading = 247.6459 },
        { coords = vector3(986.4192, -304.8241, 66.6162), heading = 239.0099 },
    },
    ['GWC'] = {
        { coords = vector3(-1414.56, -58.70, 52.34), heading = 20.03 },
        { coords = vector3(-856.35, 223.71, 73.23), heading = 71.43 },
        { coords = vector3(-1408.70, -70.04, 52.20), heading = 22.54 },
        { coords = vector3(-855.90, 437.11, 86.62), heading = 93.19 },
    },
    ['Great Ocean'] = {
        { coords = vector3(-3051.2610, 225.3382, 16.2097), heading = 60.5516 },
        { coords = vector3(-3029.6807, 225.3781, 16.1059), heading = 349.2190 },
        { coords = vector3(-3142.2566, 860.7884, 15.4662), heading = 209.5601 },
    },
    ['Banner Hotel'] = {
        { coords = vector3(-1429.2205, -761.9808, 23.5419), heading = 45.1053 },
        { coords = vector3(-1872.9410, -228.2241, 38.2446), heading = 215.0244 },
        { coords = vector3(-1559.7607, -183.5738, 55.5229), heading = 143.4241 },
        { coords = vector3(-1297.3450, -343.9846, 36.7372), heading = 116.0839 },
    },
    ['Paleto'] = {
        { coords = vector3(-357.2507, 6027.8882, 31.2215), heading = 311.5703 },
        { coords = vector3(132.2832, 6509.3882, 31.5092), heading = 133.6990 },
        { coords = vector3(-69.1872, 6598.4121, 29.4728), heading = 136.7861 },
        { coords = vector3(-477.7862, 6345.6304, 11.5235), heading = 301.8923 },
    },
    ['Docs'] = {
        { coords = vector3(738.85, -2796.08, 6.38), heading = 180.32 },
        { coords = vector3(818.11, -3324.44, 14.31), heading = 269.27 },
        { coords = vector3(1256.62, -3304.35, 5.80), heading = 0.05 },
    }
}

