local utils = require("../miscUtils")
local discordia = require("discordia")

return {
	name = "message-edit-logger",
	description = "Logs edited messages in the staff log channel.",
	visible = true,
	event = "client.messageUpdate",
	disabledByDefault = true,
	run = function(self, guildSettings, message, conn)
		if not guildSettings.staff_log_channel then return end
		local staffLogChannel = message.guild:getChannel(guildSettings.staff_log_channel)
		if not staffLogChannel then return end
		if not message.oldContent then return end
		local oldContent = message.oldContent[message.editedTimestamp]
		local newContent = message.content
		if #oldContent>1024 then
			oldContent=oldContent:sub(1,1020).."..."
		end
		if #newContent>1024 then
			newContent=newContent:sub(1,1020).."..."
		end
		staffLogChannel:send{
			embed = {
				title = "Message edited",
				fields = {
					{name = "Old content", value = oldContent},
					{name = "New content", value = newContent},
					{name = "Author", value = message.author.mentionString, inline = true},
					{name = "Channel", value = message.channel.mentionString, inline = true}
				},
				color = discordia.Color.fromHex("ffff00").value,
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