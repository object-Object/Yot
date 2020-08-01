local utils = require("miscUtils")
local muteUtils = require("muteUtils")
local commandHandler = require("commandHandler")

return {
	name = "mute",
	visible = true,
	permissions = {"manageRoles"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end

		local muteUser = utils.userFromString(args[1], message.client)
		if not muteUser then
			utils.sendEmbed(message.channel, f(lang.error.user_not_found, args[1]), "ff0000")
			return
		end
		local muteMember = utils.memberFromString(args[1], message.guild)
		local name = utils.name(muteUser, message.guild)

		local stringTimes=argString:match(utils.escapePatterns(args[1]).."%s+([^%|]+)") or ""
		local length = utils.secondsFromString(stringTimes, lang)
		length = length>0 and length or guildSettings.default_mute_length

		local valid, reasonInvalid, mutedRole = muteUtils.checkValidMute(muteMember, muteUser, message.guild, guildSettings, lang)
		if not valid then
			utils.sendEmbed(message.channel, f(lang.error.mute_fail, name, reasonInvalid), "ff0000")
			return
		end
		local isMuted = muteUtils.checkIfMuted(muteMember, muteUser, mutedRole, message.guild, conn)
		if isMuted then
			utils.sendEmbed(message.channel, f(lang.error.mute_fail, name, lang.error.already_muted), "ff0000")
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and f(lang.g.reason_str, reason) or ""
		local muteFooter = commandHandler.strings.muteFooter(guildSettings, lang, length, os.time()+length, (muteMember and true))

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		local mutedDM = utils.sendEmbed(muteUser:getPrivateChannel(), f(lang.mute.you_muted, message.guild.name)..reason, "00ff00", muteFooter)
		local success, err = muteUtils.mute(muteMember, muteUser, mutedRole, message.guild, conn, length)
		if not success then
			if mutedDM then mutedDM:delete() end
			utils.sendEmbed(message.channel, f(lang.error.mute_fail, "`"..err.."`")..lang.error.report_error, "ff0000")
			return
		end
		utils.sendEmbed(message.channel, f(lang.mute.user_muted, name)..reason, "00ff00", muteFooter)
		utils.sendEmbedSafe(staffLogChannel, f(lang.mute.user_muted, name)..reason, "00ff00", f(lang.g.responsible_user_str, utils.name(message.author, guild)).."\n"..muteFooter)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}