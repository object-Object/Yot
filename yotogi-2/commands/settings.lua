local commandHandler = require("../commandHandler")
local discordia = require("discordia")
local utils = require("../miscUtils")
local json = require("json")

local settings = {
	name = "settings",
	description = "Change settings for Yotogi in this server. Does nothing without subcommands.",
	usage = "settings",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		commandHandler.sendCommandHelp(message.channel, guildSettings, self.name, self, self.permissions)
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
		if not command:onEnable(message, guildSettings) then return end
		guildSettings.disabled_commands[commandString] = nil
		local encodedSetting = json.encode(guildSettings.disabled_commands)
		local stmt = conn:prepare("UPDATE guild_settings SET disabled_commands = ? WHERE guild_id = ?;")
		stmt:reset():bind(encodedSetting, message.guild.id):step()
		stmt:close()
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
		if not command:onDisable(message, guildSettings) then return end
		guildSettings.disabled_commands[commandString] = true
		local encodedSetting = json.encode(guildSettings.disabled_commands)
		local stmt = conn:prepare("UPDATE guild_settings SET disabled_commands = ? WHERE guild_id = ?;")
		stmt:reset():bind(encodedSetting, message.guild.id):step()
		stmt:close()
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