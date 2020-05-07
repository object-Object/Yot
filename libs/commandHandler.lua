local fs = require("fs")
local utils = require("miscUtils")
local json = require("json")
local discordia = require("discordia")

local function applySubcommandReferences(command, baseCommand)
	for _, subcommand in pairs(command.subcommands) do
		subcommand.parentCommand = command
		subcommand.baseCommand = baseCommand
		subcommand.isSubcommand = true
		applySubcommandReferences(subcommand, baseCommand)
	end
end

local commandHandler = {}

commandHandler.commands = {}				-- keys: commandString, values: command table
commandHandler.tree = {}					-- table for each category, holding commands in same format as commandHandler.commands
commandHandler.sortedCategoryNames = {}		-- values: category names, sorted alphabetically
commandHandler.sortedCommandNames = {}		-- table for each category, values: command names, sorted alphabetically
commandHandler.sortedPermissionNames = {}	-- values: permission enums, sorted alphabetically

commandHandler.customPermissions = {
	botOwner = function(member)
		return member.user==member.client.owner
	end
}

commandHandler.strings = { -- generate proper text to be used in lang strings
	warnFooter = function(guildSettings, lang, entry)
		return f(lang.footer.warn_info,
			entry.is_active and utils.secondsToTime(entry.end_timestamp-os.time(), lang) or lang.g.not_applicable,
			entry.level<guildSettings.warning_kick_level and guildSettings.warning_kick_level-entry.level or lang.g.not_applicable,
			entry.level<guildSettings.warning_ban_level and guildSettings.warning_ban_level-entry.level or lang.g.not_applicable,
			entry.is_active and lang.g.yes or lang.g.no)
	end,
	muteFooter = function(guildSettings, lang, length, end_timestamp, is_active)
		return f(lang.footer.mute_info, 
			is_active and utils.secondsToTime(end_timestamp-os.time(), lang) or lang.g.not_applicable,
			utils.secondsToTime(length, lang),
			is_active and lang.g.yes or lang.g.no)
	end
}

commandHandler.load = function()
	for category, filetype in fs.scandirSync("commands") do
		assert(filetype=="directory", "Non-directory file '"..category.."' in commands/ directory")
		if not commandHandler.tree[category] then
			commandHandler.tree[category] = {}
			commandHandler.sortedCommandNames[category] = {}
			table.insert(commandHandler.sortedCategoryNames, category)
		end
		for code, lang in pairs(discordia.storage.langs) do
			assert(lang.categories[category]~=nil, "Category "..category.." has no "..code.." lang entry")
		end
		for _, commandFilename in ipairs(fs.readdirSync("commands/"..category)) do
			if commandFilename:match("%.lua$") then
				local command = require("../commands/"..category.."/"..commandFilename)
				--[[
				for code, lang in pairs(discordia.storage.langs) do
					local commandLang = lang.commands[command.name]
					assert(commandLang~=nil, "Command "..category.."/"..command.name.." has no "..code.." lang entries")
					assert(commandLang.description~=nil, "Command "..category.."/"..command.name.." has no "..code.." lang description entry")
					assert(commandLang.usage~=nil, "Command "..category.."/"..command.name.." has no "..code.." lang usage entry")
				end --]]
				applySubcommandReferences(command, command)
				command.parentCommand = command
				command.baseCommand = command
				command.isSubcommand = false
				command.category = category
				commandHandler.commands[command.name] = command
				commandHandler.tree[category][command.name] = command
				table.insert(commandHandler.sortedCommandNames[category], command.name)
			end
		end
	end
	table.sort(commandHandler.sortedCommandNames)
	commandHandler.sortedPermissionNames = table.keys(discordia.enums.permission)
	table.sort(commandHandler.sortedPermissionNames)
end

commandHandler.stripPrefix = function(str, guildSettings, client)
	return str:gsub("^"..utils.escapePatterns(guildSettings.prefix),""):gsub("^%<%@%!?"..client.user.id.."%>%s+","")
end

