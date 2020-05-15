return {
	name = "suggestions-channel",
	visible = false,
	disabledByDefault = false,
	run = function(self, guildSettings, lang, message, conn)
		if not (guildSettings.suggestions_channel and message.channel.id==guildSettings.suggestions_channel) then return end
		for _, emote in ipairs(lang.suggestion_emotes) do
			if message then
				message:addReaction(emote)
			else
				break
			end
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}