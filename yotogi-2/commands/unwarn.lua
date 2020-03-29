local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")

return {
	name = "unwarn",
	description = "Unwarn a user.",
	usage = "unwarn <ping or id> [| reason]",
	visible = true,
	permissions = {"kickMembers","banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local warnMember = utils.memberFromString(args[1], message.guild)
		local warnUser = utils.userFromString(args[1], message.client)
		if not warnUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
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
		local logChannel = guildSettings.log_channel and message.guild:getChannel(guildSettings.log_channel)
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)
		utils.sendEmbed(message.channel, name.." has been unwarned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
		utils.sendEmbed(warnUser:getPrivateChannel(), "You have been unwarned in **"..message.guild.name.."**. You now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00", warnFooter)
		if logChannel then
			utils.sendEmbed(logChannel, name.." has been unwarned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "00ff00",
				"Responsible user: "..(message.member and message.member.name or message.author.name).."#"..message.user.discriminator.."\n"..warnFooter)
		end
		utils.setGame(message.client, conn)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}