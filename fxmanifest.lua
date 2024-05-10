fx_version 'bodacious'
game 'gta5'
description 'Advanced Lighting System - ALS is a spin off of FiveM ELS by MrDaGree'
author 'Abel Gaming'
version '1.0'
lua54 'yes'

server_scripts {
	'config.lua',
	'server/main.lua'
}

client_scripts {
	'config.lua',
	'client/main.lua',
	'client/functions.lua',
	'client/utility.lua',
	'client/events.lua'
}

exports {
	'ArePrimaryLightsActivated',
	'AreSecondaryLightsActivated',
	'AreWarningLightsActivated',
	'IsControlModuleOpen'
}