local utils = require("../miscUtils")

-- create a new webhook in channel and insert it into the database
local function addWebhook(channel, conn)

end

return {
	name = "move",
	description = "Move a specified message, or number of recent messages, to another channel.",
	usage = "move <message id or link to message or number of messages> <channel mention (e.g. #general) or id>",
	visible = true,
	permissions = {"manageMessages"},
	run = function(self, message, argString, args, guildSettings, conn)
		local selfMember = message.guild:getMember(message.client.user.id)
		if not selfMember:hasPermission("manageWebhooks") then -- should be checking this permission for the channel to which the messages are being moved?
			utils.sendEmbed(message.channel, "The messages could not be moved because Yotogi does not have the `manageWebhooks` permission.", "ff0000")
			return
		end
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}