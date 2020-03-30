local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")

return {
	name = "ban",
	description = "Ban a user by ping or id.",
	usage = "ban <ping or id> [| reason]",
	visible = true,
	permissions = {"banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local banMember = utils.memberFromString(args[1], message.guild)
		local banUser = utils.userFromString(args[1], message.client)
		if not banUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local name = banMember and banMember.name.."#"..banUser.discriminator or banUser.tag
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		local selfMember = message.guild:getMember(message.client.user.id)
		local staffMember = message.guild:getMember(message.author.id)
		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		if not selfMember:hasPermission("banMembers") then
			utils.sendEmbed(message.channel, name.." could not be banned because Yotogi does not have the `banMembers` permission.", "ff0000")
		elseif banMember and selfMember.highestRole.position<=banMember.highestRole.position then
			utils.sendEmbed(message.channel, name.." could not be banned because Yotogi's highest role is not higher than their highest role.", "ff0000")
		elseif banUser.id==message.guild.ownerId then
			utils.sendEmbed(message.channel, name.." could not be banned because they are the server owner.", "ff0000")
		else
			utils.sendEmbed(message.channel, name.." has been banned."..reason, "00ff00")
			utils.sendEmbed(banUser:getPrivateChannel(), "You have been banned from **"..message.guild.name.."**."..reason, "00ff00")
			if staffLogChannel then
				utils.sendEmbed(staffLogChannel, name.." has been banned."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
			end
			banMember:ban(reason)
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