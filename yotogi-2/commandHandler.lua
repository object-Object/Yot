local fs = require("fs")
local utils = require("./miscUtils")

local handler = {}
local commands = {}

handler.load = function()
	for _,filename in ipairs(fs.readdirSync("commands")) do
		if filename:match("%.lua$") then
			local command = require("./commands/"..filename)
			commands[command.name]=command
		end
	end
end

handler.doCommand = function(message, guildSettings, conn)
	local content = message.content:gsub("^"..utils.escapePatterns(guildSettings.prefix),"")
		:gsub("^%<%@%!?"..message.client.user.id.."%>%s+","")
	local commandString = content:match("^(%S+)")
	local command = commands[commandString]
	if command then
		local argString = content:gsub("^"..commandString.."%s*","")
		local args = argString:split("%s")
		command.run(message, argString, args, guildSettings, conn)
	end
end

handler.sendUsage = function(channel, prefix, commandString)
	local command = commands[commandString]
	return utils.sendEmbed(channel, "Usage: `"..prefix..command.usage.."`", "ff0000")
end

return handler