local json = require("json")

return {
	name = "persistent-roles-leave",
	visible = false,
	disabledByDefault = false,
	run = function(self, guildSettings, lang, member, conn)
		local persistent_roles = {}
		for role in member.roles:iter() do
			if guildSettings.persistent_roles[role.id] then
				table.insert(persistent_roles, role.id)
			end
		end
		if #persistent_roles==0 then return end
		local stmt = conn:prepare("INSERT INTO persistent_roles (guild_id, user_id, roles) VALUES (?, ?, ?);")
		stmt:reset():bind(member.guild.id, member.id, json.encode(persistent_roles)):step()
		stmt:close()
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}