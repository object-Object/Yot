local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")

return {
	name = "prefix",
	description = "Change the command prefix for this bot in this server.",
	usage = "prefix <new prefix (may be in an inline code block)>",
	visible = true,
	permissions = {"administrator"},
	run = function(message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, "prefix")
			return
		end
		local newPrefix = argString:gsub("%`(.+)%`","%1")
		local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
		stmt:reset():bind(newPrefix, message.guild.id):step()
		stmt:close()
		utils.sendEmbed(message.channel,"Prefix updated to `"..newPrefix.."`.","00ff00")
	end,
	subcommands = {}
}