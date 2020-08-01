local utils = require("miscUtils")
local warnUtils = require("warnUtils")
local commandHandler = require("commandHandler")

return {
	name = "warn",
	visible = true,
	permissions = {"kickMembers","banMembers"},
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

		local warnSuccess, warnErr, entry, doKick, doBan = warnUtils.warn(warnMember, warnUser, message.guild, guildSettings, lang, conn)
		if not warnSuccess then
			utils.sendEmbed(message.channel, f(lang.error.warn_fail, name, warnErr), "ff0000")
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and f(lang.g.reason_str, reason) or ""

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		local responsibleUserStr = f(lang.g.responsible_user_str, utils.name(message.author, message.guild))

		if doKick then
			local kickValid, kickErr = warnUtils.checkValidKick(warnMember, message.guild, lang)
			if kickValid then
				local kickedDM = utils.sendEmbed(warnUser:getPrivateChannel(), f(lang.pl(lang.warn.you_kicked, entry.level), message.guild.name, entry.level)..reason, "00ff00")
				local success, err = warnMember:kick()
				if not success then
					-- kick failed, so continue with normal warn messages
					if kickedDM then kickedDM:delete() end
					utils.sendEmbed(message.channel, f(lang.pl(lang.error.kick_warn_fail, entry.level), name, entry.level, "`"..err.."`").." "..lang.error.report_error, "ff0000")
				else
					-- kick succeeded, exit early
					local text = f(lang.pl(lang.warn.user_kicked, entry.level), name, entry.level)..reason
					utils.sendEmbed(message.channel, text, "00ff00")
					utils.sendEmbedSafe(staffLogChannel, text, "00ff00", responsibleUserStr)
					return
				end
			else
				-- kick invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, f(lang.pl(lang.error.kick_warn_fail, entry.level), name, entry.level, kickErr), "ff0000")
			end
		elseif doBan then
			local banValid, banErr = warnUtils.checkValidBan(warnMember, message.guild, lang)
			if banValid then
				local bannedDM = utils.sendEmbed(warnUser:getPrivateChannel(), f(lang.pl(lang.warn.you_banned, entry.level), message.guild.name, entry.level)..reason, "00ff00")
				local success, err = message.guild:banUser(warnUser.id)
				if not success then
					-- ban failed, so continue with normal warn messages
					if bannedDM then bannedDM:delete() end
					utils.sendEmbed(message.channel, f(lang.pl(lang.error.ban_warn_fail, entry.level), name, entry.level, "`"..err.."`")..lang.error.report_error, "ff0000")
				else
					-- ban succeeded, exit early
					local text = f(lang.pl(lang.warn.user_banned, entry.level), name, entry.level)..reason
					utils.sendEmbed(message.channel, text, "00ff00")
					utils.sendEmbedSafe(staffLogChannel, text, "00ff00", responsibleUserStr)
					return
				end
			else
				-- ban invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, f(lang.pl(lang.error.ban_warn_fail, entry.level), name, entry.level, banErr), "ff0000")
			end
		end

		local warnFooter = commandHandler.strings.warnFooter(guildSettings, lang, entry)

		utils.sendEmbed(warnUser:getPrivateChannel(), f(lang.pl(lang.warn.you_warned, entry.level), message.guild.name, entry.level)..reason, "00ff00", warnFooter)
		local text = f(lang.pl(lang.warn.user_warned, entry.level), name, entry.level)..reason
		utils.sendEmbed(message.channel, text, "00ff00", warnFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "00ff00", responsibleUserStr.."\n"..warnFooter)
	end,
	onEnable = function(self, message, guildSettings) -- function called when this command is enabled, return true if enabling can proceed
		return true
	end,
	onDisable = function(self, message, guildSettings) -- function called when this command is disabled, return true if disabling can proceed
		return true
	end,
	subcommands = {}
}