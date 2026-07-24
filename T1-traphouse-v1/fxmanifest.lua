fx_version 'cerulean'
game 'gta5'

author 'Tier One Software'
description 'Traphouse V1'

lua54 'yes' 

shared_scripts {
    '@ox_lib/init.lua', 
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/exitvehicle.lua'
}

server_scripts {
    'server/main.lua'
}