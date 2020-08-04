local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "mention",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end

		if #message.mentionedUsers>0 then
			utils.sendEmbed(message.channel, lang.commands.mention.ping_worked, "ff0000")
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
		elseif inputDiscrim then
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
			message:reply(f(lang.commands.mention.ping, utils.name(message.author, message.guild), guildSettings.prefix, mentionedUser.mentionString))
		else
			utils.sendEmbed(message.channel, f(lang.error.user_not_found, argString), "ff0000")
		end
	end,
	onEnable = function(self, guildSettings, lang, conn)
		return true
	end,
	onDisable = function(self, guildSettings, lang, conn)
		return true
	end,
	subcommands = {}
}