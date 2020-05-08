local utils = require("miscUtils")
local discordia = require("discordia")

return {
	name = "message-delete-logger",
	visible = true,
	disabledByDefault = true,
	run = function(self, guildSettings, lang, message, conn)
		if not guildSettings.staff_log_channel then return end
		local staffLogChannel = message.guild:getChannel(guildSettings.staff_log_channel)
		if not staffLogChannel then return end
		if not message.content then return end
		staffLogChannel:send{
			embed = {
				title = lang.g.message_deleted,
				description = "**"..lang.g.content.."**\n"..message.content,
				fields = {
					{name = lang.g.author, value = message.author.mentionString, inline = true},
					{name = lang.g.channel, value = message.channel.mentionString, inline = true}
				},
				color = discordia.Color.fromHex("ff0000").value,
				timestamp = discordia.Date():toISO('T', 'Z')
			}
		}
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}