Config = {}

Config.Framework = 'esx' -- esx only
Config.Command = 'scoreboard'
Config.Key = 'F10'
Config.AdminCommand = 'adminsc'
Config.MaxPlayers = 128

Config.Logo = 'https://media.discordapp.net/attachments/1394984247550283870/1514190111498043423/TMC_PVP.png?ex=6a2a76ee&is=6a29256e&hm=9bce69abca5da60670a27a891e6c1e45027ff6951548311cf7688f6e4d8e74db&=&format=webp&quality=lossless&width=960&height=960'
Config.Banner = 'https://media.discordapp.net/attachments/1396392049695133780/1505186916620828692/TMC_BANNER.png?ex=6a2219cd&is=6a20c84d&hm=7caf8688a22571d408283fe39f458df24f6cb53ceffe8864c065ec2f8fdc348c&=&format=webp&quality=lossless&width=1521&height=856'

Config.AdminGroups = {
    admin = true,
    superadmin = true,
    owner = true,
    management = true
}

Config.JobLabels = {
    police = 'Police',
    ambulance = 'EMS',
    mechanic = 'Mechanic',
    taxi = 'Taxi',
    cardealer = 'Car Dealer'
}

Config.Commands = {
    { title = 'Leaderboard', command = '/leaderboard', desc = 'View the global leaderboard.' },
    { title = 'Exclusive Camera', command = '/exclucam', desc = 'Open the exclusive camera mode.' },
    { title = 'Hitmarker Menu', command = '/hitmarker', desc = 'Edit your hitmarker settings.' },
    { title = 'Exclusive Menu', command = '/myexclu', desc = 'Manage your exclusives.' }
}

Config.Rules = {
    { title = 'Respect Everyone', desc = 'No toxicity, harassment, or racism.' },
    { title = 'No Cheating', desc = 'No menus, exploits, or third-party tools.' },
    { title = 'Follow Staff', desc = 'Listen to admins/moderators when needed.' },
    { title = 'No VDM / RDM', desc = 'Do not randomly kill or vehicle-kill players.' },
    { title = 'Use Common Sense', desc = 'Do not abuse bugs or server systems.' }
}


Config.Currencies = {}
