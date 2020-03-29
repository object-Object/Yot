local discordia = require("discordia")

return {
	name = "channels",
	description = "Show statistics about the number of channels in the server.",
	usage = "channels",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
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
					{name="Text Channels", value=textChannelCount, inline=true},
					{name="Voice Channels", value=voiceChannelCount, inline=true},
					{name="Categories", value=categoryCount, inline=true},
					{name="Usage", value=totalChannelCount.."/500 (".. 500-totalChannelCount.." remaining)", inline=true}
				},
				color=discordia.Color.fromRGB(r, g, 0).value
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