-- input can be string.split-ed table (for efficiency, if you've already split it) or string
-- string should contain command name
commandHandler.subcommandFromString = function(command, input)
	local inputType = type(input)
	assert(inputType=="table" or inputType=="string", "Expected table or string for argument #1, got "..inputType)
	local splitStr = inputType=="table" and input or input:split("%s+")
	table.remove(splitStr, 1) -- remove the base command name from splitStr
	local output = command
	if #splitStr>0 then
		local currentCommand = command
		local subcommand
		repeat
			subcommand = currentCommand.subcommands[splitStr[1]]
			if subcommand then
				currentCommand = subcommand
				table.remove(splitStr, 1)
			end
		until not subcommand or #splitStr==0
		output = subcommand or currentCommand
	end
	return output, table.concat(splitStr, " "), splitStr
end

commandHandler.sendUsage = function(channel, guildSettings, lang, command)
	return utils.sendEmbed(channel, f(lang.g.usage_str, guildSettings.prefix..command.name.." "..lang.commands[command.name].usage), "ff0000", lang.footer.cmd_usage)
end

commandHandler.sendCommandHelp = function(channel, guildSettings, lang, command)
	local baseCommand = command.baseCommand
	if guildSettings.disabled_commands[baseCommand.name] then
		channel:send{
			embed = {
				title = guildSettings.prefix..command.name,
				description = f(lang.error.command_disabled, guildSettings.prefix..baseCommand.name),
				color = discordia.Color.fromHex("ff0000").value
			}
		}
	else
		local subcommandsKeys = table.keys(command.subcommands)
		table.sort(subcommandsKeys)
		local permissionsString = #baseCommand.permissions>0 and "`"..table.concat(baseCommand.permissions, ", ").."`" or lang.g.none
		local subcommandsString = #subcommandsKeys>0 and "`"..table.concat(subcommandsKeys, "`, `").."`" or lang.g.none
		channel:send{
			embed = {
				title = guildSettings.prefix..command.name,
				description = lang.commands[command.name].description:gsub("%&prefix%;", guildSettings.prefix),
				fields = {
					{name = lang.g.category, value = lang.categories[baseCommand.category]},
					{name = lang.g.required_permissions, value = permissionsString},
					{name = lang.g.subcommands, value = subcommandsString},
					{name = lang.g.usage, value = "`"..guildSettings.prefix..command.name.." "..lang.commands[command.name].usage.."`"}
				},
				color = discordia.Color.fromHex("00ff00").value,
				footer = {
					text = lang.footer.cmd_usage
				}
			}
		}
	end
end

commandHandler.sendPermissionError = function(channel, commandString, missingPermissions, lang)
	return utils.sendEmbed(channel, f(lang.error.missing_permissions, utils.s(#missingPermissions), table.concat(missingPermissions,", ")), "ff0000")
end

commandHandler.enable = function(commandString, message, guildSettings, conn)
	if not commandHandler.commands[commandString]:onEnable(message, guildSettings, conn) then
		return false
	end
	guildSettings.disabled_commands[commandString] = nil
	local encodedSetting = json.encode(guildSettings.disabled_commands)
	local stmt = conn:prepare("UPDATE guild_settings SET disabled_commands = ? WHERE guild_id = ?;")
	stmt:reset():bind(encodedSetting, message.guild.id):step()
	stmt:close()
	return true
end

commandHandler.disable = function(commandString, message, guildSettings, conn)
	if not commandHandler.commands[commandString]:onDisable(message, guildSettings, conn) then
		return false
	end
	guildSettings.disabled_commands[commandString] = true
	local encodedSetting = json.encode(guildSettings.disabled_commands)
	local stmt = conn:prepare("UPDATE guild_settings SET disabled_commands = ? WHERE guild_id = ?;")
	stmt:reset():bind(encodedSetting, message.guild.id):step()
	stmt:close()
	return true
end

commandHandler.doCommands = function(message, guildSettings, lang, conn)
	local content = commandHandler.stripPrefix(message.content, guildSettings, message.client)
	local commandString = content:match("^(%S+)")
	local command = commandHandler.commands[commandString]
	if message.content~=content and command and not guildSettings.disabled_commands[commandString] then
		local permissions = guildSettings.command_permissions[commandString] or command.permissions
		local missingPermissions = {}
		for _,permission in pairs(permissions) do
			if permission:match("^yot%.") then
				if not commandHandler.customPermissions[permission:match("^yot%.(.+)")](message.member) then
					table.insert(missingPermissions, permission)
				end
			else
				if not message.member:hasPermission(permission) then
					table.insert(missingPermissions, permission)
				end
			end
		end
		if #missingPermissions==0 then
			local argString, args
			if command.subcommands~={} then
				command, argString, args = commandHandler.subcommandFromString(command, content)
			else
				argString = content:gsub("^"..commandString.."%s*","")
				args = argString:split("%s")
			end
			command:run(message, argString, args, guildSettings, lang, conn)
		else
			commandHandler.sendPermissionError(message.channel, commandString, missingPermissions, lang)
		end
		if guildSettings.delete_command_messages then message:delete() end
	end
end

return commandHandler