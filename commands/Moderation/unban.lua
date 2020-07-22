local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "unban",
	visible = true,
	permissions = {"banMembers"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local banUser = utils.userFromString(args[1], message.client)
		if not banUser then
			utils.sendEmbed(message.channel, f(lang.error.user_not_found, args[1]), "ff0000")
			return
		end
		local name = banUser.tag
		local reason = argString:match("%|%s+(.+)")
		reason = reason and f(lang.g.reason_str, reason) or ""
		local selfMember = message.guild:getMember(message.client.user.id)
		local staffMember = message.guild:getMember(message.author.id)
		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)
		if not selfMember:hasPermission("banMembers") then
			utils.sendEmbed(message.channel, f(lang.error.unban_fail, name, f(lang.error.missing_bot_permission_2, "banMembers")), "ff0000")
		elseif not message.guild:getBans():find(function(m) return m.user.id==banUser.id end) then
			utils.sendEmbed(message.channel, f(lang.error.user_not_banned, name), "ff0000")
		else
			utils.sendEmbed(message.channel, f(lang.ban.user_unbanned, name)..reason, "00ff00")
			utils.sendEmbed(banUser:getPrivateChannel(), f(lang.ban.you_unbanned, message.guild.name)..reason, "00ff00")
			utils.sendEmbedSafe(staffLogChannel, f(lang.logs.user_unbanned, name)..reason, "00ff00", f(lang.g.responsible_user_str, staffMember.name.."#"..staffMember.discriminator))
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