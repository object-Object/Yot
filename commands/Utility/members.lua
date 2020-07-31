local utils = require("miscUtils")

return {
	name = "members",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		utils.sendEmbed(message.channel, f(lang.pl(lang.commands.members.num, #message.guild.members), #message.guild.members), "00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}