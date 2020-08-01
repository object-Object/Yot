local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "ban",
	visible = true,
	permissions = {"banMembers"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end
		local banMember = utils.memberFromString(args[1], message.guild)
		local banUser = utils.userFromString(args[1], message.client)
		if not banUser then
			utils.sendEmbed(message.channel, f(lang.error.user_not_found, args[1]), "ff0000")
			return
		end
		local name = utils.name(banUser, message.guild)
		local days = args[2] and tonumber(args[2]:match("^(%d+)$")) or 0
		local daysRemoved = f(lang.ban.days_removed, days)
		local plainReason = argString:match("%|%s+(.+)")
		local reason = plainReason and f(lang.g.reason_str, plainReason) or ""
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
		elseif message.guild:getBan(banUser.id) then
			utils.sendEmbed(message.channel, f(lang.error.user_already_banned, name), "ff0000")
		else
			utils.sendEmbed(message.channel, f(lang.ban.user_banned, name)..reason, "00ff00", daysRemoved)
			utils.sendEmbed(banUser:getPrivateChannel(), f(lang.ban.you_banned, message.guild.name)..reason, "00ff00")
			utils.sendEmbedSafe(staffLogChannel, f(lang.ban.user_banned, name)..reason, "00ff00", f(lang.g.responsible_user_str, staffMember.name.."#"..staffMember.discriminator).."\n"..daysRemoved)
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