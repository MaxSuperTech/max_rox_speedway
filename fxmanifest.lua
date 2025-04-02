fx_version 'cerulean'
game 'gta5'

author 'Koala'
description 'piste de cource pour roxwood'

shared_scripts {
	'@ox_lib/init.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/s_main.lua'
}

files {
    'config/*.lua',
    'locales/*.json'
}

dependencies {
    'ox_lib',
    
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'