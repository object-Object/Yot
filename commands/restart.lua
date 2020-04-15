local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")

return {
	name = "restart",
	description = "Restart Yot.",
	usage = "restart",
	visible = false,
	permissions = {"yot.botOwner"},
	run = function(self, message, argString, args, guildSettings, conn)
		utils.sendEmbed(message.channel, "Restarting.", "00ff00")
		os.exit()
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}