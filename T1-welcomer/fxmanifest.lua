fx_version 'cerulean'
game 'gta5'

author 'Tier One Software'
description 'TMC Welcomer'
version '2.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependency 'ox_lib'
dependency 'oxmysql'
