fx_version 'cerulean'
game 'gta5'

name 'qbx_animal'
author 'Qbox Community'
description 'Pet System for Qbox Framework'
version '1.0.0'

lua54 'yes'
use_fxv2_oal 'yes'

dependencies {
    'qbx_core',
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}