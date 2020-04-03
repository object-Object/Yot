local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")

return {
	name = "mute-manager-join",
	description = "Set is_active to 1 and reset end_timestamp when users with mutes rejoin.",
	visible = false,
	event = "client.memberJoin",
	disabledByDefault = false,
	run = function(self, guildSettings, member, conn)
		local entry, _ = conn:exec('SELECT * FROM mutes WHERE guild_id = "'..member.guild.id..'" AND user_id = "'..member.id..'";')
		if entry then
			local staffLogChannel = guildSettings.staff_log_channel and member.guild:getChannel(guildSettings.staff_log_channel)
			if not guildSettings.muted_role then
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, member.user.tag.."'s mute could not be given back because the `muted_role` setting is not set.", "ff0000")
				end
				return
			end
			local mutedRole = member.guild:getRole(guildSettings.muted_role)
			if not mutedRole then
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, member.user.tag.."'s mute could not be given back because the role set as the `muted_role` setting no longer exists.", "ff0000")
				end
				return
			end
			local selfMember = member.guild:getMember(member.client.user.id)
			if not selfMember:hasPermission("manageRoles") then
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, member.user.tag.."'s mute could not be given back because Yotogi does not have the `manageRoles` permission.", "ff0000")
				end
			elseif selfMember.highestRole.position<=mutedRole.position then
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, member.user.tag.."'s mute could not be given back because Yotogi's highest role is not higher than the role set as the `muted_role` setting.", "ff0000")
				end
			else
				entry = utils.formatRow(entry)
				entry.is_active = true
				entry.end_timestamp = os.time()+entry.duration
				conn:exec('UPDATE mutes SET is_active = 1, end_timestamp = '..entry.end_timestamp..' WHERE guild_id = "'..member.guild.id..'" AND user_id = "'..member.id..'";')
				local muteFooter = commandHandler.strings.muteFooter(guildSettings, entry)
				utils.sendEmbed(member:getPrivateChannel(), "Your mute has been given back in **"..member.guild.name.."**.", "00ff00", muteFooter)
				local publicLogChannel = guildSettings.public_log_channel and member.guild:getChannel(guildSettings.public_log_channel)
				if publicLogChannel then
					utils.sendEmbed(publicLogChannel, member.user.tag.."'s mute has been given back.", "00ff00", muteFooter)
				end
				if staffLogChannel then
					utils.sendEmbed(staffLogChannel, member.user.tag.."'s mute has been given back.", "00ff00", muteFooter)
				end
				member:addRole(mutedRole.id)
			end
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}