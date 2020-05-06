local utils = require("miscUtils")

return {
	name = "warning-manager-leave",
	description = "Set is_active to 0 when users with warnings leave.",
	visible = false,
	event = "client.memberLeave",
	disabledByDefault = false,
	run = function(self, guildSettings, member, conn)
		local entry, _ = conn:exec('SELECT * FROM warnings WHERE guild_id = "'..member.guild.id..'" AND user_id = "'..member.id..'";')
		if entry then
			conn:exec('UPDATE warnings SET is_active = 0 WHERE guild_id = "'..member.guild.id..'" AND user_id = "'..member.id..'";')
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}