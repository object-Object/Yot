local commandHandler = require("../commandHandler")
local discordia = require("discordia")
local utils = require("../miscUtils")
local json = require("json")

-- descriptions of all of the settings that can be enabled/disabled with the base settings command
-- onEnable and onDisable return two values: the value that goes into the database, and text to be appended to the confirmation message sent in response to the command
-- if value is false, response is the error message to be sent to the user
-- args explains what to give as arguments when enabling the setting
local dbSettingsColumns = {
	public_log_channel = {
		name = "public_log_channel",
		description = "The public log channel, for things like warnings being automatically decreased and mutes being removed.",
		args = "<channel mention (e.g. #general) or channel id>",
		onEnable = function(self, message, argString, guildSettings)
			if argString=="" then
				return message.channel.id, "Public log messages will now be sent in this channel."
			else
				local channel = utils.channelFromString(argString, message.client)
				if channel then
					return channel.id, "Public log messages will now be sent in "..channel.mentionString.."."
				else
					return false, "Channel `"..argString.."` not found."
				end
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if not guildSettings[self.name] then
				return false, "Already disabled."
			end
			return nil, "Public log messages will no longer be sent."
		end
	},
	staff_log_channel = {
		name = "staff_log_channel",
		description = "The staff log channel, similar to the public log channel but with more information. Also where edited/deleted messages are logged to if enabled.",
		args = "<channel mention (e.g. #general) or channel id>",
		onEnable = function(self, message, argString, guildSettings)
			if argString=="" then
				return message.channel.id, "Staff log messages will now be sent in this channel."
			else
				local channel = utils.channelFromString(argString, message.client)
				if channel then
					return channel.id, "Staff log messages will now be sent in "..channel.mentionString.."."
				else
					return false, "Channel `"..argString.."` not found."
				end
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if not guildSettings[self.name] then
				return false, "Already disabled."
			end
			return nil, "Staff log messages will no longer be sent."
		end
	},
	suggestions_channel = {
		name = "suggestions_channel",
		description = "The suggestions channel, in which all messages will receive the reactions :thumbsup:, :person_shrugging:, and :thumbsdown: to allow people to vote on the suggestions.",
		args = "<channel mention (e.g. #general) or channel id>",
		onEnable = function(self, message, argString, guildSettings)
			if argString=="" then
				return message.channel.id, "Messages sent in this channel will now receive voting reactions."
			else
				local channel = utils.channelFromString(argString, message.client)
				if channel then
					return channel.id, "Messages sent in "..channel.mentionString.." will now receive voting reactions."
				else
					return false, "Channel `"..argString.."` not found."
				end
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if not guildSettings[self.name] then
				return false, "Already disabled."
			end
			return nil, ""
		end
	},
	delete_command_messages = {
		name = "delete_command_messages",
		description = "Whether or not command messages should be deleted.",
		args = "None",
		onEnable = function(self, message, argString, guildSettings)
			if guildSettings[self.name] then
				return false, "Already enabled."
			end
			return 1, "Command messages will now be deleted when a command is used."
		end,
		onDisable = function(self, message, argString, guildSettings)
			if not guildSettings[self.name] then
				return false, "Already disabled."
			end
			return 0, "Command messages will no longer be deleted when a command is used."
		end
	},
}

local function showSettings(message, guildSettings)
	local output = "```\n"
	for columnString, column in pairs(dbSettingsColumns) do
		output = output..columnString.." - "..(guildSettings[columnString] and tostring(guildSettings[columnString]) or "disabled").."\n"
	end
	output = output:gsub("\n$","").."```"
	message.channel:send{
		embed = {
			title = "Settings",
			description = output,
			color = discordia.Color.fromHex("00ff00").value,
			footer = {
				text = "Do "..guildSettings.prefix.."settings [setting] for more info on a setting."
			}
		}
	}
end

local settings = {
	name = "settings",
	description = "The main command for changing Yotogi's per-server settings. Lists togglable settings or shows information about a setting when used without subcommands.",
	usage = "settings [setting]",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		if argString=="" then
			showSettings(message, guildSettings)
		else
			local columnString = args[1]
			local column = dbSettingsColumns[columnString]
			if column then
				message.channel:send{
					embed = {
						title = columnString,
						description = column.description,
						fields = {
							{name = "Arguments for enabling", value = "`"..column.args.."`"}
						},
						color = discordia.Color.fromHex("00ff00").value,
						footer = {
							text = commandHandler.strings.usageFooter
						}
					}
				}
			else
				showSettings(message, guildSettings)
			end
		end
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		utils.sendEmbed(message.channel, "Disabling `"..guildSettings.prefix..self.name.."` is not permitted.", "ff0000")
		return false
	end,
	subcommands = {}
}

