local discordia = require("discordia")
local json = require("json")
local options = require("../options")

local utils = {}

utils.escapePatterns = function(str)
	return str:gsub("([^%w])", "%%%1")
end

utils.createLookupTable = function(input)
	local output={}
	for _,v in pairs(input) do
		output[v]=true
	end
	return output
end

local jsonColumns=utils.createLookupTable{
	"disabled_commands",
	"disabled_modules",
	"persistent_roles",
	"command_permissions",
	"roles"
}
local booleanColumns=utils.createLookupTable{
	"delete_command_messages",
	"is_active"
}

utils.secondsToTime = function(seconds)
	local function s(num)
		if num=="01" then return "" end return "s"
	end
	local function t(num)
		if num:match("%d")=="0" then num=num:sub(2,2) end
		return num
	end
	local seconds = tonumber(seconds)
	if seconds<=0 then
		return "N/A"
	else
		days=string.format("%02.f", math.floor(seconds/86400))
		hours=string.format("%02.f", math.floor(seconds/3600 - days*24))
		mins=string.format("%02.f", math.floor(seconds/60 - days*1440 - hours*60))
		secs=string.format("%02.f", math.floor(seconds - days*86400 - hours*3600 - mins*60))
		local returnString=""
		if t(days)~="0" then returnString=returnString..t(days).." day"..s(days)..", " end
		if t(hours)~="0" then returnString=returnString..t(hours).." hour"..s(hours)..", " end
		if t(mins)~="0" then returnString=returnString..t(mins).." minute"..s(mins)..", " end
		if t(secs)~="0" then returnString=returnString..t(secs).." second"..s(secs) end
		returnString=returnString:gsub("%, $","")
		return returnString
	end
end

utils.formatRow = function(row)
	if type(row)~="table" then return end
	for k,v in pairs(row) do
		v=v[1]
		if jsonColumns[k] then
			v=json.decode(v)
		elseif booleanColumns[k] then
			v=v==1LL
		end
		row[k]=v
	end
	return row
end

utils.getGuildSettings = function(id, conn)
	local settings,_ = conn:exec("SELECT * FROM guild_settings WHERE guild_id="..id..";","k")
	return utils.formatRow(settings)
end

utils.sendEmbed = function(channel, text, color, footer_text, footer_icon, messageContent)
	local colorValue=color and discordia.Color.fromHex(color).value or nil
	local msg=channel:send{
		content=messageContent,
		embed={
			description=text,
			color=colorValue,
			footer={
				text=footer_text,
				icon_url=footer_icon
			}
		}
	}
	return msg
end

utils.sendEmbedSafe = function(channel, text, color, footer_text, footer_icon, messageContent)
	if not channel then return false end
	return utils.sendEmbed(channel, text, color, footer_text, footer_icon, messageContent)
end

utils.logError = function(guild, err)
	return guild.client.owner:send{
		embed = {
			title = "Bot crashed!",
			description = "```\n"..err.."```",
			color = discordia.Color.fromHex("ff0000").value,
			timestamp = discordia.Date():toISO('T', 'Z'),
			footer = {
				text = "Guild: "..guild.name.." ("..guild.id..")"
			}
		}
	}
end

utils.name = function(user, guild)
	if guild then
		local member = guild:getMember(user.id)
		if member then
			return member.name.."#"..user.discriminator
		end
	end
	return user.tag
end

utils.memberFromString = function(str, guild)
	local id = str:match("^%<%@%!?(%d+)%>$") or str:match("^(%d+)$")
	if not id then return end
	return guild:getMember(id)
end

utils.userFromString = function(str, client)
	local id = str:match("^%<%@%!?(%d+)%>$") or str:match("^(%d+)$")
	if not id then return end
	return client:getUser(id)
end

utils.channelFromString = function(str, client)
	local id = str:match("^%<%#(%d+)%>$") or str:match("^(%d+)$")
	if not id then return end
	return client:getChannel(id)
end

utils.roleFromString = function(str, guild)
	local id = str:match("^%<%@%&(%d+)%>$") or str:match("^(%d+)$")
	if not id then return end
	return guild:getRole(id)
end

utils.s = function(num)
	return num==1 and "" or "s"
end

return utils