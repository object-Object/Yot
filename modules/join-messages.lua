local utils = require("../miscUtils")

return {
	name = "join-messages",
	description = "Sends a message in the public log channel when a user joins the server.",
	visible = true,
	event = "client.memberJoin",
	disabledByDefault = true,
	run = function(self, guildSettings, member, conn)
		local channel = guildSettings.public_log_channel and member.guild:getChannel(guildSettings.public_log_channel)
		utils.sendEmbedSafe(channel, member.tag.." has joined the server.", "ffff00")
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}