settings.subcommands.enable = {
	name = "settings enable",
	description = "Enable a setting. May have arguments, depending on the setting being enabled. Do `&prefix;settings [setting]` to see arguments for a setting.",
	usage = "settings enable [arguments]",
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local column = dbSettingsColumns[args[1]]
		if not column then
			utils.sendEmbed(message.channel, "Setting `"..args[1].."` not found.", "ff0000")
			return
		end
		local value, text = column:onEnable(message, argString:gsub("^%S+%s+",""), guildSettings)
		if value==false then
			utils.sendEmbed(message.channel, "`"..column.name.."` could not be enabled: "..text, "ff0000")
			return
		end
		local stmt = conn:prepare("UPDATE guild_settings SET "..column.name.." = ? WHERE guild_id = ?;")
		stmt:reset():bind(value, message.guild.id):step()
		stmt:close()
		utils.sendEmbed(message.channel, "`"..column.name.."` is now enabled. "..text, "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.disable = {
	name = "settings disable",
	description = "Disable a setting.",
	usage = "settings disable",
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local column = dbSettingsColumns[args[1]]
		if not column then
			utils.sendEmbed(message.channel, "Setting `"..args[1].."` not found.", "ff0000")
			return
		end
		local value, text = column:onDisable(message, argString:gsub("^%S+%s+",""), guildSettings)
		if value==false then
			utils.sendEmbed(message.channel, "`"..column.name.."` could not be disabled: "..text, "ff0000")
			return
		end
		local stmt = conn:prepare("UPDATE guild_settings SET "..column.name.." = ? WHERE guild_id = ?;")
		stmt:reset():bind(value, message.guild.id):step()
		stmt:close()
		utils.sendEmbed(message.channel, "`"..column.name.."` is now disabled. "..text, "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.commands = {
	name = "settings commands",
	description = "List all commands, whether they are enabled or disabled, and whether their permissions have been modified or not.",
	usage = "settings commands",
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		local output = "```\n"
		for _, commandString in ipairs(commandHandler.sortedCommandNames) do
			local command = commandHandler.commands[commandString]
			if command.visible then
				output = output..guildSettings.prefix..commandString.." - "..(guildSettings.disabled_commands[commandString] and "disabled" or "enabled").." - "..(guildSettings.command_permissions[commandString] and "modified perms" or "default perms").."\n"
			end
		end
		output = output:gsub("\n$","").."```"
		message.channel:send{
			embed = {
				title = "Command list",
				description = output,
				color = discordia.Color.fromHex("00ff00").value
			}
		}
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.enable = {
	name = "settings commands enable",
	description = "Enable a disabled command.",
	usage = "settings commands enable <command>",
	run = function(self, message, argString, args, guildSettings, conn)
		local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
		local command = commandHandler.commands[commandString]
		if not (command and command.visible) then
			utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
			return
		elseif not guildSettings.disabled_commands[commandString] then
			utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is already enabled.", "ff0000")
			return
		end
		if not commandHandler.enable(commandString, message.guild.id, guildSettings, conn) then return end
		utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is now enabled.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.disable = {
	name = "settings commands disable",
	description = "Disable a command.",
	usage = "settings commands disable <command>",
	run = function(self, message, argString, args, guildSettings, conn)
		local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
		local command = commandHandler.commands[commandString]
		if not (command and command.visible) then
			utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
			return
		elseif guildSettings.disabled_commands[commandString] then
			utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is already disabled.", "ff0000")
			return
		end
		if not commandHandler.disable(commandString, message.guild.id, guildSettings, conn) then return end
		utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is now disabled.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.permissions = {
	name = "settings commands permissions",
	description = "Set the permissions required to use a command. To view the permissions currently required for a command, use the `&prefix;help` command.",
	usage = "settings commands permissions <command> <permission1> [permission2 permission3 ...]",
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end

	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.permissions.subcommands.list = {
	name = "settings commands permissions list",
	description = "List all permissions you can assign to commands.",
	usage = "settings commands permissions list",
	run = function(self, message, argString, args, guildSettings, conn)
		local output = "```\n"
		for _, permission in ipairs(commandHandler.sortedPermissionNames) do
			output = output..permission.."\n"
		end
		output = output:gsub("\n$","").."```"
		message.channel:send{
			embed = {
				title = "Permissions",
				description = output,
				color = discordia.Color.fromHex("00ff00").value
			}
		}
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.reset = {
	name = "settings commands reset",
	description = "Reset a command to its default state.",
	usage = "settings commands reset <command>",
	run = function(self, message, argString, args, guildSettings, conn)
		
	end,
	subcommands = {}
}

return settings