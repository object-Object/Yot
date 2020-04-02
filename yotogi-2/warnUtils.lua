local utils = require("./miscUtils")
local commandHandler = require("./commandHandler")

local warnUtils = {}

warnUtils.warn = function(warnMember, warnUser, message, guildSettings, conn, reason, staffMember)
	reason = reason or ""
	staffMember = staffMember or message.guild:getMember(message.author.id)
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
	local selfMember = message.guild:getMember(message.client.user.id)
	if entry.level==guildSettings.warning_kick_level and warnMember then
		if not selfMember:hasPermission("kickMembers") then
			utils.sendEmbed(message.channel, name.." could not be kicked because Yotogi does not have the `kickMembers` permission.", "ff0000")
		elseif selfMember.highestRole.position<=warnMember.highestRole.position then
			utils.sendEmbed(message.channel, name.." could not be kicked because Yotogi's highest role is not higher than their highest role.", "ff0000")
		elseif warnUser.id==message.guild.ownerId then
			utils.sendEmbed(message.channel, name.." could not be kicked because they are the server owner.", "ff0000")
		else
			utils.sendEmbed(message.channel, name.." has been kicked for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
			utils.sendEmbed(warnUser:getPrivateChannel(), "You have been kicked from **"..message.guild.name.."** for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
			if staffLogChannel then
				utils.sendEmbed(staffLogChannel, name.." has been kicked for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
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
			utils.sendEmbed(message.channel, name.." has been banned for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
			utils.sendEmbed(warnUser:getPrivateChannel(), "You have been banned from **"..message.guild.name.."** for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00")
			if staffLogChannel then
				utils.sendEmbed(staffLogChannel, name.." has been banned for reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
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
		utils.sendEmbed(staffLogChannel, name.." has been warned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator.."\n"..warnFooter)
	end
	utils.setGame(message.client, conn)
end

warnUtils.unwarn = function(warnMember, warnUser, message, guildSettings, conn, reason, staffMember)
	reason = reason or ""
	staffMember = staffMember or message.guild:getMember(message.author.id)
	local name = warnMember and warnMember.name.."#"..warnUser.discriminator or warnUser.tag
	if warnUser.bot then
		utils.sendEmbed(message.channel, name.." could not be unwarned because they are a bot.", "ff0000")
		return
	end
	local entry, _ = conn:exec('SELECT * FROM warnings WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
	if not entry then
		utils.sendEmbed(message.channel, name.." could not be unwarned because they don't have any warnings.", "ff0000")
		return
	end
	entry = utils.formatRow(entry)
	entry.level = entry.level-1
	if entry.level==0 then
		entry.end_timestamp = 0
		conn:exec('DELETE FROM warnings WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
	else
		entry.end_timestamp = os.time()+guildSettings.warning_length
		conn:exec("UPDATE warnings SET level = "..entry.level..", end_timestamp = "..entry.end_timestamp..' WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..warnUser.id..'";')
	end
	local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
	local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)
	utils.sendEmbed(message.channel, name.." has been unwarned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
	utils.sendEmbed(warnUser:getPrivateChannel(), "You have been unwarned in **"..message.guild.name.."**. You now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
	if staffLogChannel then
		utils.sendEmbed(staffLogChannel, name.." has been unwarned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator.."\n"..warnFooter)
	end
	utils.setGame(message.client, conn)
end

return warnUtils