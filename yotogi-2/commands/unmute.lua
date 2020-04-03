local utils = require("../miscUtils")
local muteUtils = require("../muteUtils")
local commandHandler = require("../commandHandler")

return {
	name = "unmute",
	description = "Unmute a user.",
	usage = "unmute <ping or id> [| reason]",
	visible = true,
	permissions = {"manageRoles"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local muteMember = utils.memberFromString(args[1], message.guild)
		local muteUser = utils.userFromString(args[1], message.client)
		if not muteUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		muteUtils.unmute(muteMember, muteUser, message, guildSettings, conn, reason)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}