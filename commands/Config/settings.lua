local rm = require("reactionMenu")

return {
	name = "settings",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local menu = rm.Menu{
			startPage = rm.Page{
				title = lang.settings.main_title,
				description = lang.settings.main_desc,
				choices = {
					rm.Choice{
						name = lang.settings.settings_choice,
						destination = rm.Page{
							title = "placeholder"
						}
					},
					rm.Choice{
						name = lang.settings.commands_choice,
						destination = rm.Page{
							title = "placeholder"
						}
					},
					rm.Choice{
						name = lang.settings.modules_choice,
						destination = rm.Page{
							title = "placeholder"
						}
					}
				}
			},
			storage = {
				conn = conn,
				guildSettings = guildSettings
			}
		}
		rm.send(message.channel, message.author, menu, lang)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}