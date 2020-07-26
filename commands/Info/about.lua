local commandHandler = require("commandHandler")
local discordia = require("discordia")
local fs = require("fs")

return {
	name = "about",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local changelog=fs.readFileSync("changelog.txt")
		local version=changelog and changelog:match("%*%*([^%*]+)%*%*") or lang.g.version_error
		message.channel:send{
			embed = {
				title = lang.commands.about.title,
				description = lang.commands.about.embed_desc,
				color = discordia.Color.fromHex("00ff00").value,
				fields = {
					{name = lang.commands.about.servers, value = #message.client.guilds},
					{name = "GitHub", value = "https://github.com/object-Object/Yot"},
					{name = lang.commands.about.invite_link, value = "https://objectobject.ca/Yot"}
				},
				footer = {
					text = f(lang.footer.version, version)
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