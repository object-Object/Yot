local warnUtils = require("../warnUtils")
local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")
local options = require("../options")
local http = require("coro-http")
local timer = require("timer")

local timeout = false

return {
	name = "youtube-anti-ad",
	description = "Deletes messages containing YouTube video links in which the video uploader's name matches the user's, and warns the users who posted them. A role ignored by this module may be set using the `advertising_allowed_role` setting.",
	visible = true,
	event = "client.messageCreate",
	disabledByDefault = true,
	run = function(self, guildSettings, message, conn)
		local member = message.guild:getMember(message.author.id)
		local name = utils.name(message.author, message.guild)
		if guildSettings.advertising_allowed_role and member:hasRole(guildSettings.advertising_allowed_role) then
			return
		end
		
		local url

		if message.content:lower():match("youtube.com/watch%?v=%S") then
			local lowContent=message.content:lower()
			local _,_,lowerCaseUrl=lowContent:find("youtube.com/watch%?v=([a-zA-Z0-9_%-]+)")
			local start,stop=lowContent:find(lowerCaseUrl,1,true)
			url=message.content:sub(start,stop)
		elseif message.content:lower():match("youtu%.be/%S") then
			local lowContent=message.content:lower()
			local _,_,lowerCaseUrl=lowContent:find("youtu%.be/([a-zA-Z0-9_%-]+)")
			local start,stop=lowContent:find(lowerCaseUrl,1,true)
			url=message.content:sub(start,stop)
		end
		if not url then return end

		local _,body=http.request("GET","https://www.googleapis.com/youtube/v3/videos?id="..url.."&part=snippet&key="..options.youtubeAPIKey)
		local channelID=body:match('"channelId": "(%S+)"')
		if not channelID then return end
		local res,body=http.request("GET","https://www.googleapis.com/youtube/v3/channels?id="..channelID.."&part=snippet&key="..options.youtubeAPIKey)
		local authorName=body:match('"title": (%b"")'):gsub('"',""):lower()
		if not authorName or not (
			member.name:lower():find(authorName,1,true) 
			or member.username:lower():find(authorName,1,true) 
			or authorName:find(member.name:lower(),1,true) 
			or authorName:find(member.username:lower(),1,true)
		) then return end

		message:delete()

		if timeout then return end
		timeout=true
		timer.setTimeout(1000, function() timeout=false end)

		local warnSuccess, warnErr, entry, doKick, doBan = warnUtils.warn(member, message.author, message.guild, guildSettings, conn)
		if not warnSuccess then
			utils.sendEmbed(message.channel, name.." could not be automatically warned because "..warnErr, "ff0000")
			return
		end

		local reason = " (Reason: Advertising is not allowed on this server!)"

		local staffLogChannel = guildSettings.staff_log_channel and message.guild:getChannel(guildSettings.staff_log_channel)

		if doKick then
			local kickValid, kickErr = warnUtils.checkValidKick(member, message.guild)
			if kickValid then
				local kickedDM = utils.sendEmbed(message.author:getPrivateChannel(), "You have been kicked from **"..message.guild.name.."** for automatically reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "ffff00")
				local success, err = member:kick()
				if not success then
					-- kick failed, so continue with normal warn messages
					if kickedDM then kickedDM:delete() end
					utils.sendEmbed(message.channel, name.." could not be kicked for automatically reaching "..entry.level.." warning"..utils.s(entry.level)..": `"..err.."`. Please report this error to the bot developer by sending Yotogi a direct message.", "ff0000")
				else
					-- kick succeeded, exit early
					local text = name.." has been kicked for automatically reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason
					utils.sendEmbed(message.channel, text, "ffff00")
					utils.sendEmbedSafe(staffLogChannel, text, "ffff00", "Responsible user: "..utils.name(message.client.user, message.guild))
					return
				end
			else
				-- kick invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, name.." could not be kicked for automatically reaching "..entry.level.." warning"..utils.s(entry.level).." because "..kickErr, "ff0000")
			end
		elseif doBan then
			local banValid, banErr = warnUtils.checkValidBan(member, message.guild)
			if banValid then
				local bannedDM = utils.sendEmbed(message.author:getPrivateChannel(), "You have been banned from **"..message.guild.name.."** for automatically reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason, "ffff00")
				local success, err = message.guild:banUser(message.author.id)
				if not success then
					-- ban failed, so continue with normal warn messages
					if bannedDM then bannedDM:delete() end
					utils.sendEmbed(message.channel, name.." could not be banned for automatically reaching "..entry.level.." warning"..utils.s(entry.level)..": `"..err.."`. Please report this error to the bot developer by sending Yotogi a direct message.", "ff0000")
				else
					-- ban succeeded, exit early
					local text = name.." has been banned for automatically reaching "..entry.level.." warning"..utils.s(entry.level).."."..reason
					utils.sendEmbed(message.channel, text, "ffff00")
					utils.sendEmbedSafe(staffLogChannel, text, "ffff00", "Responsible user: "..utils.name(message.client.user, message.guild))
					return
				end
			else
				-- ban invalid, so continue with normal warn messages
				utils.sendEmbed(message.channel, name.." could not be banned for automatically reaching "..entry.level.." warning"..utils.s(entry.level).." because "..banErr, "ff0000")
			end
		end

		local warnFooter = commandHandler.strings.warnFooter(guildSettings, entry)

		utils.sendEmbed(message.author:getPrivateChannel(), "You have been automatically warned in **"..message.guild.name.."**. You now have "..entry.level.." warning"..utils.s(entry.level).."."..reason, "ffff00", warnFooter)
		local text = name.." has been automatically warned. They now have "..entry.level.." warning"..utils.s(entry.level).."."..reason
		utils.sendEmbed(message.channel, text, "ffff00", warnFooter)
		utils.sendEmbedSafe(staffLogChannel, text, "ffff00", "Responsible user: "..utils.name(message.client.user, message.guild).."\n"..warnFooter)
	end,
	onEnable = function(self, message, guildSettings, conn)
		return true
	end,
	onDisable = function(self, message, guildSettings, conn)
		return true
	end
}