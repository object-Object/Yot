local utils = require("miscUtils")

return {
	name = "persistent-roles-join",
	visible = false,
	disabledByDefault = false,
	run = function(self, guildSettings, lang, member, conn)
		local entry = conn:exec("SELECT * FROM persistent_roles WHERE guild_id = '"..member.guild.id.."' AND user_id = '"..member.id.."';")
		if entry then
			conn:exec("DELETE FROM persistent_roles WHERE guild_id = '"..member.guild.id.."' AND user_id = '"..member.id.."';")
			entry = utils.formatRow(entry)
			local addedRoles = {}
			for _, roleId in pairs(entry.roles) do
				local role = member.guild:getRole(roleId)
				if role and guildSettings.persistent_roles[roleId] and member:addRole(role)then
					table.insert(addedRoles, "`"..role.name.."`")
				end
			end
			if #addedRoles==0 then return end
			local addedRolesStr = table.concat(addedRoles, lang.persistent_roles.concat)
			local publicLogChannel = member.guild:getChannel(guildSettings.public_log_channel)
			utils.sendEmbed(member:getPrivateChannel(), f(lang.pl(lang.persistent_roles.you_roles_given, #addedRoles), member.guild.name, addedRolesStr), "ffff00")
			utils.sendEmbedSafe(publicLogChannel, f(lang.pl(lang.persistent_roles.user_roles_given, #addedRoles), utils.name(member.user, member.guild), addedRolesStr), "ffff00")
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}