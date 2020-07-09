local commandHandler = require("../commandHandler")
local discordia = require("discordia")
local fs = require("fs")

return {
	name = "about",
	description = "Display information about the bot.",
	usage = "about",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		local changelog=fs.readFileSync("changelog.txt")
		local version=changelog and changelog:match("%*%*([^%*]+)%*%*") or "error"
		message.channel:send{
			embed = {
				title = "About Yot",
				description = "• Yot is a moderation and utility bot, written in Lua.\n• It is written, hosted, and maintained by [object Object]#0001.\n• Found a bug? Send a direct message to Yot! Include some information about the bug, like what you were doing when it happened, what you expected to happen, and what actually happened.",
				color = discordia.Color.fromHex("00ff00").value,
				fields = {
					{name = "Servers", value = #message.client.guilds},
					{name = "GitHub", value = "https://github.com/object-Object/Yot"},
					{name = "Invite link", value = "https://objectobject.ca/Yot"}
				},
				footer = {
					text = "Version: "..version
				}
			}
		}
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}