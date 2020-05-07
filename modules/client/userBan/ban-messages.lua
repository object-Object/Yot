local utils = require("miscUtils")

return {
	name = "ban-messages",
	description = "Send messages in the public log channel when a user is banned.",
	visible = true,
	disabledByDefault = true,
	run = function(self, guildSettings, lang, user, guild, conn)
		local publicLogChannel = guildSettings.public_log_channel and guild:getChannel(guildSettings.public_log_channel)
		utils.sendEmbedSafe(publicLogChannel, user.tag.." has been banned from this server.", "ffff00")
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}