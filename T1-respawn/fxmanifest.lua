fx_version 'cerulean'
game 'gta5'

author 'tieronesoftware.com'
description 'ESX Respawn HTML Menu'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/logo.png'
}

dependencies {
    'es_extended',
    'ox_inventory'
}

server_script 'server.lua'
