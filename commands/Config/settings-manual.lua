local commandHandler = require("commandHandler")
local moduleHandler = require("moduleHandler")
local discordia = require("discordia")
local utils = require("miscUtils")
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
	muted_role = {
		name = "muted_role",
		description = "The role muted users are given.",
		args = "<role mention (e.g. @Role) or role id>",
		onEnable = function(self, message, argString, guildSettings)
			if argString=="" then
				return false, "Role not found in message."
			else
				local role = utils.roleFromString(argString, message.guild)
				if role then
					local selfMember = message.guild:getMember(message.client.user.id)
					if selfMember.highestRole.position<=role.position then
						return false, "Yot's highest role is not above the chosen role."
					end
					return role.id, "Muted users will now be given the role "..role.mentionString..". Note: this does **not** apply retroactively."
				else
					return false, "Role `"..argString.."` not found."
				end
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if not guildSettings[self.name] then
				return false, "Already disabled."
			end
			return nil, "Commands related to muting users will not function until `muted_role` is set."
		end
	},
	advertising_allowed_role = {
		name = "advertising_allowed_role",
		description = "The role that the anti-advertising modules will ignore.",
		args = "<role mention (e.g. @Role) or role id>",
		onEnable = function(self, message, argString, guildSettings)
			if argString=="" then
				return false, "Role not found in message."
			else
				local role = utils.roleFromString(argString, message.guild)
				if role then
					return role.id, "Users with the role "..role.mentionString.." will now be ignored by the anti-advertising modules."
				else
					return false, "Role `"..argString.."` not found."
				end
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if not guildSettings[self.name] then
				return false, "Already disabled."
			end
			return nil, "All users will now be affected by the anti-advertising modules."
		end
	},
	delete_command_messages = {
		name = "delete_command_messages",
		description = "Whether or not command messages should be deleted.",
		args = "None",
		onEnable = function(self, message, argString, guildSettings)
			if guildSettings[self.name] then
				return false, "Already enabled."
			elseif not message.guild:getMember(message.client.user.id):hasPermission("manageMessages") then
				return false, "Yot does not have the `manageMessages` permission."
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
	warning_kick_level = {
		name = "warning_kick_level",
		description = "Users will be kicked from the server when they reach this amount of warnings.",
		args = "<number of warnings>",
		onEnable = function(self, message, argString, guildSettings)
			local numWarnings = argString:match("^(%-?%d+)$")
			numWarnings = numWarnings and tonumber(numWarnings)
			if not numWarnings then
				return false, "Number of warnings not found in message."
			elseif numWarnings<=0 then
				return false, "Number of warnings must be above 0."
			else
				return numWarnings, "Users will now be kicked from the server when they reach "..numWarnings.." warnings."
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if guildSettings[self.name]==-1 then
				return false, "Already disabled."
			end
			return -1, "Users will no longer be kicked from the server for reaching a certain amount of warnings."
		end
	},
	warning_ban_level = {
		name = "warning_ban_level",
		description = "Users will be banned from the server when they reach this amount of warnings.",
		args = "<number of warnings>",
		onEnable = function(self, message, argString, guildSettings)
			local numWarnings = argString:match("^(%-?%d+)$")
			numWarnings = numWarnings and tonumber(numWarnings)
			if not numWarnings then
				return false, "Number of warnings not found in message."
			elseif numWarnings<=0 then
				return false, "Number of warnings must be above 0."
			else
				return numWarnings, "Users will now be banned from the server when they reach "..numWarnings.." warnings."
			end
		end,
		onDisable = function(self, message, argString, guildSettings)
			if guildSettings[self.name]==-1 then
				return false, "Already disabled."
			end
			return -1, "Users will no longer be banned from the server for reaching a certain amount of warnings."
		end
	},
	default_mute_length = {
		name = "default_mute_length",
		description = "The default amount of time before a mute is removed.",
		args = "<number of warnings>",
		onEnable = function(self, message, argString, guildSettings)
			
		end,
		onDisable = function(self, message, argString, guildSettings)
			if guildSettings[self.name]==-1 then
				return false, "Already disabled."
			end
			return -1, "Mutes will no longer be automatically removed."
		end
	},
}
local sortedColumnNames = table.keys(dbSettingsColumns)
table.sort(sortedColumnNames)

