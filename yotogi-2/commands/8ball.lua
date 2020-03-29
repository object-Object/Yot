local commandHandler = require("../commandHandler")
local discordia = require("discordia")

local ballResponses={
	"Without a doubt", "Definitely", "As I see it, yes", "Yes", "Signs point to yes", "Certainly", "Indubitably", "Probably", -- positive
	"Maybe", "Don't ask me", "Ask someone else", "Ask your friends", "Perhaps", "Possibly", "Uncertain", "Signs are unclear", -- neutral
	"Don't count on it", "My reply is no", "My sources say no", "Outlook not so good", "Very doubtful", "Absolutely not", "No", "Certainly not" -- negative
}

return {
	name = "8ball",
	description = "Consult the magic 8-ball to find the answer to your question.",
	usage = "8ball <question>",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local responseNumber=math.random(#ballResponses)
		local response=ballResponses[responseNumber]
		local embedColor
		if responseNumber<=#ballResponses / 3 then
			-- positive, green
			embedColor = discordia.Color.fromRGB(0,255,0).value
		elseif responseNumber>=#ballResponses / 3 * 2 + 1 then
			-- negative, red
			embedColor = discordia.Color.fromRGB(255,0,0).value
		else
			-- neutral, yellow
			embedColor = discordia.Color.fromRGB(255,255,0).value
		end
		message.channel:send{
			embed={
				title=argString,
				author={
					name=(message.member and message.member.name.."#"..message.author.discriminator or message.author.tag),
					icon_url=message.author.avatarURL
				},
				description=":8ball: "..response,
				color=embedColor
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