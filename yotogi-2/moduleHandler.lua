-- In the context of this bot, a module is pretty much anything the bot does that isn't a module.
-- For example: checking messages for advertising, decreasing warning levels.

local fs = require("fs")
local json = require("json")
local utils = require("./miscUtils")

local moduleHandler = {}
moduleHandler.modules = {}
moduleHandler.sortedModuleNames = {}

moduleHandler.load = function()
	for _,filename in ipairs(fs.readdirSync("modules")) do
		if filename:match("%.lua$") then
			local mod = require("./modules/"..filename)
			moduleHandler.modules[mod.name] = mod
			table.insert(moduleHandler.sortedModuleNames, mod.name)
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
	for _, mod in pairs(moduleHandler.modules) do
		if mod.event==event and not guildSettings.disabled_modules[mod.name] then
			mod:run(guildSettings, ...)
		end
	end
end

return moduleHandler