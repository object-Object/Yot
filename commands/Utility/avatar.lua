local commandHandler = require("commandHandler")

return {
	name = "avatar",
	description = "Show a user's avatar in full size.",
	usage = "avatar <ping> [ping 2] [ping 3 ...]",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if not message.mentionedUsers.first then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local output=""
		for user in message.mentionedUsers:iter() do
			output=output..user.tag..": "..user:getAvatarURL(1024).."\n"
		end
		message:reply(output)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}