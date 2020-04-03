local utils = require("../miscUtils")
local muteUtils = require("../muteUtils")
local commandHandler = require("../commandHandler")

return {
	name = "unmute",
	description = "Unmute a user.",
	usage = "unmute <ping or id> [| reason]",
	visible = true,
	permissions = {"manageRoles"},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		
		local muteUser = utils.userFromString(args[1], message.client)
		if not muteUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local muteMember = utils.memberFromString(args[1], message.guild)
		local name = utils.name(muteUser, message.guild)

		local valid, reasonInvalid, mutedRole = muteUtils.checkValidMute(muteMember, muteUser, message.guild, guildSettings)
		if not valid then
			utils.sendEmbed(message.channel, name.." could not be unmuted because "..reasonInvalid, "ff0000")
			return
		end
		local isMuted = muteUtils.checkIfMuted(muteMember, muteUser, mutedRole, message.guild, conn)
		if not isMuted then
			utils.sendEmbed(message.channel, name.." is not muted.", "ff0000")
			muteUtils.deleteEntry(message.guild, muteUser, conn)
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		local mutedDM = utils.sendEmbed(muteUser:getPrivateChannel(), "You have been unmuted in **"..message.guild.name.."**."..reason, "00ff00")
		local success, err = muteUtils.unmute(muteMember, muteUser, mutedRole, message.guild, conn)
		if not success then
			if mutedDM then mutedDM:delete() end
			utils.sendEmbed(message.channel, name.." could not be unmuted: `"..err.."`. Please report this error to the bot developer by sending Yotogi a direct message.", "ff0000")
			return
		end
		utils.sendEmbed(message.channel, name.." has been unmuted."..reason, "00ff00")
		if staffLogChannel then
			utils.sendEmbed(staffLogChannel, name.." has been unmuted."..reason, "00ff00", "Responsible user: "..utils.name(message.author, guild))
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