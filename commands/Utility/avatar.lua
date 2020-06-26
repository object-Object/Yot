<<<<<<< HEAD:commands/Utility/avatar.lua
local commandHandler = require("commandHandler")
=======
local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")
>>>>>>> fix/avatar-command:commands/avatar.lua

return {
	name = "avatar",
	description = "Show a user's avatar in full size.",
	usage = "avatar <user ID or ping>",
	visible = true,
	permissions = {},
<<<<<<< HEAD:commands/Utility/avatar.lua
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if not message.mentionedUsers.first then
			commandHandler.sendUsage(message.channel, guildSettings, self)
=======
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
>>>>>>> fix/avatar-command:commands/avatar.lua
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