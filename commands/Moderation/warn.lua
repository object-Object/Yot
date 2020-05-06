local utils = require("miscUtils")
local warnUtils = require("warnUtils")
local commandHandler = require("commandHandler")

return {
	name = "warn",
	description = "Warn a user.",
	usage = "warn <ping or id> [| reason]",
	visible = true,
	permissions = {"kickMembers","banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end

		local warnUser = utils.userFromString(args[1], message.client)
		if not warnUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local warnMember = utils.memberFromString(args[1], message.guild)
		local name = utils.name(warnUser, message.guild)

		local warnSuccess, warnErr, entry, doKick, doBan = warnUtils.warn(warnMember, warnUser, message.guild, guildSettings, conn)
		if not warnSuccess then
			utils.sendEmbed(message.channel, name.." could not be warned because "..warnErr, "ff0000")
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		if doKick then
			local kickValid, kickErr = warnUtils.checkValidKick(warnMember, message.guild)
			if kickValid then
				local kickedDM = utils.sendEmbed(warnUser:getPrivateChannel(), "You have been kicked from **"..message.guild.name.."** for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
				local success, err = warnMember:kick()
				if not success then
					-- kick failed, so continue with normal warn messages
					if kickedDM then kickedDM:delete() end
					utils.sendEmbed(message.channel, name.." could not be kicked for reaching "..entry.level.." warning"..utils.s(entry.level)..": `"..err.."`. Please report this error to the bot developer by sending Yot a direct message.", "ff0000")
				else
					-- kick succeeded, exit early
					local text = name.." has been kicked for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason
					utils.sendEmbed(message.channel, text, "00ff00")
					utils.sendEmbedSafe(staffLogChannel, text, "00ff00", "Responsible user: "..utils.name(message.author, message.guild))
					return
				end
			else
				-- kick invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, name.." could not be kicked for reaching "..entry.level.." warning"..utils.s(entry.level).." because "..kickErr, "ff0000")
			end
		elseif doBan then
			local banValid, banErr = warnUtils.checkValidBan(warnMember, message.guild)
			if banValid then
				local bannedDM = utils.sendEmbed(warnUser:getPrivateChannel(), "You have been banned from **"..message.guild.name.."** for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
				local success, err = message.guild:banUser(warnUser.id)
				if not success then
					-- ban failed, so continue with normal warn messages
					if bannedDM then bannedDM:delete() end
					utils.sendEmbed(message.channel, name.." could not be banned for reaching "..entry.level.." warning"..utils.s(entry.level)..": `"..err.."`. Please report this error to the bot developer by sending Yot a direct message.", "ff0000")
				else
					-- ban succeeded, exit early
					local text = name.." has been banned for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason
					utils.sendEmbed(message.channel, text, "00ff00")
					utils.sendEmbedSafe(staffLogChannel, text, "00ff00", "Responsible user: "..utils.name(message.author, message.guild))
					return
				end
			else
				-- ban invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, name.." could not be banned for reaching "..entry.level.." warning"..utils.s(entry.level).." because "..banErr, "ff0000")
			end
		end

		local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)

		utils.sendEmbed(warnUser:getPrivateChannel(), "You have been warned in **"..message.guild.name.."**. You now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
		local text = name.." has been warned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason
		utils.sendEmbed(message.channel, text, "00ff00", warnFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "00ff00", "Responsible user: "..utils.name(message.author, message.guild).."\n"..warnFooter)
	end,
	onEnable = function(self, message, guildSettings) -- function called when this command is enabled, return true if enabling can proceed
		return true
	end,
	onDisable = function(self, message, guildSettings) -- function called when this command is disabled, return true if disabling can proceed
		return true
	end,
	subcommands = {}
}