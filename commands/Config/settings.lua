local rm = require("reactionMenu")
local commandHandler = require("commandHandler")

return {
	name = "settings",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local commandChoices = {}
		local commandNames = table.keys(commandHandler.commands)
		table.sort(commandNames)
		for _, commandString in ipairs(commandNames) do
			local command = commandHandler.commands[commandString]
			if command.visible then
				table.insert(commandChoices, rm.Choice{
					name = "`"..guildSettings.prefix..command.name.."`",
					destination = rm.Page{
						title = guildSettings.prefix..command.name,
						choices = {
							rm.Choice{
								name = lang.settings.enable_disable_choice,
								value = function(self, menu, lang)
									return menu.storage.guildSettings.disabled_commands[command.name] and lang.settings.disabled or lang.settings.enabled
								end,
								onChoose = function(self, menu, lang)
									local success, output = commandHandler.toggle(command, menu.storage.guildSettings, lang, menu.storage.conn)
									return rm.Page{
										title = menu.storage.guildSettings.prefix..command.name,
										color = (success and "00ff00" or "ff0000"),
										description = output
									}
								end
							}
						}
					}
				})
			end
		end

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
						destination = rm.paginateChoices(commandChoices, lang.settings.command_list_title, lang.settings.command_list_desc, lang)
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
	onEnable = function(self, guildSettings, lang, conn)
		return true
	end,
	onDisable = function(self, guildSettings, lang, conn)
		return true
	end,
	subcommands = {}
}