local function showSettings(message, guildSettings)
	local output = "```\n"
	for _, columnString in pairs(sortedColumnNames) do
		column = dbSettingsColumns[columnString]
		output = output..columnString.." - "..(guildSettings[columnString] and tostring(guildSettings[columnString]) or "disabled").."\n"
	end
	output = output:gsub("\n$","").."```"
	message.channel:send{
		embed = {
			title = "Settings (Manual)",
			description = output,
			color = discordia.Color.fromHex("00ff00").value,
			footer = {
				text = "Do "..guildSettings.prefix.."settings-manual [setting] for more info on a setting."
			}
		}
	}
end

local function showModules(message, guildSettings)
	local output = "```\n"
	for _, modString in ipairs(moduleHandler.sortedModuleNames) do
		local mod = moduleHandler.modules[modString]
		if mod.visible then
			output = output..modString.." - "..(guildSettings.disabled_modules[modString] and "DISABLED" or "enabled").."\n"
		end
	end
	output = output:gsub("\n$","").."```"
	message.channel:send{
		embed = {
			title = "Module list",
			description = output,
			color = discordia.Color.fromHex("00ff00").value,
			footer = {
				text = "Modules are case sensitive."
			}
		}
	}
end

local settings = {
	name = "settings-manual",
	description = "**You should probably be using `&prefix;settings` instead! This command will receive no updates or internationalization, and may be removed without notice!** The old command for changing Yot's per-server settings. Lists togglable settings or shows information about a setting when used without subcommands.",
	usage = "settings-manual [setting]",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
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
							{name = "Arguments for enabling", value = "`"..column.args.."`"},
							{name = "Value", value = "`"..(guildSettings[columnString] and tostring(guildSettings[columnString]) or "disabled").."`"}
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
	name = "settings-manual enable",
	description = "Enable a setting. This is a semi-alias for `&prefix;settings-manual update`. May have arguments, depending on the setting being enabled. Do `&prefix;settings-manual [setting]` to see arguments for a setting.",
	usage = "settings-manual enable <setting> [arguments]",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
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

settings.subcommands.update = {
	name = "settings-manual update",
	description = "Update the value of a setting. This is a semi-alias for `&prefix;settings enable`. May have arguments, depending on the setting being updated. Do `&prefix;settings [setting]` to see arguments for a setting.",
	usage = "settings-manual update <setting> [arguments]",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local column = dbSettingsColumns[args[1]]
		if not column then
			utils.sendEmbed(message.channel, "Setting `"..args[1].."` not found.", "ff0000")
			return
		end
		if column.args=="None" then
			utils.sendEmbed(message.channel, "`"..column.name.."` can only be enabled or disabled, not updated.", "ff0000")
			return
		end
		local value, text = column:onEnable(message, argString:gsub("^%S+%s+",""), guildSettings)
		if value==false then
			utils.sendEmbed(message.channel, "Value of `"..column.name.."` could not be updated: "..text, "ff0000")
			return
		end
		local stmt = conn:prepare("UPDATE guild_settings SET "..column.name.." = ? WHERE guild_id = ?;")
		stmt:reset():bind(value, message.guild.id):step()
		stmt:close()
		utils.sendEmbed(message.channel, "Value of `"..column.name.."` successfully updated. "..text, "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.disable = {
	name = "settings-manual disable",
	description = "Disable a setting.",
	usage = "settings-manual disable <setting>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
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
	name = "settings-manual commands",
	description = "List all commands, whether they are enabled or disabled, and whether their permissions have been modified or not.",
	usage = "settings-manual commands",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local fields = {}
		for _, categoryString in ipairs(commandHandler.sortedCategoryNames) do
			local category = commandHandler.sortedCommandNames[categoryString]
			if not categoryString:match("^%.") then
				local output = "```\n"
				for _, commandString in ipairs(category) do
					local command = commandHandler.commands[commandString]
					if command.visible then
						output = output..guildSettings.prefix..commandString.." - "..(guildSettings.disabled_commands[commandString] and "DISABLED" or "enabled").." - "..(guildSettings.command_permissions[commandString] and "MODIFIED perms" or "default perms").."\n"
					end
				end
				if output~="```\n" then
					output = output:gsub("\n$","").."```"
					table.insert(fields, {name = categoryString, value = output})
				end
			end
		end
		message.channel:send{
			embed = {
				title = "Command list",
				fields = fields,
				color = discordia.Color.fromHex("00ff00").value
			}
		}
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.enable = {
	name = "settings-manual commands enable",
	description = "Enable a disabled command.",
	usage = "settings-manual commands enable <command>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
		local command = commandHandler.commands[commandString]
		if not (command and command.visible) then
			utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
			return
		elseif not guildSettings.disabled_commands[commandString] then
			utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is already enabled.", "ff0000")
			return
		end
		if not commandHandler.enable(commandString, message, guildSettings, conn) then return end
		utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is now enabled.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.disable = {
	name = "settings-manual commands disable",
	description = "Disable a command.",
	usage = "settings-manual commands disable <command>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
		local command = commandHandler.commands[commandString]
		if not (command and command.visible) then
			utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
			return
		elseif guildSettings.disabled_commands[commandString] then
			utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is already disabled.", "ff0000")
			return
		end
		if not commandHandler.disable(commandString, message, guildSettings, conn) then return end
		utils.sendEmbed(message.channel, "`"..guildSettings.prefix..commandString.."` is now disabled.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.permissions = {
	name = "settings-manual commands permissions",
	description = "Set the permissions required to use a command. Enter just the command to make the command usable by everyone. To view the permissions currently required for a command, use the `&prefix;help` command.",
	usage = "settings-manual commands permissions <command> [permission1 permission2 permission3 ...]",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
		local command = commandHandler.commands[commandString]
		if not (command and command.visible) then
			utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
			return
		end
		local newPermissions = {}
		for i=2, #args do
			local permission = args[i]
			if not discordia.enums.permission[permission] then
				utils.sendEmbed(message.channel, "`"..permission.."` is not a valid permission.", "ff0000")
				return
			end
			table.insert(newPermissions, permission)
		end
		guildSettings.command_permissions[commandString] = newPermissions
		local command_permissions = json.encode(guildSettings.command_permissions)
		conn:exec("UPDATE guild_settings SET command_permissions = '"..command_permissions.."' WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, "Updated permissions of `"..guildSettings.prefix..commandString.."`.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.commands.subcommands.permissions.subcommands.list = {
	name = "settings-manual commands permissions list",
	description = "List all permissions you can assign to commands.",
	usage = "settings-manual commands permissions list",
	run = function(self, message, argString, args, guildSettings, lang, conn)
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
	name = "settings-manual commands reset",
	description = "Reset a command to its default state. This will enable the command if disabled and set the command permissions back to default.",
	usage = "settings-manual commands reset <command>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local commandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
		local command = commandHandler.commands[commandString]
		if not (command and command.visible) then
			utils.sendEmbed(message.channel, "Command `"..guildSettings.prefix..commandString.."` not found.", "ff0000")
			return
		end
		guildSettings.command_permissions[commandString] = nil
		guildSettings.disabled_commands[commandString] = nil
		local command_permissions = json.encode(guildSettings.command_permissions)
		local disabled_commands = json.encode(guildSettings.disabled_commands)
		conn:exec("UPDATE guild_settings SET command_permissions = '"..command_permissions.."', disabled_commands = '"..disabled_commands.."' WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, "Successfully reset `"..guildSettings.prefix..commandString.."`.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.modules = {
	name = "settings-manual modules",
	description = "List all modules and whether they are enabled or disabled, or show information about a module.",
	usage = "settings-manual modules [module]",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			showModules(message, guildSettings)
		else
			local mod = moduleHandler.modules[argString]
			if (mod and mod.visible) then
				message.channel:send{
					embed = {
						title = mod.name,
						description = mod.description,
						fields = {
							{name = "Event", value = "`"..mod.event.."`"},
							{name = "Enabled", value = (guildSettings.disabled_modules[mod.name] and "no" or "yes")}
						},
						color = discordia.Color.fromHex("00ff00").value
					}
				}
			else
				showModules(message, guildSettings)
			end
		end
	end,
	subcommands = {}
}

settings.subcommands.modules.subcommands.enable = {
	name = "settings-manual modules enable",
	description = "Enable a disabled module.",
	usage = "settings-manual modules enable <module>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local mod = moduleHandler.modules[argString]
		if not (mod and mod.visible) then
			utils.sendEmbed(message.channel, "Module `"..argString.."` not found.", "ff0000")
			return
		elseif not guildSettings.disabled_modules[mod.name] then
			utils.sendEmbed(message.channel, "`"..mod.name.."` is already enabled.", "ff0000")
			return
		end
		if not moduleHandler.enable(mod.name, message, guildSettings, conn) then return end
		utils.sendEmbed(message.channel, "`"..mod.name.."` is now enabled.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.modules.subcommands.disable = {
	name = "settings-manual modules disable",
	description = "Disable an enabled module.",
	usage = "settings-manual modules disable <module>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local mod = moduleHandler.modules[argString]
		if not (mod and mod.visible) then
			utils.sendEmbed(message.channel, "Module `"..argString.."` not found.", "ff0000")
			return
		elseif guildSettings.disabled_modules[mod.name] then
			utils.sendEmbed(message.channel, "`"..mod.name.."` is already disabled.", "ff0000")
			return
		end
		if not moduleHandler.disable(mod.name, message, guildSettings, conn) then return end
		utils.sendEmbed(message.channel, "`"..mod.name.."` is now disabled.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.persistentroles = {
	name = "settings-manual persistentroles",
	description = "List all persistent roles. Persistent roles are roles that will be given back to users if they leave while having them. This is different from the muted role, which is handled separately and should not be added as a persistent role.",
	usage = "settings-manual persistentroles",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local output = "``` \n"
		for roleId, _ in pairs(guildSettings.persistent_roles) do
			local role = guild:getRole(roleId)
			if role then
				output = output..role.name.." ("..roleId..")\n"
			end
		end
		output = output:gsub("\n$","").."```"
		message.channel:send{
			embed = {
				title = "Persistent roles",
				description = output,
				color = discordia.Color.fromHex("00ff00").value
			}
		}
	end,
	subcommands = {}
}

settings.subcommands.persistentroles.subcommands.add = {
	name = "settings-manual persistentroles add",
	description = "Add a persistent role by id or role mention.",
	usage = "settings-manual persistentroles add <role mention (e.g. @Role) or role id>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local role = utils.roleFromString(argString, message.guild)
		local selfMember = message.guild:getMember(message.client.user.id)
		if not role then
			utils.sendEmbed(message.channel, "Role `"..argString.."` not found.", "ff0000")
			return
		elseif guildSettings.persistent_roles[role.id] then
			utils.sendEmbed(message.channel, role.mentionString.." is already persistent.", "ff0000")
			return
		elseif selfMember.highestRole.position<=role.position then
			utils.sendEmbed(message.channel, role.mentionString.." could not be made persistent because Yot's highest role is not above it.", "ff0000")
			return
		end
		guildSettings.persistent_roles[role.id] = true
		local persistent_roles = json.encode(guildSettings.persistent_roles)
		conn:exec("UPDATE guild_settings SET persistent_roles = '"..persistent_roles.."' WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, role.mentionString.." is now persistent.", "00ff00")
	end,
	subcommands = {}
}

settings.subcommands.persistentroles.subcommands.remove = {
	name = "settings-manual persistentroles remove",
	description = "Remove a persistent role by id or role mention.",
	usage = "settings-manual persistentroles remove <role mention (e.g. @Role) or role id>",
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local role = utils.roleFromString(argString, message.guild)
		if not role then
			utils.sendEmbed(message.channel, "Role `"..argString.."` not found.", "ff0000")
			return
		elseif not guildSettings.persistent_roles[role.id] then
			utils.sendEmbed(message.channel, role.mentionString.." is not persistent.", "ff0000")
			return
		end
		guildSettings.persistent_roles[role.id] = nil
		local persistent_roles = json.encode(guildSettings.persistent_roles)
		conn:exec("UPDATE guild_settings SET persistent_roles = '"..persistent_roles.."' WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, role.mentionString.." is no longer persistent.", "00ff00")
	end,
	subcommands = {}
}

return settings