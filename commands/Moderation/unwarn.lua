local commandHandler = require("commandHandler")
local utils = require("miscUtils")
local warnUtils = require("warnUtils")

return {
	name = "unwarn",
	visible = true,
	permissions = {"kickMembers", "banMembers"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end

		local warnUser = utils.userFromString(args[1], message.client)
		if not warnUser then
			utils.sendEmbed(message.channel, f(lang.error.user_not_found, args[1]), "ff0000")
			return
		end
		local warnMember = utils.memberFromString(args[1], message.guild)
		local name = utils.name(warnUser, message.guild)

		local unwarnSuccess, unwarnErr, entry = warnUtils.unwarn(warnUser, message.guild, guildSettings, lang, conn)
		if not unwarnSuccess then
			utils.sendEmbed(message.channel, f(lang.error.unwarn_fail, name, unwarnErr), "ff0000")
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and f(lang.g.reason_str, reason) or ""

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		local warnFooter = commandHandler.strings.warnFooter(guildSettings, lang, entry)

		utils.sendEmbed(warnUser:getPrivateChannel(), f(lang.pl(lang.warn.you_unwarned, entry.level), message.guild.name, entry.level)..reason, "00ff00", warnFooter)
		local text = f(lang.pl(lang.warn.user_unwarned, entry.level), name, entry.level)..reason
		utils.sendEmbed(message.channel, text, "00ff00", warnFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "00ff00", f(lang.g.responsible_user_str, utils.name(message.author, message.guild)).."\n"..warnFooter)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}