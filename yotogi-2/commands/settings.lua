local commandHandler = require("../commandHandler")
local discordia = require("discordia")
local utils = require("../miscUtils")
local json = require("json")

return {
	name = "settings",
	description = "Change settings for Yotogi in this server.",
	usage = "settings",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {

		commands = {
			name = "settings commands",
			description = "List all commands and whether they are enabled or disabled.",
			usage = "settings commands",
			run = function(self, message, argString, args, guildSettings, conn)
				if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end

			end,
			subcommands = {

				enable = {
					name = "settings commands enable",
					description = "Enable a disabled command.",
					usage = "settings commands enable <command>",
					run = function(self, message, argString, args, guildSettings, conn)
						local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
						if commandString=="settings" then
							utils.sendEmbed(message.channel, "Enabling/disabling `"..guildSettings.prefix.."settings` is not permitted.", "ff0000")
						elseif commandHandler.commands[commandString] then
							if guildSettings.disabled_commands[commandString] then
								guildSettings.disabled_commands[commandString] = nil
								local encodedSetting = json.encode(guildSettings.disabled_commands)
								local stmt = conn:prepare("UPDATE guild_settings SET disabled_commands = ? WHERE guild_id = ?;")
								stmt:reset():bind(encodedSetting, message.guild.id):step()
								stmt:close()
								utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is now enabled.", "00ff00")
							else
								utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is already enabled.", "ff0000")
							end
						else
							utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
						end
					end,
					subcommands = {}
				},

				disable = {
					name = "settings commands disable",
					description = "Disable a command.",
					usage = "settings commands disable <command>",
					run = function(self, message, argString, args, guildSettings, conn)
						local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
						if commandString=="settings" then
							utils.sendEmbed(message.channel, "Enabling/disabling `"..guildSettings.prefix.."settings` is not permitted.", "ff0000")
						elseif commandHandler.commands[commandString] then
							if not guildSettings.disabled_commands[commandString] then
								guildSettings.disabled_commands[commandString] = true
								local encodedSetting = json.encode(guildSettings.disabled_commands)
								local stmt = conn:prepare("UPDATE guild_settings SET disabled_commands = ? WHERE guild_id = ?;")
								stmt:reset():bind(encodedSetting, message.guild.id):step()
								stmt:close()
								utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is now disabled.", "00ff00")
							else
								utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is already disabled.", "ff0000")
							end
						else
							utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
						end
					end,
					subcommands = {}
				},

				permissions = {
					name = "settings commands permissions",
					description = "Set the permissions required to use a command.",
					usage = "settings commands permissions <command> <permission1> [permission2 permission3 ...]",
					run = function(self, message, argString, args, guildSettings, conn)
						if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end

					end,
					subcommands = {

						list = {
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

					}
				},

				reset = {
					name = "settings commands reset",
					description = "Reset a command to its default state.",
					usage = "settings commands reset <command>",
					run = function(self, message, argString, args, guildSettings, conn)
						
					end,
					subcommands = {}
				}

			}
		},

	}
}