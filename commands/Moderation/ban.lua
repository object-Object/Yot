local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "ban",
	description = "Ban a user by ping or id. Optionally, the number of days of their messages to purge may be specified (defaults to 0).",
	usage = "ban <ping or id> [days of their messages to purge] [| reason]",
	visible = true,
	permissions = {"banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, self)
			return
		end
		local banMember = utils.memberFromString(args[1], message.guild)
		local banUser = utils.userFromString(args[1], message.client)
		if not banUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local name = banMember and banMember.name.."#"..banUser.discriminator or banUser.tag
		local days = args[2] and args[2]:match("^(%d+)$") or 0
		days = tonumber(days)
		local daysRemoved = days>0 and " "..days.." day"..utils.s(days).." of their messages "..(days==1 and "was" or "were").." purged." or ""
		local plainReason = argString:match("%|%s+(.+)")
		local reason = plainReason and " (Reason: "..plainReason..")" or ""
		local selfMember = message.guild:getMember(message.client.user.id)
		local staffMember = message.guild:getMember(message.author.id)
		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		if days>7 then
			utils.sendEmbed(message.channel, name.." could not be banned because the number of days of their messages to purge cannot be above 7.", "ff0000")
		elseif not selfMember:hasPermission("banMembers") then
			utils.sendEmbed(message.channel, name.." could not be banned because Yot does not have the `banMembers` permission.", "ff0000")
		elseif banMember and selfMember.highestRole.position<=banMember.highestRole.position then
			utils.sendEmbed(message.channel, name.." could not be banned because Yot's highest role is not higher than their highest role.", "ff0000")
		elseif banUser.id==message.guild.ownerId then
			utils.sendEmbed(message.channel, name.." could not be banned because they are the server owner.", "ff0000")
		else
			utils.sendEmbed(message.channel, name.." has been banned."..daysRemoved..reason, "00ff00")
			utils.sendEmbed(banUser:getPrivateChannel(), "You have been banned from **"..message.guild.name.."**."..reason, "00ff00")
			if staffLogChannel then
				utils.sendEmbed(staffLogChannel, name.." has been banned."..daysRemoved..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
			end
			message.guild:banUser(banUser.id, plainReason, days)
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