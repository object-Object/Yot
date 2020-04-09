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
				title = "About Yotogi",
				description = "• Yotogi is a general-purpose bot with an emphasis on moderation.\n• It is written, hosted, and maintained by [object Object]#0001.\n• Found a bug? Send a direct message to Yotogi! Include some information about the bug, like what you were doing when it happened, what you expected to happen, and what actually happened.",
				color = discordia.Color.fromHex("00ff00").value,
				fields = {
					{name = "Servers", value = #message.client.guilds},
					{name = "GitHub", value = "https://github.com/object-Object/Yotogi"},
					{name = "Invite link", value = "https://discordapp.com/api/oauth2/authorize?client_id=316932415840845865&permissions=805431366&scope=bot"}
				},
				footer = {
					text = "Version "..version
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