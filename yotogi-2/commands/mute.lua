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
		local muteMember = utils.memberFromString(args[1], message.guild)
		local muteUser = utils.userFromString(args[1], message.client)
		if not muteUser then
			utils.sendEmbed(message.channel, "User "..args[1].." not found.", "ff0000")
			return
		end
		local length=0
		local stringTimes=argString:match(utils.escapePatterns(args[1]).."%s+([^%|]+)") or ""
		for num, mod in stringTimes:gmatch("(%d+)(%a)") do
			length=length+getSeconds(num, mod)
		end
		length = length>0 and length or guildSettings.default_mute_length
		local reason = argString:match("%|%s+(.+)")
		reason = reason and " (Reason: "..reason..")" or ""
		muteUtils.mute(muteMember, muteUser, message, guildSettings, conn, length, reason)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}