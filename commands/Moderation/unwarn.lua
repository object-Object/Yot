local commandHandler = require("commandHandler")
local utils = require("miscUtils")
local warnUtils = require("warnUtils")

return {
	name = "unwarn",
	description = "Unwarn a user.",
	usage = "unwarn <ping or id> [| reason]",
	visible = true,
	permissions = {"kickMembers","banMembers"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, self)
			return
		end

		local warnUser = utils.userFromString(args[1], message.client)
		if not warnUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local warnMember = utils.memberFromString(args[1], message.guild)
		local name = utils.name(warnUser, message.guild)

		local unwarnSuccess, unwarnErr, entry = warnUtils.unwarn(warnUser, message.guild, guildSettings, conn)
		if not unwarnSuccess then
			utils.sendEmbed(message.channel, name.." could not be unwarned because "..unwarnErr, "ff0000")
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)

		utils.sendEmbed(warnUser:getPrivateChannel(), "You have been unwarned in **"..message.guild.name.."**. You now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
		local text = name.." has been unwarned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason
		utils.sendEmbed(message.channel, text, "00ff00", warnFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "00ff00", "Responsible user: "..utils.name(message.author, message.guild).."\n"..warnFooter)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}