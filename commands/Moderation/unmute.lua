local utils = require("miscUtils")
local muteUtils = require("muteUtils")
local commandHandler = require("commandHandler")

return {
	name = "unmute",
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

		local valid, reasonInvalid, mutedRole = muteUtils.checkValidMute(muteMember, muteUser, message.guild, guildSettings, lang)
		if not valid then
			utils.sendEmbed(message.channel, f(lang.error.unmute_fail, name, reasonInvalid), "ff0000")
			return
		end
		local isMuted = muteUtils.checkIfMuted(muteMember, muteUser, mutedRole, message.guild, conn)
		if not isMuted then
			utils.sendEmbed(message.channel, f(lang.error.unmute_fail, name, lang.error.not_muted), "ff0000")
			muteUtils.deleteEntry(message.guild, muteUser, conn)
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and f(lang.g.reason_str, reason) or ""

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		local mutedDM = utils.sendEmbed(muteUser:getPrivateChannel(), f(lang.mute.you_unmuted, message.guild.name)..reason, "00ff00")
		local success, err = muteUtils.unmute(muteMember, muteUser, mutedRole, message.guild, conn)
		if not success then
			if mutedDM then mutedDM:delete() end
			utils.sendEmbed(message.channel, f(lang.error.unmute_fail, name, "`"..err.."`").." "..lang.error.report_error, "ff0000")
			return
		end
		utils.sendEmbed(message.channel, f(lang.mute.user_unmuted, name)..reason, "00ff00")
		utils.sendEmbedSafe(staffLogChannel, f(lang.mute.user_unmuted, name)..reason, "00ff00", f(lang.g.responsible_user_str, utils.name(message.author, guild)))
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}