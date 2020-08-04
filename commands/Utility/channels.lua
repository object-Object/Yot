local discordia = require("discordia")

return {
	name = "channels",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local textChannelCount=#message.guild.textChannels
		local voiceChannelCount=#message.guild.voiceChannels
		local categoryCount=#message.guild.categories
		local totalChannelCount=textChannelCount+voiceChannelCount+categoryCount
		local r=1.02*(totalChannelCount)
		local g=1.02*(500-(totalChannelCount))
		if r>255 then r=255 end
		if g>255 then g=255 end
		message:reply{
			embed={
				fields={
					{name=lang.commands.channels.text_channels, value=textChannelCount, inline=true},
					{name=lang.commands.channels.voice_channels, value=voiceChannelCount, inline=true},
					{name=lang.commands.channels.categories, value=categoryCount, inline=true},
					{name=lang.commands.channels.total_usage, value=f(lang.commands.channels.channel_usage, totalChannelCount, 500-totalChannelCount), inline=true}
				},
				color=discordia.Color.fromRGB(r, g, 0).value
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