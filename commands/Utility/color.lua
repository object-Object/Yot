local commandHandler = require("commandHandler")
local utils = require("miscUtils")
local colors = require("colors")
local discordia = require("discordia")

return {
	name = "color",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end

		local code = argString:gsub("^%#",""):lower()

		if #code~=6 or code:match("%W")~=nil then
			utils.sendEmbed(message.channel, lang.error.invalid_color, "ff0000")
			return
		end

		local url = colors.getColorURL(code, message.client, conn)

		if not url then
			utils.sendEmbed(message.channel, lang.error.invalid_color, "ff0000")
			return
		end

		message:reply{
			embed = {
				title = "#"..code,
				image = {
					url = url
				},
				color = (code~="ffffff" and discordia.Color.fromHex(code).value or discordia.Color.fromHex("fffffe").value)
			}
		}
	end,
	onEnable = function(self, guildSettings, lang, conn)
		return true
	end,
	onDisable = function(self, guildSettings, lang, conn)
		return true
	end,
	subcommands = {}
}