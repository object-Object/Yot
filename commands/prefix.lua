local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")
local options = require("../options")

return {
	name = "prefix",
	description = "Show or change the command prefix for Yot in this server.",
	usage = "prefix [new prefix (may be in an inline code block)]",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		if argString=="" then
			utils.sendEmbed(message.channel, "Prefix is currently `"..guildSettings.prefix.."`.", "00ff00")
			return
		end
		local newPrefix = argString:gsub("%`(.+)%`","%1")
		local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
		stmt:reset():bind(newPrefix, message.guild.id):step()
		stmt:close()
		utils.sendEmbed(message.channel,"Prefix updated to `"..newPrefix.."`.","00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {

		reset = {
			name = "prefix reset",
			description = "Reset the command prefix for Yot in this server.",
			usage = "prefix reset",
			run = function(self, message, argString, args, guildSettings, conn)
				local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
				stmt:reset():bind(options.defaultPrefix, message.guild.id):step()
				stmt:close()
				utils.sendEmbed(message.channel,"Prefix reset to `"..options.defaultPrefix.."`.","00ff00")
			end,
			subcommands = {}
		}

	}
}