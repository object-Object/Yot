local fs = require("fs")
local utils = require("./miscUtils")

local commandHandler = {}

commandHandler.commands = {}
commandHandler.sortedCommandNames = {}

commandHandler.customPermissions = {
	botOwner = function(member)
		return member.user==member.client.owner
	end
}

commandHandler.strings = { -- bits of text used in multiple places that should be consistent
	usageFooter = "Angled brackets represent required arguments. Square brackets represent optional arguments. Do not include the brackets in the command."
}

commandHandler.load = function()
	for _,filename in ipairs(fs.readdirSync("commands")) do
		if filename:match("%.lua$") then
			local command = require("./commands/"..filename)
			commandHandler.commands[command.name] = command
			table.insert(commandHandler.sortedCommandNames, command.name)
		end
	end
	table.sort(commandHandler.sortedCommandNames)
end

commandHandler.stripPrefix = function(str, guildSettings, client)
	return str:gsub("^"..utils.escapePatterns(guildSettings.prefix),""):gsub("^%<%@%!?"..client.user.id.."%>%s+","")
end

commandHandler.sendUsage = function(channel, prefix, commandString)
	local command = commandHandler.commands[commandString]
	return utils.sendEmbed(channel, "Usage: `"..prefix..command.usage.."`", "ff0000", commandHandler.strings.usageFooter)
end

commandHandler.sendPermissionError = function(channel, commandString, missingPermissions)
	return utils.sendEmbed(channel, "You need the following permission"..utils.s(#missingPermissions).." to use this command: `"
		..table.concat(missingPermissions,", ").."`", "ff0000")
end

commandHandler.doCommand = function(message, guildSettings, conn)
	local content = commandHandler.stripPrefix(message.content, guildSettings, message.client)
	local commandString = content:match("^(%S+)")
	local command = commandHandler.commands[commandString]
	if message.content~=content and command and not guildSettings.disabled_commands[commandString] then
		local permissions = guildSettings.command_permissions[commandString] or command.permissions
		local missingPermissions = {}
		for _,permission in pairs(permissions) do
			if permission:match("^yotogi%.") then
				if not commandHandler.customPermissions[permission:match("^yotogi%.(.+)")](message.member) then
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
			command:run(message, argString, args, guildSettings, conn)
		else
			commandHandler.sendPermissionError(message.channel, commandString, missingPermissions)
		end
		if guildSettings.delete_command_messages then message:delete() end
	end
end

commandHandler.doSubcommand = function(message, argString, args, guildSettings, conn, commandString)
	local command = commandHandler.commands[commandString]
	local subcommand = command.subcommands[args[1]]
	if subcommand then
		argString=argString:gsub("^%S+%s*","")
		table.remove(args,1)
		subcommand:run(message, argString, args, guildSettings, conn)
		return true
	end
	return false
end

return commandHandler