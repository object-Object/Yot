local discordia = require("discordia")
local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")

local function showMainHelp(message, guildSettings)
	local output = "```\n"
	for _, commandString in ipairs(commandHandler.sortedCommandNames) do
		if commandHandler.commands[commandString].visible and not guildSettings.disabled_commands[commandString] then
			output = output..guildSettings.prefix..commandString.."\n"
		end
	end
	output = output:gsub("\n$","").."```"
	message.channel:send{
		embed = {
			title = "Commands",
			description = output,
			color = discordia.Color.fromHex("00ff00").value,
			footer = {
				text = "Do "..guildSettings.prefix.."help [command] for more info on a command."
			}
		}
	}
end

local function showCommandHelp(message, guildSettings, baseCommandString, command, permissions)
	if guildSettings.disabled_commands[baseCommandString] then
		message.channel:send{
			embed = {
				title = guildSettings.prefix..command.name,
				description = guildSettings.prefix..baseCommandString.." is disabled in this server.",
				color = discordia.Color.fromHex("ff0000").value
			}
		}
	else
		local subcommandsKeys = table.keys(command.subcommands)
		local permissionsString = #permissions>0 and "`"..table.concat(permissions, ", ").."`" or "None"
		local subcommandsString = #subcommandsKeys>0 and "`"..table.concat(subcommandsKeys, "`, `").."`" or "None"
		message.channel:send{
			embed = {
				title = guildSettings.prefix..command.name,
				description = command.description,
				fields = {
					{name = "Required permissions", value = permissionsString},
					{name = "Subcommands", value = subcommandsString},
					{name = "Usage", value = "`"..guildSettings.prefix..command.usage.."`"}
				},
				color = discordia.Color.fromHex("00ff00").value,
				footer = {
					text = commandHandler.strings.usageFooter
				}
			}
		}
	end
end

return {
	name = "help", -- name of the command and what users type to use it
	description = "Show the help menu or info for a command.", -- description for help command
	usage = "help [command]", -- usage for help command and errors
	visible = true, -- whether or not this command shows up in help and is togglable by users
	permissions = {}, -- required permissions to use the command
	run = function(self, message, argString, args, guildSettings, conn) -- function called when the command is used
		if argString=="" then
			-- show normal help menu
			showMainHelp(message, guildSettings)
		else
			-- show command-specific help
			local baseCommandString = commandHandler.stripPrefix(args[1], guildSettings, message.client)
			local command = commandHandler.commands[baseCommandString]
			if command then
				local permissions = guildSettings.command_permissions[baseCommandString] or command.permissions
				if #args>1 then
					local currentCommand = command
					local subcommand
					for i=2, #args do
						subcommand = currentCommand.subcommands[args[i]]
						if subcommand then
							currentCommand = subcommand
						else
							break
						end
					end
					if subcommand then
						showCommandHelp(message, guildSettings, baseCommandString, subcommand, permissions)
					else
						showCommandHelp(message, guildSettings, baseCommandString, currentCommand, permissions)
					end
				else
					showCommandHelp(message, guildSettings, baseCommandString, command, permissions)
				end
			else
				-- command not found
				showMainHelp(message, guildSettings)
			end
		end
	end,
	onEnable = function(self, message, guildSettings) -- function called when this command is enabled, return true if enabling can proceed
		return true
	end,
	onDisable = function(self, message, guildSettings) -- function called when this command is disabled, return true if disabling can proceed
		return true
	end,
	subcommands = {}
}