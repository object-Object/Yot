local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "warnings",
	description = "Show how many warnings you have, or how many someone else has.",
	usage = "warnings [ping or id]",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		local warnMember = message.member
		local warnUser = message.author
		if argString~="" then
			warnMember = utils.memberFromString(argString, message.guild)
			warnUser = utils.userFromString(argString, message.client)
			if not warnUser then
				utils.sendEmbed(message.channel, "User "..argString.." not found.", "ff0000")
				return
			elseif warnUser.bot then
				utils.sendEmbed(message.channel, "User "..argString.." cannot have warnings because they are a bot.", "ff0000")
				return
			end
		end
		local entry, _ = conn:exec("SELECT * FROM warnings WHERE guild_id = '"..message.guild.id.."' AND user_id = '"..warnUser.id.."';")
		if entry then
			entry = utils.formatRow(entry)
		else
			entry = {level = 0, end_timestamp = 0, is_active = true}
		end
		local name = warnMember and warnMember.name.."#"..warnUser.discriminator or warnUser.tag
		utils.sendEmbed(message.channel, name.." has "..entry.level.." warning"..utils.s(entry.level)..".", "00ff00",
			(warnUser==message.author and "Does something seem wrong? Try "..guildSettings.prefix.."warnings refresh\n" or "")..commandHandler.strings.warnFooter(guildSettings, entry))
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {

		refresh = {
			name = "warnings refresh",
			description = "Do this command if something seems wrong with your warnings, such as being marked not active even when you're in the server.",
			usage = "warnings refresh",
			run = function(self, message, argString, args, guildSettings, conn)
				local entry, _ = conn:exec("SELECT * FROM warnings WHERE guild_id = '"..message.guild.id.."' AND user_id = '"..message.author.id.."';")
				if entry then
					entry = utils.formatRow(entry)
					if not entry.is_active and message.guild:getMember(message.author.id) then
						conn:exec('UPDATE warnings SET is_active = 1 WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..message.author.id..'";')
						utils.sendEmbed(message.channel, "Successfully refreshed your warnings. `is_active` was set to true.", "00ff00")
						return
					end
				end
				utils.sendEmbed(message.channel, "Successfully refreshed your warnings. No changes were made.", "00ff00")
			end,
			subcommands = {}
		}

	}
}