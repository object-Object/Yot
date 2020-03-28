local discordia = require("discordia")
local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")

local function appendSubcommands(str, indent, command)
	for subcommandString, subcommand in pairs(command.subcommands) do
		str = str..indent..subcommandString.."\n"
		str = appendSubcommands(str, indent.."  ", subcommand)
	end
	return str
end

local function showMainHelp(message, guildSettings, showSubcommands)
	local output = "```\n"
	for _, commandString in ipairs(commandHandler.sortedCommandNames) do
		local command = commandHandler.commands[commandString]
		if command.visible and not guildSettings.disabled_commands[commandString] then
			output = output..guildSettings.prefix..commandString.."\n"
			if showSubcommands then
				output = appendSubcommands(output, "  ", command)
			end
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

return {
	name = "help", -- name of the command and what users type to use it
	description = "Show the help menu or info for a command.", -- description for help command
	usage = "help [command]", -- usage for help command and errors
	visible = true, -- whether or not this command shows up in help and is togglable by users
	permissions = {}, -- required permissions to use the command
	run = function(self, message, argString, args, guildSettings, conn) -- function called when the command is used
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		if argString=="" then
			-- show normal help menu
			showMainHelp(message, guildSettings, false)
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
						commandHandler.sendCommandHelp(message.channel, guildSettings, baseCommandString, subcommand, permissions)
					else
						commandHandler.sendCommandHelp(message.channel, guildSettings, baseCommandString, currentCommand, permissions)
					end
				else
					commandHandler.sendCommandHelp(message.channel, guildSettings, baseCommandString, command, permissions)
				end
			else
				-- command not found
				showMainHelp(message, guildSettings, false)
			end
		end
	end,
	onEnable = function(self, message, guildSettings) -- function called when this command is enabled, return true if enabling can proceed
		return true
	end,
	onDisable = function(self, message, guildSettings) -- function called when this command is disabled, return true if disabling can proceed
		return true
	end,
	subcommands = {

		subcommands = {
			name = "help subcommands",
			description = "Show the help menu with the subcommands for each command listed.",
			usage = "help subcommands",
			run = function(self, message, argString, args, guildSettings, conn)
				showMainHelp(message, guildSettings, true)
			end,
			subcommands = {}
		}

	}
}