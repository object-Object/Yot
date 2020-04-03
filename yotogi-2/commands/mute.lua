local utils = require("../miscUtils")
local muteUtils = require("../muteUtils")
local commandHandler = require("../commandHandler")

local modifiers={
	m = 60,
	h = 3600,
	d = 86400,
	w = 604800
}

local function getSeconds(num, mod)
	if not (num and mod and modifiers[mod]) then
		num, mod = 0, 0
	else
		num, mod = tonumber(num), modifiers[mod]
	end
	return num*mod
end

return {
	name = "mute",
	description = "Mute a user.",
	usage = "mute <ping or id> [length (e.g. 2d4h, 5m, 1w2d3h4m)] [| reason]",
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

		local length=0
		local stringTimes=argString:match(utils.escapePatterns(args[1]).."%s+([^%|]+)") or ""
		for num, mod in stringTimes:gmatch("(%d+)(%a)") do
			length=length+getSeconds(num, mod)
		end
		length = length>0 and length or guildSettings.default_mute_length

		local valid, reasonInvalid, mutedRole = muteUtils.checkValidMute(muteMember, muteUser, message.guild, guildSettings)
		if not valid then
			utils.sendEmbed(message.channel, name.." could not be muted because "..reasonInvalid, "ff0000")
			return
		end
		local isMuted = muteUtils.checkIfMuted(muteMember, muteUser, mutedRole, message.guild, conn)
		if isMuted then
			utils.sendEmbed(message.channel, name.." is already muted.", "ff0000")
			return
		end

		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		local muteFooter = commandHandler.strings.muteFooter(guildSettings, length, os.time()+length, (muteMember and true))

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		local mutedDM = utils.sendEmbed(muteUser:getPrivateChannel(), "You have been muted in **"..message.guild.name.."**."..reason, "00ff00", muteFooter)
		local success, err = muteUtils.mute(muteMember, muteUser, mutedRole, message.guild, conn, length)
		if not success then
			if mutedDM then mutedDM:delete() end
			utils.sendEmbed(message.channel, name.." could not be muted: `"..err.."`. Please report this error to the bot developer by sending Yotogi a direct message.", "ff0000")
			return
		end
		utils.sendEmbed(message.channel, name.." has been muted."..reason, "00ff00", muteFooter)
		if staffLogChannel then
			utils.sendEmbed(staffLogChannel, name.." has been muted."..reason, "00ff00", "Responsible user: "..utils.name(message.author, guild).."\n"..muteFooter)
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