local utils = require("miscUtils")

return {
	name = "leave-messages",
	description = "Sends a message in the public log channel when a user leaves the server.",
	visible = true,
	event = "client.memberLeave",
	disabledByDefault = true,
	run = function(self, guildSettings, lang, member, conn)
		local channel = guildSettings.public_log_channel and member.guild:getChannel(guildSettings.public_log_channel)
		utils.sendEmbedSafe(channel, member.tag.." has left the server.", "ffff00")
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}