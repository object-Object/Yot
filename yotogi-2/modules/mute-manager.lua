local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")
local moduleHandler = require("../moduleHandler")
local options = require("../options")
local muteUtils = require("../muteUtils")

return {
	name = "mute-manager",
	description = "Runs once per minute to remove any active mutes that have expired.",
	visible = true,
	event = "clock.min",
	disabledByDefault = false,
	run = function(self, guildSettings, guild, conn)
		local mutes, nrow = conn:exec("SELECT * FROM mutes WHERE is_active = 1 AND end_timestamp <= "..os.time().." AND guild_id = '"..guild.id.."';")
		if not mutes then return end
		for row=1, nrow do
			local muteMember = guild:getMember(mutes.user_id[row])
			if not muteMember then
				conn:exec("UPDATE mutes SET is_active = 0 WHERE guild_id = '"..guild.id.."' AND user_id = '"..mutes.user_id[row].."';")
				goto continue
			end
			local muteUser = muteMember.user
			local name = utils.name(muteUser, guild)

			local publicLogChannel = guildSettings.public_log_channel and guild:getChannel(guildSettings.public_log_channel)
			local staffLogChannel = guildSettings.staff_log_channel and guild:getChannel(guildSettings.staff_log_channel)

			local valid, reasonInvalid, mutedRole = muteUtils.checkValidMute(muteMember, muteUser, guild, guildSettings)
			if not valid then
				local text = name.." could not be automatically unmuted because "..reasonInvalid
				utils.sendEmbedSafe(publicLogChannel, text, "ff0000")
				utils.sendEmbedSafe(staffLogChannel, text, "ff0000")
				muteUtils.deleteEntry(guild, muteUser, conn)
				goto continue
			end
			local isMuted = muteUtils.checkIfMuted(muteMember, muteUser, mutedRole, guild, conn)
			if not isMuted then
				muteUtils.deleteEntry(guild, muteUser, conn)
				goto continue
			end

			local mutedDM = utils.sendEmbed(muteUser:getPrivateChannel(), "You have been automatically unmuted in **"..guild.name.."**.", "00ff00")
			local success, err = muteUtils.unmute(muteMember, muteUser, mutedRole, guild, conn)
			if not success then
				if mutedDM then mutedDM:delete() end
				local text = name.." could not be automatically unmuted: `"..err.."`. Please report this error to the bot developer by sending Yotogi a direct message."
				utils.sendEmbedSafe(publicLogChannel, text, "ff0000")
				utils.sendEmbedSafe(staffLogChannel, text, "ff0000")
				goto continue
			end
			local text = name.." has been automatically unmuted."
			utils.sendEmbedSafe(publicLogChannel, text, "00ff00")
			utils.sendEmbedSafe(staffLogChannel, text, "00ff00")

			-- I know "goto is evil", but it drastically improves code clarity here because Lua doesn't have a continue statement
			::continue::
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