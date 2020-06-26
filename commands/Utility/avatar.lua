local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "avatar",
	description = "Show a user's avatar in full size.",
	usage = "avatar <user ID or ping>",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, self)
			return
		end
		local user = utils.userFromString(args[1], message.client)
		if not user then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
		else
			message:reply("Avatar of **"..utils.name(user, message.guild).."**:\n"..user:getAvatarURL(1024))
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