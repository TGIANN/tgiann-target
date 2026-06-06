-- FX Information
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
nui_callback_strict_mode 'true'
lua54 'yes'
game 'gta5'

-- Resource Information
name 'tgiann-target'
author 'TGIANN'
version '1.0.0'
repository 'https://github.com/TGIANN/tgiann-target'
description ''

-- Manifest
ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua'
}

files {
    'web/build/**',
    'locales/*.json',
    'client/api.lua',
    'client/config.lua',
    'client/canInteract.lua',
    'client/utils/convar.lua',
    'client/utils/shared.lua',
    'client/utils/world.lua',
    'client/utils/player.lua',
    'client/utils/nui.lua',
    'client/utils/dui.lua',
    'client/state.lua',
    'client/debug.lua',
    'client/defaults.lua',
    'client/framework/nd.lua',
    'client/framework/ox.lua',
    'client/framework/esx.lua',
    'client/framework/qb.lua',
    'client/framework/qbx.lua',
    'client/compat/qbtarget.lua',
}

-- Drop-in replacement. Provides ox_target by default so exports.ox_target keeps working.
-- To replace qb-target instead, change this to 'qb-target'
provide 'ox_target'

dependency 'ox_lib'
