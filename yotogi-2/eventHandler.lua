-- In the context of this bot, an event is pretty much anything the bot does that isn't a command.
-- This is not Discord events (e.g. messageCreate).
-- For example: checking messages for advertising.

local fs = require("fs")
local utils = require("./miscUtils")

local eventHandler = {}
local events = {}

eventHandler.load = function()
	for _,filename in ipairs(fs.readdirSync("events")) do
		if filename:match("%.lua$") then
			local mod = require("./events/"..filename)
			events[mod.name] = mod
		end
	end
end

eventHandler.doevents = function(discordEvent, guildSettings, ...)
	for modName, mod in pairs(events) do
		if mod.discordEvent==discordEvent and not guildSettings.disabled_events[modName] then
			mod.run(guildSettings, ...)
		end
	end
end

return eventHandler