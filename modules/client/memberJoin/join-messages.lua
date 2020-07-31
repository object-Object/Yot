local utils = require("miscUtils")

return {
	name = "join-messages",
	visible = true,
	disabledByDefault = true,
	run = function(self, guildSettings, lang, member, conn)
		local channel = guildSettings.public_log_channel and member.guild:getChannel(guildSettings.public_log_channel)
		utils.sendEmbedSafe(channel, f(lang.modules["join-messages"].default_message, member.tag), "ffff00")
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}