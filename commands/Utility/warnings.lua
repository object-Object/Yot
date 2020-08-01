local commandHandler = require("commandHandler")
local utils = require("miscUtils")

return {
	name = "warnings",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		local warnMember = message.member
		local warnUser = message.author
		if argString~="" then
			warnMember = utils.memberFromString(argString, message.guild)
			warnUser = utils.userFromString(argString, message.client)
			if not warnUser then
				utils.sendEmbed(message.channel, f(lang.error.user_not_found, argString), "ff0000")
				return
			elseif warnUser.bot then
				utils.sendEmbed(message.channel, f(lang.error.bot_cannot_have_warn, argString), "ff0000")
				return
			end
		end
		local entry, _ = conn:exec("SELECT * FROM warnings WHERE guild_id = '"..message.guild.id.."' AND user_id = '"..warnUser.id.."';")
		if entry then
			entry = utils.formatRow(entry)
		else
			entry = {level = 0, end_timestamp = 0, is_active = warnMember~=nil}
		end
		local name = warnMember and warnMember.name.."#"..warnUser.discriminator or warnUser.tag
		utils.sendEmbed(message.channel, f(lang.pl(lang.warn.user_has_n_warnings, entry.level), name, entry.level), "00ff00",
			(warnUser==message.author and f(lang.warn.try_refresh, guildSettings.prefix).."\n" or "")..commandHandler.strings.warnFooter(guildSettings, lang, entry))
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
			run = function(self, message, argString, args, guildSettings, lang, conn)
				local entry, _ = conn:exec("SELECT * FROM warnings WHERE guild_id = '"..message.guild.id.."' AND user_id = '"..message.author.id.."';")
				if entry then
					entry = utils.formatRow(entry)
					if not entry.is_active and message.guild:getMember(message.author.id) then
						conn:exec('UPDATE warnings SET is_active = 1 WHERE guild_id = "'..message.guild.id..'" AND user_id = "'..message.author.id..'";')
						utils.sendEmbed(message.channel, lang.warn.refreshed_set_active, "00ff00")
						return
					end
				end
				utils.sendEmbed(message.channel, lang.warn.refreshed_no_changes, "00ff00")
			end,
			subcommands = {}
		}

	}
}