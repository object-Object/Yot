local utils = require("miscUtils")
local muteUtils = require("muteUtils")
local commandHandler = require("commandHandler")

return {
	name = "mute-manager-join",
	description = "Set is_active to 1 and reset end_timestamp when users with mutes rejoin.",
	visible = false,
	disabledByDefault = false,
	run = function(self, guildSettings, muteMember, conn)
		local entry, _ = conn:exec('SELECT * FROM mutes WHERE guild_id = "'..muteMember.guild.id..'" AND user_id = "'..muteMember.id..'";')
		if not entry then return end
		entry = utils.formatRow(entry)

		local muteUser = muteMember.user
		local name = utils.name(muteUser, muteMember.guild)

		local publicLogChannel = guildSettings.public_log_channel and muteMember.guild:getChannel(guildSettings.public_log_channel)
		local staffLogChannel = guildSettings.staff_log_channel and muteMember.guild:getChannel(guildSettings.staff_log_channel)

		local valid, reasonInvalid, mutedRole = muteUtils.checkValidMute(muteMember, muteUser, muteMember.guild, guildSettings)
		if not valid then
			local text = name.."'s mute could not be given back because "..reasonInvalid
			utils.sendEmbedSafe(publicLogChannel, text, "ff0000")
			utils.sendEmbedSafe(staffLogChannel, text, "ff0000")
			muteUtils.deleteEntry(muteMember.guild, muteUser, conn)
			return
		end

		local muteFooter = commandHandler.strings.muteFooter(guildSettings, entry.length, os.time()+entry.length, true)

		local mutedDM = utils.sendEmbed(muteUser:getPrivateChannel(), "Your mute has been given back in **"..muteMember.guild.name.."**.", "00ff00", muteFooter)
		local success, err = muteUtils.remute(muteMember, muteUser, mutedRole, muteMember.guild, conn, entry.length)
		if not success then
			if mutedDM then mutedDM:delete() end
			local text = name.."'s mute could not be given back: `"..err.."`. Please report this error to the bot developer by sending Yot a direct message."
			utils.sendEmbedSafe(publicLogChannel, text, "ff0000")
			utils.sendEmbedSafe(staffLogChannel, text, "ff0000")
			return
		end
		local text = name.."'s mute has been given back."
		utils.sendEmbedSafe(publicLogChannel, text, "00ff00", muteFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "00ff00", muteFooter)
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}