local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "kick",
	description = "Kick a user by ping or id.",
	usage = "kick <ping or id> [| reason]",
	visible = true,
	permissions = {"kickMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, self)
			return
		end
		local kickMember = utils.memberFromString(args[1], message.guild)
		local kickUser = utils.userFromString(args[1], message.client)
		if not kickUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local name = utils.name(kickUser, message.guild)
		if not kickMember then
			utils.sendEmbed(message.channel, name.." could not be kicked because they are not in this server.", "ff0000")
			return
		end
		local plainReason = argString:match("%|%s+(.+)")
		local reason = plainReason and " (Reason: "..plainReason..")" or ""
		local selfMember = message.guild:getMember(message.client.user.id)
		local staffMember = message.guild:getMember(message.author.id)
		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		if not selfMember:hasPermission("kickMembers") then
			utils.sendEmbed(message.channel, name.." could not be kicked because Yot does not have the `kickMembers` permission.", "ff0000")
		elseif kickMember and selfMember.highestRole.position<=kickMember.highestRole.position then
			utils.sendEmbed(message.channel, name.." could not be kicked because Yot's highest role is not higher than their highest role.", "ff0000")
		elseif kickUser.id==message.guild.ownerId then
			utils.sendEmbed(message.channel, name.." could not be kicked because they are the server owner.", "ff0000")
		else
			utils.sendEmbed(message.channel, name.." has been kicked."..reason, "00ff00")
			utils.sendEmbed(kickUser:getPrivateChannel(), "You have been kicked from **"..message.guild.name.."**."..reason, "00ff00")
			if staffLogChannel then
				utils.sendEmbed(staffLogChannel, name.." has been kicked."..reason, "00ff00", "Responsible user: "..staffMember.name.."#"..staffMember.discriminator)
			end
			message.guild:kickUser(kickUser.id, plainReason)
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