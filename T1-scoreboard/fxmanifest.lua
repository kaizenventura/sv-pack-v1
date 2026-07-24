fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'TMC PVP'
description 'TMC PVP ESX Scoreboard - Glassmorphism HTML NUI + ox_lib announcements'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- optional but recommended for persistent announcements
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

dependency 'ox_lib'
