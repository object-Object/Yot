local utils = require("miscUtils")
local commandHandler = require("commandHandler")
local discordia = require("discordia")
local options = discordia.storage.options

return {
	name = "prefix",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		utils.sendEmbed(message.channel, f(lang.commands.prefix.prefix_is, guildSettings.prefix), "00ff00")
	end,
	onEnable = function(self, guildSettings, lang, conn)
		return true
	end,
	onDisable = function(self, guildSettings, lang, conn)
		return true
	end,
	subcommands = {

		set = {
			name = "prefix set",
			permissions = {"administrator"},
			run = function(self, message, argString, args, guildSettings, lang, conn)
				if argString=="" then
					commandHandler.sendUsage(message.channel, guildSettings, lang, self)
					return
				end
				local newPrefix = argString:gsub("%`(.+)%`","%1")
				if guildSettings.prefix==newPrefix then
					utils.sendEmbed(message.channel, f(lang.error.prefix_already_set, newPrefix),"ff0000")
					return
				end
				local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
				stmt:reset():bind(newPrefix, message.guild.id):step()
				stmt:close()
				utils.sendEmbed(message.channel, f(lang.commands.prefix.prefix_set, guildSettings.prefix, newPrefix),"00ff00")
			end,
			subcommands = {}
		},

		reset = {
			name = "prefix reset",
			permissions = {"administrator"},
			run = function(self, message, argString, args, guildSettings, lang, conn)
				if guildSettings.prefix==options.defaultPrefix then
					utils.sendEmbed(message.channel, f(lang.error.prefix_already_set, options.defaultPrefix),"ff0000")
					return
				end
				local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
				stmt:reset():bind(options.defaultPrefix, message.guild.id):step()
				stmt:close()
				utils.sendEmbed(message.channel, f(lang.commands.prefix.prefix_reset, guildSettings.prefix, options.defaultPrefix), "00ff00")
			end,
			subcommands = {}
		}

	}
}