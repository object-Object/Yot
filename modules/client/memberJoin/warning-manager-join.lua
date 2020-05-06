local utils = require("miscUtils")
local commandHandler = require("commandHandler")

return {
	name = "warning-manager-join",
	description = "Set is_active to 1 and reset end_timestamp when users with warnings rejoin.",
	visible = false,
	disabledByDefault = false,
	run = function(self, guildSettings, member, conn)
		local entry, _ = conn:exec('SELECT * FROM warnings WHERE guild_id = "'..member.guild.id..'" AND user_id = "'..member.id..'";')
		if entry then
			entry = utils.formatRow(entry)
			entry.is_active = true
			entry.end_timestamp = os.time()+guildSettings.warning_length
			conn:exec('UPDATE warnings SET is_active = 1, end_timestamp = '..entry.end_timestamp..' WHERE guild_id = "'..member.guild.id..'" AND user_id = "'..member.id..'";')
			local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)
			utils.sendEmbed(member:getPrivateChannel(), "Your warnings have been given back in **"..member.guild.name.."**. You have "..entry.level.." warning"..utils.s(entry.level)..".", "00ff00", warnFooter)
			local publicLogChannel = guildSettings.public_log_channel and member.guild:getChannel(guildSettings.public_log_channel)
			local staffLogChannel = guildSettings.staff_log_channel and member.guild:getChannel(guildSettings.staff_log_channel)
			local text = member.user.tag.."'s warnings have been given back. They have "..entry.level.." warning"..utils.s(entry.level).."."
			utils.sendEmbedSafe(publicLogChannel, text, "00ff00", warnFooter)
			utils.sendEmbedSafe(staffLogChannel, text, "00ff00", warnFooter)
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}