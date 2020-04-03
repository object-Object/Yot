local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")
local moduleHandler = require("../moduleHandler")
local options = require("../options")

return {
	name = "mute-manager",
	description = "Runs once per minute to remove any active mutes that have expired.",
	visible = true,
	event = "clock.min",
	disabledByDefault = false,
	run = function(self, guildSettings, guild, conn)
		local mutes, nrow = conn:exec("SELECT * FROM mutes WHERE is_active = 1 AND end_timestamp <= "..os.time().." AND guild_id = '"..guild.id.."';")
		if mutes then
			local deleteStmt = conn:prepare("DELETE FROM mutes WHERE guild_id = ? AND user_id = ?;")
			local fixActiveStmt = conn:prepare("UPDATE mutes SET is_active = 0 WHERE guild_id = ? AND user_id = ?;")
			for row=1, nrow do
				local muteMember = guild:getMember(mutes.user_id[row])
				if not muteMember then
					fixActiveStmt:reset():bind(guild.id, mutes.user_id[row]):step()
				else
					local muteUser = guild.client:getUser(mutes.user_id[row])
					deleteStmt:reset():bind(guild.id, muteUser.id):step()
					local name = muteMember.name.."#"..muteUser.discriminator
					local publicLogChannel = guildSettings.public_log_channel and guild:getChannel(guildSettings.public_log_channel)
					local staffLogChannel = guildSettings.staff_log_channel and guild:getChannel(guildSettings.staff_log_channel)
					if not guildSettings.muted_role then
						if publicLogChannel then
							utils.sendEmbed(publicLogChannel, name.." could not be automatically unmuted because the `muted_role` setting is not set.", "ff0000")
						end
						if staffLogChannel then
							utils.sendEmbed(staffLogChannel, name.." could not be automatically unmuted because the `muted_role` setting is not set.", "ff0000")
						end
					else
						local mutedRole = guild:getRole(guildSettings.muted_role)
						if not mutedRole then
							if publicLogChannel then
								utils.sendEmbed(publicLogChannel, name.." could not be automatically unmuted because the role set as the `muted_role` setting no longer exists.", "ff0000")
							end
							if staffLogChannel then
								utils.sendEmbed(staffLogChannel, name.." could not be automatically unmuted because the role set as the `muted_role` setting no longer exists.", "ff0000")
							end
						else
							if muteMember:hasRole(mutedRole.id) then
								local selfMember = guild:getMember(guild.client.user.id)
								if not selfMember:hasPermission("manageRoles") then
									if publicLogChannel then
										utils.sendEmbed(publicLogChannel, name.." could not be automatically unmuted because Yotogi does not have the `manageRoles` permission.", "ff0000")
									end
									if staffLogChannel then
										utils.sendEmbed(staffLogChannel, name.." could not be automatically unmuted because Yotogi does not have the `manageRoles` permission.", "ff0000")
									end
								elseif selfMember.highestRole.position<=mutedRole.position then
									if publicLogChannel then
										utils.sendEmbed(publicLogChannel, name.." could not be automatically unmuted because Yotogi's highest role is not higher than the role set as the `muted_role` setting.", "ff0000")
									end
									if staffLogChannel then
										utils.sendEmbed(staffLogChannel, name.." could not be automatically unmuted because Yotogi's highest role is not higher than the role set as the `muted_role` setting.", "ff0000")
									end
								else
									utils.sendEmbed(muteUser:getPrivateChannel(), "You have been automatically unmuted in **"..guild.name.."**.", "00ff00")
									if publicLogChannel then
										utils.sendEmbed(publicLogChannel, name.." has been automatically unmuted.", "00ff00", nil, nil, muteUser.mentionString)
									end
									if staffLogChannel then
										utils.sendEmbed(staffLogChannel, name.." has been automatically unmuted.", "00ff00")
									end
									muteMember:removeRole(mutedRole.id)
								end
							end
						end
					end
				end
			end
			deleteStmt:close()
			fixActiveStmt:close()
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		conn:exec("UPDATE guild_settings SET default_mute_length = "..options.defaultMuteLength.." WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, "Mutes will now expire. The `default_mute_length` setting has been set to "..options.defaultMuteLength..".", "00ff00")
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		conn:exec("UPDATE guild_settings SET default_mute_length = 0 WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, "Mutes will no longer expire. The `default_mute_length` setting has been set to 0.", "00ff00")
		return true
	end
}