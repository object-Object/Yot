local utils = require("../miscUtils")

return {
	name = "members",
	description = "Show how many members are in the server.",
	usage = "members",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		utils.sendEmbed(message.channel, "There are currently **"..#message.guild.members.."** members in the server.", "00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}