local commandHandler = require("../commandHandler")

return {
	name = "ping",
	description = "Ping someone using their tag, part or all of their username, or both.",
	usage = "ping [part or all of username][#tag]",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end
		local mentionedUser = message.mentionedUsers.first
		if mentionedUser then
			message:reply("Ping from "..message.member.name..": "..mentionedUser.mentionString)
		else
			argString=argString:gsub("^@",""):lower()
			local discrim = argString:match("%#(%d%d%d%d)")
			if discrim then
				local name = argString:match("(.+)%#%d%d%d%d")
				if name then
					local m=message.guild.members:find(function(e) return e.discriminator == discrim and (e.username:lower():find(name,1,true) or e.name:lower():find(name,1,true)) end) 
					if m then
						message:reply("Ping from **"..message.member.name.."** using `"..guildSettings.prefix.."ping`: "..m.mentionString)
					else
						message:reply("Ping from **"..message.member.name.."** using `"..guildSettings.prefix.."ping`: could not find member `"..argString.."`")
					end
				else
					local m=message.guild.members:find(function(e) return e.discriminator == discrim end)
					if m then
						message:reply("Ping from **"..message.member.name.."** using `"..guildSettings.prefix.."ping`: "..m.mentionString)
					else
						message:reply("Ping from **"..message.member.name.."** using `"..guildSettings.prefix.."ping`: could not find member `"..argString.."`")
					end
				end
			else
				local m=message.guild.members:find(function(e) return e.username:lower():find(argString,1,true) or e.name:find(argString,1,true) end)
				if m then
					message:reply("Ping from **"..message.member.name.."** using `"..guildSettings.prefix.."ping`: "..m.mentionString)
				else
					message:reply("Ping from **"..message.member.name.."** using `"..guildSettings.prefix.."ping`: could not find member `"..argString.."`")
				end
			end
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