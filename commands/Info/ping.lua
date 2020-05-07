local discordia = require("discordia")
local stopwatch = discordia.Stopwatch()

return {
	name = "ping",
	description = "Show Yot's ping (API latency).",
	usage = "ping",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		stopwatch:reset()
		stopwatch:start()
		local outputMsg = message.channel:send("Pinging...")
		stopwatch:stop()
		outputMsg:update{
			embed = {
				description = "Ping: `"..math.floor(stopwatch:getTime():toMilliseconds()+0.5).." ms`",
				color = discordia.Color.fromHex("00ff00").value
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