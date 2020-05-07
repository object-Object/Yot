local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "unban",
	description = "Unban a user by ping or id.",
	usage = "unban <ping or id> [| reason]",
	visible = true,
	permissions = {"banMembers"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, self)
			return
		end
		local banUser = utils.userFromString(args[1], message.client)
		if not banUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local name = banUser.tag
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		local selfMember = message.guild:getMember(message.client.user.id)
		local staffMember = message.guild:getMember(message.author.id)
		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		if not selfMember:hasPermission("banMembers") then
			utils.sendEmbed(message.channel, name.." could not be unbanned because Yot does not have the `banMembers` permission.", "ff0000")
		elseif not message.guild:getBans():find(function(m) return m.user.id==banUser.id end) then
			utils.sendEmbed(message.channel, name.." is not banned.", "ff0000")
		else
			utils.sendEmbed(message.channel, name.." has been unbanned."..reason, "00ff00")
			utils.sendEmbed(banUser:getPrivateChannel(), "You have been unbanned from **"..message.guild.name.."**."..reason, "00ff00")
			if staffLogChannel then
				utils.sendEmbed(staffLogChannel, name.." has been unbanned."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
			end
			message.guild:unbanUser(banUser.id, reason)
		end
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}