-- In the context of this bot, a module is pretty much anything the bot does that isn't a command.
-- For example: checking messages for advertising, decreasing warning levels.

local fs = require("fs")
local utils = require("./miscUtils")

local moduleHandler = {}
moduleHandler.modules = {}

moduleHandler.load = function()
	for _,filename in ipairs(fs.readdirSync("modules")) do
		if filename:match("%.lua$") then
			local mod = require("./modules/"..filename)
			moduleHandler.modules[mod.name] = mod
		end
	end
end

moduleHandler.doModules = function(event, guildSettings, ...)
	for modName, mod in pairs(moduleHandler.modules) do
		if mod.event==event and not guildSettings.disabled_modules[modName] then
			mod:run(guildSettings, ...)
		end
	end
end

return moduleHandler