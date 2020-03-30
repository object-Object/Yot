local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")

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
		local warnMember = utils.memberFromString(args[1], message.guild)
		local warnUser = utils.userFromString(args[1], message.client)
		if not warnUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local name = warnMember and warnMember.name.."#"..warnUser.discriminator or warnUser.tag
		if warnUser.bot then
			utils.sendEmbed(message.channel, name.." could not be warned because they are a bot.", "ff0000")
			return
		end
		local entry, _ = conn:exec('SELECT * FROM warnings WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
		if entry then
			entry = utils.formatRow(entry)
			entry.level = entry.level+1
			entry.end_timestamp = os.time()+guildSettings.warning_length
			conn:exec("UPDATE warnings SET level = "..entry.level..", end_timestamp = "..entry.end_timestamp..' WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
		else
			entry = {level=1, end_timestamp=os.time()+guildSettings.warning_length, is_active=(warnMember and true or false)}
			conn:exec('INSERT INTO warnings (guild_id, user_id, level, end_timestamp, is_active) VALUES ("'..message.guild.id..'", "'..warnUser.id..'", '..entry.level..', '..entry.end_timestamp..', '..(entry.is_active and 1 or 0)..');')
		end
		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		local selfMember = message.guild:getMember(message.client.user.id)
		if entry.level==guildSettings.warning_kick_level and warnMember then
			if not selfMember:hasPermission("kickMembers") then
				utils.sendEmbed(message.channel, name.." could not be kicked because Yotogi does not have the `banMembers` permission.", "ff0000")
			elseif selfMember.highestRole.position<=warnMember.highestRole.position then
				utils.sendEmbed(message.channel, name.." could not be kicked because Yotogi's highest role is not higher than their highest role.", "ff0000")
			elseif warnUser.id==message.guild.ownerId then
				utils.sendEmbed(message.channel, name.." could not be kicked because they are the server owner.", "ff0000")
			else
				entry.is_active = false
				conn:exec('UPDATE warnings SET is_active = 0 WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
				utils.sendEmbed(message.channel, name.." has been kicked for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
				utils.sendEmbed(warnUser:getPrivateChannel(), "You have been kicked from **"..message.guild.name.."** for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, name.." has been kicked for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00",
						"Responsible user: "..(message.member and message.member.name or message.author.name).."#"..message.user.discriminator)
				end
				warnMember:kick(reason)
				utils.setGame(message.client, conn)
				return
			end
		elseif entry.level==guildSettings.warning_ban_level and warnMember then
			if not selfMember:hasPermission("banMembers") then
				utils.sendEmbed(message.channel, name.." could not be banned because Yotogi does not have the `banMembers` permission.", "ff0000")
			elseif selfMember.highestRole.position<=warnMember.highestRole.position then
				utils.sendEmbed(message.channel, name.." could not be banned because Yotogi's highest role is not higher than their highest role.", "ff0000")
			elseif warnUser.id==message.guild.ownerId then
				utils.sendEmbed(message.channel, name.." could not be banned because they are the server owner.", "ff0000")
			else
				entry.is_active = false
				conn:exec('UPDATE warnings SET is_active = 0 WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
				utils.sendEmbed(message.channel, name.." has been banned for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
				utils.sendEmbed(warnUser:getPrivateChannel(), "You have been banned from **"..message.guild.name.."** for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, name.." has been banned for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00",
						"Responsible user: "..(message.member and message.member.name or message.author.name).."#"..message.user.discriminator)
				end
				warnMember:ban(reason)
				utils.setGame(message.client, conn)
				return
			end
		end
		local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)
		utils.sendEmbed(message.channel, name.." has been warned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
		utils.sendEmbed(warnUser:getPrivateChannel(), "You have been warned in **"..message.guild.name.."**. You now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
		if staffLogChannel then
			utils.sendEmbed(staffLogChannel, name.." has been warned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00",
				"Responsible user: "..(message.member and message.member.name or message.author.name).."#"..message.user.discriminator.."\n"..warnFooter)
		end
		utils.setGame(message.client, conn)
	end,
	onEnable = function(self, message, guildSettings) -- function called when this command is enabled, return true if enabling can proceed
		return true
	end,
	onDisable = function(self, message, guildSettings) -- function called when this command is disabled, return true if disabling can proceed
		return true
	end,
	subcommands = {}
}