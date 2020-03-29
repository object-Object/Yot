local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")

return {
	name = "warningRemover",
	description = "Runs once per minute to remove any active warnings that have expired.",
	visible = true,
	discordEvent = "clock.min",
	run = function(guildSettings, guild, conn)
		local warnings, nrow = conn:exec("SELECT * FROM warnings WHERE is_active = 1 AND end_timestamp <= "..os.time().." AND guild_id = '"..guild.id.."';")
		if warnings then
			local decreaseStmt = conn:prepare("UPDATE warnings SET level = ?, end_timestamp = ? WHERE guild_id = ? AND user_id = ?;")
			local deleteStmt = conn:prepare("DELETE FROM warnings WHERE guild_id = ? AND user_id = ?;")
			for row=1, nrow do
				local warnMember = guild:getMember(warnings.user_id[row])
				local warnUser = guild.client:getUser(warnings.user_id[row])
				local level = warnings.level[row]-1
				local end_timestamp = level>0 and os.time()+guildSettings.warning_length or 0
				if level==0 then
					deleteStmt:reset():bind(guild.id, warnUser.id):step()
				else
					decreaseStmt:reset():bind(level, end_timestamp, guild.id, warnUser.id):step()
				end
				local logChannel = guildSettings.log_channel and guild:getChannel(guildSettings.log_channel)
				local warnFooter = commandHandler.strings.warnFooter(guildSettings, {is_active=true, end_timestamp=end_timestamp, level=level})
				local name = warnMember and warnMember.name.."#"..warnUser.discriminator or warnUser.tag
				utils.sendEmbed(warnUser:getPrivateChannel(), "You have been automatically unwarned in **"..guild.name.."**. You now have "..level.." warning"..utils.s(level)..".", "00ff00", warnFooter)
				if logChannel then
					utils.sendEmbed(logChannel, name.." has been automatically unwarned. They now have "..level.." warning"..utils.s(level)..".", "00ff00", warnFooter)
				end
			end
			decreaseStmt:close()
			deleteStmt:close()
			utils.setGame(guild.client, conn)
		end
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end
}