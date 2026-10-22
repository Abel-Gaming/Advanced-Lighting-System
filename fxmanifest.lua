fx_version 'cerulean'
game 'gta5'
description 'Advanced Lighting System - ALS is a spin off of FiveM ELS by MrDaGree'
author 'Abel Gaming'
version '1.2'
lua54 'yes'

ui_page 'html/index.html'

files {
	'html/index.html',
	'html/style.css',
	'html/app.js',
}

shared_scripts {
	'config.lua',
	'sh_data.lua',
}

server_scripts {
	's_main.lua',
}

client_scripts {
	'cl_utility.lua',
	'cl_functions.lua',
	'cl_events.lua',
	'cl_main.lua',
	'cl_editor.lua',
}
