local utils = require("miscUtils")

return {
	name = "ban-messages",
	visible = true,
	disabledByDefault = true,
	run = function(self, guildSettings, lang, user, guild, conn)
		local publicLogChannel = guildSettings.public_log_channel and guild:getChannel(guildSettings.public_log_channel)
		utils.sendEmbedSafe(publicLogChannel, f(lang.logs.user_banned, user.tag), "ffff00")
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}