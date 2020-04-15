local commandHandler = require("../commandHandler")
local utils = require("../miscUtils")

return {
	name = "mention",
	description = "Mention (ping) someone using their discriminator (tag - the 4 numbers after the hashtag in their username), part or all of their username, or both. Alternatively, you can use their id.",
	usage = "mention <[part or all of username][#discriminator] or user id>",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end

		if #message.mentionedUsers>0 then
			message:reply("User was successfully pinged in the command. No further action is necessary.")
			return
		end

		local mentionedUser = utils.userFromString(args[1], message.client)
		local input = argString:gsub("^@",""):lower()
		local inputName = input:match("(.+)%#%d%d%d%d$")
		local inputDiscrim = input:match("%#(%d%d%d%d)$")

		if inputDiscrim and inputName then
			-- check if both the discrim and the name match
			mentionedUser = mentionedUser or message.guild.members:find(function(e)
				return e.discriminator==inputDiscrim and (e.username:lower():find(inputName, 1, true) or e.name:lower():find(inputName, 1, true))
			end)
			-- check if the discrim matches
			mentionedUser = mentionedUser or message.guild.members:find(function(e)
				return e.discriminator==inputDiscrim
			end)
		end
		-- check if the name matches
		mentionedUser = mentionedUser or message.guild.members:find(function(e)
			return e.username:lower():find(input, 1, true) or e.name:lower():find(input, 1, true) 
		end)
		-- check if the name matches the entire input
		mentionedUser = mentionedUser or message.guild.members:find(function(e)
			return e.username:lower():find(argString:lower(), 1, true) or e.name:lower():find(argString:lower(), 1, true) 
		end)

		if mentionedUser then
			message:reply("Ping from **"..utils.name(message.author, message.guild).."** using `"..guildSettings.prefix.."mention`: "..mentionedUser.mentionString)
		else
			message:reply("Could not find user `"..argString.."`.")
		end
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}