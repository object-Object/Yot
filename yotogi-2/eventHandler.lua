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
			local event = require("./events/"..filename)
			events[event.name] = event
		end
	end
end

eventHandler.doEvents = function(discordEvent, guildSettings, ...)
	for eventName, event in pairs(events) do
		if event.discordEvent==discordEvent and not guildSettings.disabled_events[eventName] then
			event.run(guildSettings, ...)
		end
	end
end

return eventHandler