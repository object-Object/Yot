local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")
local warnUtils = require("../warnUtils")

return {
	name = "unwarn",
	description = "Unwarn a user.",
	usage = "unwarn <ping or id> [| reason]",
	visible = true,
	permissions = {"kickMembers","banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local warnMember = utils.memberFromString(args[1], message.guild)
		local warnUser = utils.userFromString(args[1], message.client)
		if not warnUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		warnUtils.unwarn(warnMember, warnUser, message, guildSettings, conn, reason)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}