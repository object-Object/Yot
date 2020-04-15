local utils = require("./miscUtils")
local commandHandler = require("./commandHandler")

local warnUtils = {}

-- returns: success, err
-- true, nil if kick can proceed
-- false, err otherwise
warnUtils.checkValidKick = function(kickMember, guild)
	local selfMember = guild:getMember(guild.client.user.id)
	if not selfMember:hasPermission("kickMembers") then
		return false, "Yot does not have the `kickMembers` permission."
	elseif not kickMember then
		return false, "they are not in this server."
	elseif selfMember.highestRole.position<=kickMember.highestRole.position then
		return false, "Yot's highest role is not higher than their highest role."
	elseif kickMember.id==guild.ownerId then
		return false, "they are the server owner."
	end
	return true
end

-- returns: success, err
-- true, nil if kick can proceed
-- false, err otherwise
warnUtils.checkValidBan = function(banMember, guild)
	local selfMember = guild:getMember(guild.client.user.id)
	if not selfMember:hasPermission("banMembers") then
		return false, "Yot does not have the `banMembers` permission."
	elseif banMember and selfMember.highestRole.position<=banMember.highestRole.position then
		return false, "Yot's highest role is not higher than their highest role."
	elseif banMember and banMember.id==guild.ownerId then
		return false, "they are the server owner."
	end
	return true
end

-- returns: success, err, entry, doKick, doBan
-- true, nil, entry, false, false if normal warn and works
-- false, err, nil, nil, nil if warn fails
-- true, nil, entry, true, false if reached kick threshold
-- true, nil, entry, false, true if reached ban threshold
warnUtils.warn = function(warnMember, warnUser, guild, guildSettings, conn)
	if warnUser.bot then
		return false, "they are a bot."
	end
	local entry, _ = conn:exec('SELECT * FROM warnings WHERE guild_id = "'..guild.id..'" AND user_id = "'..warnUser.id..'";')
	if entry then
		entry = utils.formatRow(entry)
		entry.level = entry.level+1
		entry.end_timestamp = os.time()+guildSettings.warning_length
		local stmt = conn:prepare("UPDATE warnings SET level = ?, end_timestamp = ? WHERE guild_id = ? AND user_id = ?;")
		stmt:reset():bind(entry.level, entry.end_timestamp, guild.id, warnUser.id):step()
		stmt:close()
	else
		entry = {
			level=1,
			end_timestamp=os.time()+guildSettings.warning_length,
			is_active=(warnMember and true or false)
		}
		local stmt = conn:prepare("INSERT INTO warnings (guild_id, user_id, level, end_timestamp, is_active) VALUES (?, ?, ?, ?, ?);")
		stmt:reset():bind(guild.id, warnUser.id, entry.level, entry.end_timestamp, (entry.is_active and 1 or 0)):step()
		stmt:close()
	end
	if entry.level==guildSettings.warning_kick_level then
		return true, nil, entry, true, false
	elseif entry.level==guildSettings.warning_ban_level then
		return true, nil, entry, false, true
	end
	return true, nil, entry, false, false
end

-- returns: success, err, entry
-- true, nil, entry if unwarn succeeds
-- false, err, nil otherwise
warnUtils.unwarn = function(warnUser, guild, guildSettings, conn)
	if warnUser.bot then
		return false, "they are a bot."
	end
	local entry, _ = conn:exec('SELECT * FROM warnings WHERE guild_id = "'..guild.id..'" AND user_id = "'..warnUser.id..'";')
	if not entry then
		return false, "they don't have any warnings."
	end
	entry = utils.formatRow(entry)
	entry.level = entry.level-1
	if entry.level==0 then
		entry.end_timestamp = 0
		local stmt = conn:prepare("DELETE FROM warnings WHERE guild_id = ? AND user_id = ?;")
		stmt:reset():bind(guild.id, warnUser.id):step()
		stmt:close()
	else
		entry.end_timestamp = os.time()+guildSettings.warning_length
		local stmt = conn:prepare("UPDATE warnings SET level = ?, end_timestamp = ? WHERE guild_id = ? AND user_id = ?;")
		stmt:reset():bind(entry.level, entry.end_timestamp, guild.id, warnUser.id):step()
		stmt:close()
	end
	return true, nil, entry
end

return warnUtils