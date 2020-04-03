local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")
local moduleHandler = require("../moduleHandler")
local options = require("../options")

return {
	name = "warning-manager",
	description = "Runs once per minute to remove any active warnings that have expired.",
	visible = true,
	event = "clock.min",
	disabledByDefault = false,
	run = function(self, guildSettings, guild, conn)
		local warnings, nrow = conn:exec("SELECT * FROM warnings WHERE is_active = 1 AND end_timestamp <= "..os.time().." AND guild_id = '"..guild.id.."';")
		if warnings then
			local decreaseStmt = conn:prepare("UPDATE warnings SET level = ?, end_timestamp = ? WHERE guild_id = ? AND user_id = ?;")
			local deleteStmt = conn:prepare("DELETE FROM warnings WHERE guild_id = ? AND user_id = ?;")
			local fixActiveStmt = conn:prepare("UPDATE warnings SET is_active = 0 WHERE guild_id = ? AND user_id = ?;")
			for row=1, nrow do
				local warnMember = guild:getMember(warnings.user_id[row])
				if not warnMember then
					fixActiveStmt:reset():bind(guild.id, warnings.user_id[row]):step()
				else
					local warnUser = guild.client:getUser(warnings.user_id[row])
					local level = warnings.level[row]-1
					local end_timestamp = level>0 and os.time()+guildSettings.warning_length or 0
					if level==0 then
						deleteStmt:reset():bind(guild.id, warnUser.id):step()
					else
						decreaseStmt:reset():bind(level, end_timestamp, guild.id, warnUser.id):step()
					end
					local publicLogChannel = guildSettings.public_log_channel and guild:getChannel(guildSettings.public_log_channel)
					local staffLogChannel = guildSettings.staff_log_channel and guild:getChannel(guildSettings.staff_log_channel)
					local warnFooter = commandHandler.strings.warnFooter(guildSettings, {is_active=true, end_timestamp=end_timestamp, level=level})
					local name = warnMember.name.."#"..warnUser.discriminator
					utils.sendEmbed(warnUser:getPrivateChannel(), "You have been automatically unwarned in **"..guild.name.."**. You now have "..level.." warning"..utils.s(level)..".", "00ff00", warnFooter)
					if publicLogChannel then
						utils.sendEmbed(publicLogChannel, name.." has been automatically unwarned. They now have "..level.." warning"..utils.s(level)..".", "00ff00", warnFooter, nil, warnUser.mentionString)
					end
					if staffLogChannel then
						utils.sendEmbed(staffLogChannel, name.." has been automatically unwarned. They now have "..level.." warning"..utils.s(level)..".", "00ff00", warnFooter)
					end
				end
			end
			decreaseStmt:close()
			deleteStmt:close()
			fixActiveStmt:close()
			utils.setGame(guild.client, conn)
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		conn:exec("UPDATE guild_settings SET warning_length = "..options.warningLength.." WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, "Warnings will now expire. The `warning_length` setting has been set to "..options.warningLength..".", "00ff00")
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		conn:exec("UPDATE guild_settings SET warning_length = 0 WHERE guild_id = '"..message.guild.id.."';")
		utils.sendEmbed(message.channel, "Warnings will no longer expire. The `warning_length` setting has been set to 0.", "00ff00")
		return true
	end
}