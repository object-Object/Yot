local fs = require("fs")
local utils = require("./miscUtils")

local handler = {}
local commands = {}
local customPermissions = {
	botOwner = function(member)
		return member.user==member.client.owner
	end
}

handler.load = function()
	for _,filename in ipairs(fs.readdirSync("commands")) do
		if filename:match("%.lua$") then
			local command = require("./commands/"..filename)
			commands[command.name] = command
		end
	end
end

handler.sendUsage = function(channel, prefix, commandString)
	local command = commands[commandString]
	return utils.sendEmbed(channel, "Usage: `"..prefix..command.usage.."`", "ff0000",
		"Angled brackets represent required arguments. Square brackets represent optional arguments. Do not include the brackets in the command.")
end

handler.sendPermissionError = function(channel, commandString, missingPermissions)
	return utils.sendEmbed(channel, "You need the following permission"..utils.s(#missingPermissions).." to use this command: `"
		..table.concat(missingPermissions,", ").."`", "ff0000")
end

handler.doCommand = function(message, guildSettings, conn)
	local content = message.content:gsub("^"..utils.escapePatterns(guildSettings.prefix),"")
		:gsub("^%<%@%!?"..message.client.user.id.."%>%s+","")
	local commandString = content:match("^(%S+)")
	local command = commands[commandString]
	if command then
		local permissions = guildSettings.command_permissions[commandString] or command.permissions
		local missingPermissions = {}
		for _,permission in pairs(permissions) do
			if permission:match("^yotogi%.") then
				if not customPermissions[permission:match("^yotogi%.(.+)")](message.member) then
					table.insert(missingPermissions, permission)
				end
			else
				if not message.member:hasPermission(permission) then
					table.insert(missingPermissions, permission)
				end
			end
		end
		if #missingPermissions==0 then
			local argString = content:gsub("^"..commandString.."%s*","")
			local args = argString:split("%s")
			command.run(message, argString, args, guildSettings, conn)
		else
			handler.sendPermissionError(message.channel, commandString, missingPermissions)
		end
		if guildSettings.delete_command_messages then message:delete() end
	end
end

return handler