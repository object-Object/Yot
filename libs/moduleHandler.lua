-- In the context of this bot, a module is pretty much anything the bot does that isn't a module.
-- For example: checking messages for advertising, decreasing warning levels.

local fs = require("fs")
local json = require("json")
local utils = require("miscUtils")
local discordia = require("discordia")

local moduleHandler = {}
moduleHandler.modules = {}				-- table holding all modules with name as key and module table as value
moduleHandler.tree = {}					-- table holding all modules, in a class.event.module hierarchy
moduleHandler.sortedModuleNames = {}	-- table holding all modules as value, sorted alphabetically

moduleHandler.load = function()
	for class, classFiletype in fs.scandirSync("modules") do
		assert(classFiletype=="directory", "Non-directory file '"..class.."' in modules/ directory")
		if not moduleHandler.tree[class] then
			moduleHandler.tree[class] = {}
		end
		for event, eventFiletype in fs.scandirSync("modules/"..class) do
			assert(eventFiletype=="directory", "Non-directory file '"..event.."' in modules/"..class.."/ directory")
			if not moduleHandler.tree[class][event] then
				moduleHandler.tree[class][event] = {}
			end
			for _,filename in ipairs(fs.readdirSync("modules/"..class.."/"..event)) do
				if filename:match("%.lua$") then
					local mod = require("../modules/"..class.."/"..event.."/"..filename)
					--[[
					for code, lang in pairs(discordia.storage.langs) do
						local modLang = lang.modules[mod.name]
						assert(modLang~=nil, "Module "..class.."/"..event.."/"..mod.name.." has no "..code.." lang entries")
						assert(modLang.description~=nil, "Module "..class.."/"..event.."/"..mod.name.." has no "..code.." lang description entry")
					end --]]
					mod.event = class.."."..event
					moduleHandler.modules[mod.name] = mod
					moduleHandler.tree[class][event][mod.name] = mod
					table.insert(moduleHandler.sortedModuleNames, mod.name)
				end
			end
		end
	end
	table.sort(moduleHandler.sortedModuleNames)
end

moduleHandler.enable = function(modString, message, guildSettings, conn)
	if not moduleHandler.modules[modString]:onEnable(message, guildSettings, conn) then
		return false
	end
	guildSettings.disabled_modules[modString] = nil
	local encodedSetting = json.encode(guildSettings.disabled_modules)
	local stmt = conn:prepare("UPDATE guild_settings SET disabled_modules = ? WHERE guild_id = ?;")
	stmt:reset():bind(encodedSetting, message.guild.id):step()
	stmt:close()
	return true
end

moduleHandler.disable = function(modString, message, guildSettings, conn)
	if not moduleHandler.modules[modString]:onDisable(message, guildSettings, conn) then
		return false
	end
	guildSettings.disabled_modules[modString] = true
	local encodedSetting = json.encode(guildSettings.disabled_modules)
	local stmt = conn:prepare("UPDATE guild_settings SET disabled_modules = ? WHERE guild_id = ?;")
	stmt:reset():bind(encodedSetting, message.guild.id):step()
	stmt:close()
	return true
end

moduleHandler.doModules = function(event, guildSettings, ...)
	for _, mod in pairs(event) do
		if not guildSettings.disabled_modules[mod.name] then
			mod:run(guildSettings, ...)
		end
	end
end

return moduleHandler