local suggestionsEmotes = {"👍","🤷","👎"}

return {
	name = "suggestions-channel",
	description = "Add voting reactions to messages sent in the server's suggestions channel, if set.",
	visible = false,
	event = "client.messageCreate",
	disabledByDefault = false,
	run = function(self, guildSettings, message, conn)
		if not (guildSettings.suggestions_channel and message.channel.id==guildSettings.suggestions_channel) then return end
		for _, emote in ipairs(suggestionsEmotes) do
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