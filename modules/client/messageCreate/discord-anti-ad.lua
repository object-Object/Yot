local warnUtils = require("warnUtils")
local utils = require("miscUtils")
local commandHandler = require("commandHandler")
local timer = require("timer")

local timeout = false

return {
	name = "discord-anti-ad",
	visible = true,
	disabledByDefault = true,
	run = function(self, guildSettings, lang, message, conn)
		local member = message.guild:getMember(message.author.id)
		local name = utils.name(message.author, message.guild)
		local responsibleName = f(lang.g.responsible_user_str, utils.name(message.client.user, message.guild))
		if guildSettings.advertising_allowed_role and member:hasRole(guildSettings.advertising_allowed_role) then
			return
		end
		local code = message.content:match("discord.gg.(%w+)")
		local invite = code and message.client:getInvite(code)
		if not (invite and invite.guildId~=message.guild.id) then return end

		message:delete()

		if timeout then return end
		timeout=true
		timer.setTimeout(1000, function() timeout=false end)

		local warnSuccess, warnErr, entry, doKick, doBan = warnUtils.warn(member, message.author, message.guild, guildSettings, lang, conn)
		if not warnSuccess then
			utils.sendEmbed(message.channel, f(lang.error.auto_warn_fail, name, warnErr), "ff0000")
			return
		end

		local reason = f(lang.g.reason_str, lang.error.advertising_not_allowed)

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		if doKick then
			local kickValid, kickErr = warnUtils.checkValidKick(member, message.guild, lang)
			if kickValid then
				local kickedDM = utils.sendEmbed(message.author:getPrivateChannel(), f(lang.pl(lang.warn.you_kicked_auto, entry.level), message.guild.name, entry.level)..reason, "ffff00")
				local success, err = member:kick()
				if not success then
					-- kick failed, so continue with normal warn messages
					if kickedDM then kickedDM:delete() end
					utils.sendEmbed(message.channel, f(lang.pl(lang.error.kick_auto_warn_fail, entry.level), name, entry.level, "`"..err.."`").." "..lang.error.report_error, "ff0000")
				else
					-- kick succeeded, exit early
					local text = f(lang.pl(lang.warn.user_kicked_auto, entry.level), name, entry.level)..reason
					utils.sendEmbed(message.channel, text, "ffff00")
					utils.sendEmbedSafe(staffLogChannel, text, "ffff00", responsibleName)
					return
				end
			else
				-- kick invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, f(lang.pl(lang.error.kick_auto_warn_fail, entry.level), name, entry.level, kickErr), "ff0000")
			end
		elseif doBan then
			local banValid, banErr = warnUtils.checkValidBan(member, message.guild, lang)
			if banValid then
				local bannedDM = utils.sendEmbed(message.author:getPrivateChannel(), f(lang.pl(lang.warn.you_banned_auto, entry.level), message.guild.name, entry.level)..reason, "ffff00")
				local success, err = message.guild:banUser(message.author.id)
				if not success then
					-- ban failed, so continue with normal warn messages
					if bannedDM then bannedDM:delete() end
					utils.sendEmbed(message.channel, f(lang.pl(lang.error.ban_auto_warn_fail, entry.level), name, entry.level, "`"..err.."`").." "..lang.error.report_error, "ff0000")
				else
					-- ban succeeded, exit early
					local text = f(lang.pl(lang.warn.user_banned_auto, entry.level), name, entry.level)..reason
					utils.sendEmbed(message.channel, text, "ffff00")
					utils.sendEmbedSafe(staffLogChannel, text, "ffff00", responsibleName)
					return
				end
			else
				-- ban invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, f(lang.pl(lang.error.kick_auto_warn_fail, entry.level), name, entry.level, banErr), "ff0000")
			end
		end

		local warnFooter = commandHandler.strings.warnFooter(guildSettings, lang, entry)

		utils.sendEmbed(message.author:getPrivateChannel(), f(lang.pl(lang.warn.you_warned_auto, entry.level), message.guild.name, entry.level)..reason, "ffff00", warnFooter)
		local text = f(lang.pl(lang.warn.user_warned_auto, entry.level), name, entry.level)..reason
		utils.sendEmbed(message.channel, text, "ffff00", warnFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "ffff00", responsibleName.."\n"..warnFooter)
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}