local utils = require("miscUtils")
local commandHandler = require("commandHandler")

local muteUtils = {}

-- returns: success, err, mutedRole
-- true, nil, mutedRole if mute can proceed
-- false, err, nil otherwise
muteUtils.checkValidMute = function(muteMember, muteUser, guild, guildSettings, lang)
	local selfMember = guild:getMember(guild.client.user.id)
	if not guildSettings.muted_role then
		return false, f(lang.error.setting_not_set, "muted_role")
	end
	local mutedRole = guild:getRole(guildSettings.muted_role)
	if not mutedRole then
		return false, f(lang.error.setting_object_gone, "muted_role")
	elseif muteUser.bot then
		return false, lang.error.user_is_bot
	elseif not selfMember:hasPermission("manageRoles") then
		return false, f(lang.error.missing_bot_permission_2, "manageRoles")
	elseif selfMember.highestRole.position<=mutedRole.position then
		return false, f(lang.error.bot_below_role, selfMember.highestRole.mentionString, mutedRole.mentionString)
	elseif muteMember and muteMember:hasPermission("administrator") then
		return false, f(lang.error.user_has_permission, "administrator")
	end
	return true, nil, mutedRole
end

-- returns: success
-- true if muted
-- false otherwise
muteUtils.checkIfMuted = function(muteMember, muteUser, mutedRole, guild, conn)
	if not muteMember then
		local entry, _ = conn:exec('SELECT * FROM mutes WHERE guild_id = "'..guild.id..'" AND user_id = "'..muteUser.id..'";')
		if entry then
			return true
		end
	elseif muteMember:hasRole(mutedRole.id) then
		return true
	end
	return false
end

-- returns: nothing
muteUtils.deleteEntry = function(guild, muteUser, conn)
	conn:exec("DELETE FROM mutes WHERE guild_id = '"..guild.id.."' AND user_id = '"..muteUser.id.."';")
end

-- returns: success, err
-- true, nil if mute succeeds
-- false, err otherwise
muteUtils.mute = function(muteMember, muteUser, mutedRole, guild, conn, length)
	muteUtils.deleteEntry(guild, muteUser, conn)
	local stmt = conn:prepare("INSERT INTO mutes (guild_id, user_id, length, end_timestamp, is_active) VALUES (?, ?, ?, ?, ?);")
	stmt:reset():bind(guild.id, muteUser.id, length, os.time()+length, (muteMember and 1 or 0)):step()
	stmt:close()
	if muteMember then
		local success, err = muteMember:addRole(mutedRole.id)
		if not success then
			return false, err
		end
	end
	return true
end

-- returns: success, err
-- true, nil if mute succeeds
-- false, err otherwise
muteUtils.remute = function(muteMember, muteUser, mutedRole, guild, conn, length)
	local stmt = conn:prepare("UPDATE mutes SET is_active = 1, end_timestamp = ? WHERE guild_id = ? AND user_id = ?;")
	stmt:reset():bind(os.time()+length, guild.id, muteUser.id):step()
	stmt:close()
	if muteMember then
		local success, err = muteMember:addRole(mutedRole.id)
		if not success then
			return false, err
		end
	end
	return true
end

-- returns: success, err
-- true, nil if unmute succeeds
-- false, err otherwise
muteUtils.unmute = function(muteMember, muteUser, mutedRole, guild, conn)
	muteUtils.deleteEntry(guild, muteUser, conn)
	if muteMember then
		local success, err = muteMember:removeRole(mutedRole.id)
		if not success then
			return false, err
		end
	end
	return true
end

return muteUtils