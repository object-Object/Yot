local utils = require("miscUtils")

return {
	name = "roll",
	description = "Roll a dice.",
	usage = "roll [number of rolls]d<number of sides on dice>[+modifier or -modifier]",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local rolls,sides,modifier="","",""
		if argString~="" then
			rolls,sides=argString:match("(%d*)d(%d+)")
			if not sides then return end
			if rolls=="" then rolls="1" end
			modifier=argString:match("d"..sides.."(%p%d+)")
		else
			rolls,sides,modifier="1","20",nil
		end
		local result=0
		for i=1,tonumber(rolls) do
			local handle=io.popen("date +%s%N | cut -b1-13")
			local ms=tonumber(handle:read("*n"))
			handle:close()
			math.randomseed(ms)
			result=result+math.random(sides)
		end
		if modifier then result=result+modifier else modifier="" end
		utils.sendEmbed(message.channel, message.member.name.." rolled "..rolls.."d"..sides..modifier.." and got "..result..".", "00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}