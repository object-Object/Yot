local utils = require("./miscUtils")
local commandHandler = require("./commandHandler")

local muteUtils = {}

muteUtils.mute = function(muteMember, muteUser, message, guildSettings, conn, length, reason, staffMember)
	length = length or guildSettings.default_mute_length
	reason = reason or ""
	staffMember = staffMember or message.guild:getMember(message.author.id)
	local name = muteMember and muteMember.name.."#"..muteUser.discriminator or muteUser.tag
	if not guildSettings.muted_role then
		utils.sendEmbed(message.channel, name.." could not be muted because the `muted_role` setting is not set.", "ff0000")
		return
	end
	local mutedRole = message.guild:getRole(guildSettings.muted_role)
	if not mutedRole then
		utils.sendEmbed(message.channel, name.." could not be muted because the role set as the `muted_role` setting no longer exists.", "ff0000")
		return
	end
	if muteUser.bot then
		utils.sendEmbed(message.channel, name.." could not be muted because they are a bot.", "ff0000")
		return
	end
	local entry, _ = conn:exec('SELECT * FROM mutes WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..muteUser.id..'";')
	if (not muteMember and entry) or (muteMember and muteMember:hasRole(mutedRole.id)) then
		utils.sendEmbed(message.channel, name.." is already muted.", "ff0000")
		return
	end
	local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
	local selfMember = message.guild:getMember(message.client.user.id)
	if not selfMember:hasPermission("manageRoles") then
		utils.sendEmbed(message.channel, name.." could not be muted because Yotogi does not have the `manageRoles` permission.", "ff0000")
	elseif selfMember.highestRole.position<=mutedRole.position then
		utils.sendEmbed(message.channel, name.." could not be muted because Yotogi's highest role is not higher than the role set as the `muted_role` setting.", "ff0000")
	elseif muteMember and muteMember:hasPermission("administrator") then
		utils.sendEmbed(message.channel, name.." could not be muted because they have the `administrator` permission.", "ff0000")
	else
		if entry then
			conn:exec("DELETE FROM mutes WHERE guild_id = '"..message.guild.id.."' AND user_id = '"..muteUser.id.."';")
		end
		entry = {guild_id=message.guild.id, user_id=muteUser.id, duration=length, end_timestamp=os.time()+length, is_active=(muteMember and true or false)}
		conn:exec('INSERT INTO mutes (guild_id, user_id, duration, end_timestamp, is_active) VALUES ("'..entry.guild_id..'", "'..entry.user_id..'", '..entry.duration..', '..entry.end_timestamp..', '..(entry.is_active and 1 or 0)..');')
		local muteFooter = commandHandler.strings.muteFooter(guildSettings, entry)
		utils.sendEmbed(message.channel, name.." has been muted."..reason, "00ff00", muteFooter)
		utils.sendEmbed(muteUser:getPrivateChannel(), "You have been muted in **"..message.guild.name.."**."..reason, "00ff00", muteFooter)
		if staffLogChannel then
			utils.sendEmbed(staffLogChannel, name.." has been muted."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator.."\n"..muteFooter)
		end
		if muteMember then
			muteMember:addRole(mutedRole.id)
		end
	end
end

muteUtils.unmute = function(muteMember, muteUser, message, guildSettings, conn, reason, staffMember)
	reason = reason or ""
	staffMember = staffMember or message.guild:getMember(message.author.id)
	local name = muteMember and muteMember.name.."#"..muteUser.discriminator or muteUser.tag
	if not guildSettings.muted_role then
		utils.sendEmbed(message.channel, name.." could not be unmuted because the `muted_role` setting is not set.", "ff0000")
		return
	end
	local mutedRole = message.guild:getRole(guildSettings.muted_role)
	if not mutedRole then
		utils.sendEmbed(message.channel, name.." could not be unmuted because the role set as the `muted_role` setting no longer exists.", "ff0000")
		return
	end
	if muteUser.bot then
		utils.sendEmbed(message.channel, name.." could not be unmuted because they are a bot.", "ff0000")
		return
	end
	local entry, _ = conn:exec('SELECT * FROM mutes WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..muteUser.id..'";')
	if (not muteMember and not entry) or (muteMember and not muteMember:hasRole(mutedRole.id)) then
		utils.sendEmbed(message.channel, name.." is not muted.", "ff0000")
		return
	end
	local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
	local selfMember = message.guild:getMember(message.client.user.id)
	if not selfMember:hasPermission("manageRoles") then
		utils.sendEmbed(message.channel, name.." could not be unmuted because Yotogi does not have the `manageRoles` permission.", "ff0000")
	elseif selfMember.highestRole.position<=mutedRole.position then
		utils.sendEmbed(message.channel, name.." could not be unmuted because Yotogi's highest role is not higher than the role set as the `muted_role` setting.", "ff0000")
	elseif muteMember and muteMember:hasPermission("administrator") then
		utils.sendEmbed(message.channel, name.." could not be unmuted because they have the `administrator` permission.", "ff0000")
	else
		if entry then
			conn:exec("DELETE FROM mutes WHERE guild_id = '"..message.guild.id.."' AND user_id = '"..muteUser.id.."';")
		end
		utils.sendEmbed(message.channel, name.." has been unmuted."..reason, "00ff00")
		utils.sendEmbed(muteUser:getPrivateChannel(), "You have been unmuted in **"..message.guild.name.."**."..reason, "00ff00")
		if staffLogChannel then
			utils.sendEmbed(staffLogChannel, name.." has been unmuted."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
		end
		if muteMember then
			muteMember:removeRole(mutedRole.id)
		end
	end
end

return muteUtils