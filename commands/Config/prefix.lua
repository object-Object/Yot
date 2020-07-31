local utils = require("miscUtils")
local commandHandler = require("commandHandler")
local discordia = require("discordia")
local options = discordia.storage.options

return {
	name = "prefix",
	visible = true,
	permissions = {"administrator"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			utils.sendEmbed(message.channel, f(lang.commands.prefix.prefix_is, guildSettings.prefix), "00ff00")
			return
		end
		local newPrefix = argString:gsub("%`(.+)%`","%1")
		local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
		stmt:reset():bind(newPrefix, message.guild.id):step()
		stmt:close()
		utils.sendEmbed(message.channel, f(lang.commands.prefix.prefix_set, guildSettings.prefix, newPrefix),"00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {

		reset = {
			name = "prefix reset",
			run = function(self, message, argString, args, guildSettings, lang, conn)
				local stmt = conn:prepare("UPDATE guild_settings SET prefix = ? WHERE guild_id = ?;")
				stmt:reset():bind(options.defaultPrefix, message.guild.id):step()
				stmt:close()
				utils.sendEmbed(message.channel, f(lang.commands.prefix.prefix_reset, guildSettings.prefix, options.defaultPrefix), "00ff00")
			end,
			subcommands = {}
		}

	}
}