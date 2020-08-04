local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "avatar",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local user = utils.userFromString(args[1], message.client)
		if not user then
			utils.sendEmbed(message.channel, f(lang.error.user_not_found, args[1]), "ff0000")
		else
			message:reply(f(lang.commands.avatar.avatar_of, utils.name(user, message.guild), user:getAvatarURL(1024)))
		end
	end,
	onEnable = function(self, guildSettings, lang, conn)
		return true
	end,
	onDisable = function(self, guildSettings, lang, conn)
		return true
	end,
	subcommands = {}
}