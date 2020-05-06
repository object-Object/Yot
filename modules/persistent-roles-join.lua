local utils = require("miscUtils")

return {
	name = "persistent-roles-join",
	description = "Give back persistent roles when users join who had the roles when they left.",
	visible = false,
	event = "client.memberJoin",
	disabledByDefault = false,
	run = function(self, guildSettings, member, conn)
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
			local addedRolesStr = table.concat(addedRoles, ", ")
			local publicLogChannel = member.guild:getChannel(guildSettings.public_log_channel)
			utils.sendEmbed(member:getPrivateChannel(), "You have been given back the following role"..utils.s(#addedRoles).." in **"..member.guild.name.."**: "..addedRolesStr..".", "00ff00")
			utils.sendEmbedSafe(publicLogChannel, utils.name(member.user, member.guild).." has been given back the following role"..utils.s(#addedRoles)..": "..addedRolesStr..".", "00ff00")
		end
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}