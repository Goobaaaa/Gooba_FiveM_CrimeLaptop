fx_version 'cerulean'
game 'gta5'

name 'crime_laptop'
description 'Criminal laptop with profile system, black market, and jobs'
author 'NDRP / Gooba'
version '1.0.0'

lua54 'yes'

dependency 'ox_inventory'
dependency 'oxmysql'

shared_scripts {
    'config.lua',
    'shared/utils.lua',
    'shared/framework.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/profiles.lua',
    'server/blackmarket.lua',
    'server/main.lua'
}

files {
    'nui/index.html',
    'nui/css/style.css',
    'nui/js/app.js',
    'nui/js/pages.js',
    'nui/js/api.js'
}

ui_page 'nui/index.html'
