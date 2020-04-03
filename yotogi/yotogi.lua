--[[

Remember to update the changelog!

]]

local discordia = require('discordia')
local discordiaOptions = {cacheAllMembers=true}
local client = discordia.Client(discordiaOptions)
local clock = discordia.Clock()
local http = require('coro-http')
local parse = require('url').parse
local timer = require('timer')
local qs = require('querystring')
local pp = require('pretty-print')
local fs = require("fs")
discordia.extensions.string()
discordia.extensions.table()

local timeout=false

local f=io.open("settings","r")
local settings=f:read("*a"):split("%s")
f:close()

local persistRoles={
	"315517372666609677", --100K HYPE
	"517387293930029056", --500K HYPE
	"394224494207565824", --2017
	"517387385760120854", --2018
	"510492547131506692", --voice-banned
	"505410557902323742", --persist2
	"505410445520142346", --persist1
	"268843390467178496", --donator
}
	
local token=settings[1]
local prefix=settings[2]
local youtubeAPIKey=settings[3]
local icons={"https://i.imgur.com/Nasd4Zu.jpg","https://i.imgur.com/E4gkEdu.jpg","https://i.imgur.com/c8tw60A.jpg","https://i.imgur.com/xegOTLd.jpg"}
local starEmojis={[1]="⭐️",[5]="🌟",[10]="💫"}
local suggestionsEmojis={"👍","🤷","👎"}
local toggles={}
toggles["ban_messages"]="ban_messages.toggle"
toggles["starboard"]="starboard.toggle"
toggles["starboard_remove"]="starboard_remove.toggle"
toggles["suggestions"]="suggestions.toggle"
toggles["status"]="status.toggle"
local denies={}
denies["suggest"]={"denied-suggest","send messages in the suggestions channel"}
denies["star-messages"]={"denied-star-messages","add new reactions to messages, including :star:"}
denies["view-warnings"]={"denied-view-warnings","use the `$warnings` command"}

function set (list)
	local set = {}
	for _,l in ipairs(list) do set[l]=true end
	return set
end

function table.removeKey(table, key)
	local element = table[key]
	table[key] = nil
	return element
end

function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function table.keyByValue(table, element)
  for key, value in pairs(table) do
    if value == element then
      return key
    end
  end
  return false
end

function get(object,name)
	local found = object:find(function(r) return r.name == name end)
	return found
end

function warnDownload()
	f=nil
	f=io.open("warnings.txt","r")
	warnTable={}
	for line in f:lines() do
		local temp=string.split(line,"%s")
		if temp[4] and tonumber(temp[3])>0 then warnTable[temp[1]]={temp[2],temp[3],temp[4]} end
	end
end

function warnUpdate(input)
	f=io.open("warnings.txt","w")
	f:write(input)
	f:close()
	warnDownload()
	local aWarningNum=0
	local iWarningNum=0
	for k,v in pairs(warnTable) do if v[3]~="false" then aWarningNum=aWarningNum+1 else iWarningNum=iWarningNum+1 end end
    aWarningNum=tostring(aWarningNum)
    iWarningNum=tostring(iWarningNum)
    if not io.open("status.toggle","r") then
        client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
    end
end

function getWarnPrint()
	local warnPrint=""
	for k,v in pairs(warnTable) do
		if v[2]~=0 then warnPrint=warnPrint..k.." "..v[1].." "..v[2].." "..v[3].."\n" end
	end
	return warnPrint
end

function muteDownload()
	f=nil
	f=io.open("mutes.txt","r")
	muteTable={}
	for line in f:lines() do
		local temp=string.split(line,"%s")
		if temp[4] and tonumber(temp[3])>0 then muteTable[temp[1]]={temp[2],temp[3],temp[4]} end
	end
end

function muteUpdate(input)
	f=io.open("mutes.txt","w")
	f:write(input)
	f:close()
	muteDownload()
end

function getMutePrint()
	local mutePrint=""
	for k,v in pairs(muteTable) do
		mutePrint=mutePrint..k.." "..v[1].." "..v[2].." "..v[3].."\n"
	end
	return mutePrint
end

function starDownload()
	f=nil
	f=io.open("starred.txt","r")
	starTable={}
	for line in f:lines() do
		local temp=string.split(line,"%s")
		if temp[2] then table.insert(starTable,{temp[1],temp[2]}) end
	end
end

function starUpdate(input)
	f=io.open("starred.txt","w")
	f:write(input)
	f:close()
	starDownload()
end

function getStarPrint()
	local starPrint=""
	for k,v in ipairs(starTable) do
		if v[2] then starPrint=starPrint..v[1].." "..v[2].."\n" end
	end
	return starPrint
end

function persistDownload()
	f=io.open("persist.txt","r")
	persistTable={}
	for line in f:lines() do
		local temp=string.split(line,"%s")
		local temp2=temp
		table.remove(temp2,temp2[1])
		if temp[2] then
			persistTable[temp[1]]=temp2
		end
	end
end

function persistUpdate(input)
	f=io.open("persist.txt","w")
	f:write(input)
	f:close()
	persistDownload()
end

function getPersistPrint()
	local persistPrint=""
	for k,v in pairs(persistTable) do
		persistPrint=persistPrint..k
		for j,u in pairs(v) do
			persistPrint=persistPrint.." "..u
		end
		persistPrint=persistPrint.."\n"
	end
	return persistPrint
end

function hasPermission(member,...)
	if not member then return end
	if member.user==member.guild.owner then return true end
	for role in member.roles:iter() do
		if role:getPermissions():has(...) or role:getPermissions():has("administrator") then
			return true
		end
	end
end

function highestRole(member)
	if not member then return end
	highRole=member.guild.defaultRole
	if member.roleCount==0 then return highRole end
	for role in member.roles:iter() do
		if role.position>highRole.position then highRole=role end
	end
	return highRole
end

function banned(member,guild)
	print(member,guild)
	for ban in guild:getBans():iter() do
		if ban.user.id==member.id then return true end
	end
	return false
end

function read(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

local function strToNum(str)
    local year, month, day, hour, min, sec, msec = str:match(
        '(%d*)-(%d*)-(%d*)T(%d*):(%d*):(%d*)%.?(%d*)+00:00'
    )
    local t = os.time({
        day = day, month = month, year = year,
        hour = hour, min = min, sec = sec,
    })
    local d = os.date('!*t')
    d.isdst = os.date('*t', t).isdst
    t = os.difftime(t, os.time(d)) + os.time()
    local n = #msec
    return n > 0 and t + msec / 10 ^ n or t
end

function secondsToClock(seconds)
	local seconds = tonumber(seconds)
	if seconds<=0 then
		return "00:00:00"
	else
		hours=string.format("%02.f", math.floor(seconds/3600))
		mins=string.format("%02.f", math.floor(seconds/60 - (hours*60)))
		secs=string.format("%02.f", math.floor(seconds - hours*3600 - mins*60))
		return hours..":"..mins..":"..secs
	end
end

function secondsToClock2(seconds)
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

function getSeconds(num,mod)
	local modifiers={}
	modifiers["m"]=60
	modifiers["h"]=3600
	modifiers["d"]=86400
	modifiers["w"]=604800
	if not num or not mod or not modifiers[mod] then num,mod=0,0 else num,mod=tonumber(num),modifiers[mod] end
	local output=num*mod
	return output
end

function printLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = tostring(select(i, ...))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

function prettyLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = pp.strip(pp.dump(select(i, ...)))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

function code(str)
	return string.format('```\n%s```', str)
end

function exec(arg, msg)

	if not arg then return end
	if msg.author ~= msg.client.owner then msg:reply("Insufficient permissions.") return end

	arg = arg:gsub('```\n?', '')

	local lines = {}
	local iolines = {}

	local sandbox = table.copy(_G, localtable)
	sandbox.message = msg
	sandbox.client = msg.client
	sandbox.guild = msg.guild
	sandbox.channel = msg.channel
	sandbox.timer = timer
	sandbox.qs = qs
	sandbox.discordia = discordia
	sandbox.warnTable = warnTable
	sandbox.read = read
	sandbox.strToNum = strToNum
	sandbox.secondsToClock = secondsToClock
	sandbox.secondsToClock2 = secondsToClock2
	sandbox.sendEmbed = sendEmbed
	sandbox.rules = rules
	sandbox.http = http
	sandbox.getSeconds = getSeconds
	sandbox.get = get
	sandbox.timeout = timeout
	
	sandbox.io.write = function(...)
		table.insert(iolines, printLine(...))
	end

	sandbox.print = function(...)
		table.insert(lines, printLine(...))
	end

	sandbox.p = function(...)
		table.insert(lines, prettyLine(...))
	end

	local fn, syntaxError = load(arg, 'DiscordBot', 't', sandbox)
	if not fn then return msg:reply(code(syntaxError)) end

	local success, runtimeError = pcall(fn)
	if not success then return msg:reply(code(runtimeError)) end

	lines = table.concat(lines, '\n')
	iolines = table.concat(iolines)

	if #lines > 1990 then
		local file=io.open("temp.txt","w")
		file:write(lines)
		file:close()
		msg:reply{content="Output is too large. See attached file.",file="temp.txt"}
		os.execute("rm temp.txt")
		return
	end
	if #iolines > 1990 then
		local file=io.open("temp.txt","w")
		file:write(lines)
		file:close()
		msg:reply{content="Output is too large. See attached file.",file="temp.txt"}
		os.execute("rm temp.txt")
		return
	end

	if lines~="" then return msg:reply(code(lines)) end
	if iolines~="" then return msg:reply(iolines) end

end

function match2(text,phrase)
	local text=text:gsub("%p",""):lower()
	if text:match("^"..phrase.."%s+") or text:match("%s+"..phrase.."%s+") or text:match("%s+"..phrase.."$") or text:match("^"..phrase.."$") then return true else return false end
end

function isDenied(member,key)
	if denies[key] then
		local role=get(member.guild.roles,denies[key][1])
		if role and member:hasRole(role) then
			return true
		end
	end
end

function sendEmbed(channel,arg,footer_text,footer_icon)
	if not channel or not arg then return end
	local msg=channel:send{
		embed={
			description=arg,
			color=discordia.Color.fromRGB(255,0,0).value,
			footer={
				text=footer_text,
				icon_url=footer_icon
			}
		}
	}
	return msg
end

function sendUsage(user,command,arg)
	if not user or not command or not arg then return end
	local msg=user:send{
		embed={
			description="**Usage for "..command..":**```\n"..command.." "..arg.."```",
			color=discordia.Color.fromRGB(255,0,0).value,
			footer={
				text="Angled brackets represent required arguments. Square brackets represent optional arguments. Do not include the brackets in the command."
			}
		}
	}
	return msg
end

crashCount=0
function logError(title,section,error)
	if not error then error="" end
	client.owner:send{
		embed={
			title=title,
			description="```\nSection: "..section.."\n"..error.."```",
			color=discordia.Color.fromRGB(255,0,0).value
		}
	}
	print("Error:",error)
	prevTime=prevTime or os.time()
	if os.time()-prevTime<=10 then crashCount=crashCount+1 else crashCount=0 end
	if crashCount>=3 then
		client.owner:send{
			embed={
				title="Bot stopping!",
				description="```\nToo many errors```",
				color=discordia.Color.fromRGB(255,0,0).value
			}
		}
		client:stop()
		os.exit()
	end
end

warnDownload()
muteDownload()
starDownload()
persistDownload()

client:on("ready", function()
    p("Logged in! Prefix: "..prefix)
    local aWarningNum=0
	local iWarningNum=0
	for k,v in pairs(warnTable) do if v[3]~="false" then aWarningNum=aWarningNum+1 else iWarningNum=iWarningNum+1 end end
    aWarningNum=tostring(aWarningNum)
    iWarningNum=tostring(iWarningNum)
    if not io.open("status.toggle","r") then
        client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
    end
end)

client:on('guildAvailable', function(guild)
	print("Guild available.\n "..guild.name.."\n ID: "..guild.id)
end)

client:on('guildCreate', function(guild)
	print("Added to guild.\n "..guild.name)
	client.owner:send("Added to guild.\n "..guild.name)
end)


client:on('guildDelete', function(guild)
	print("Kicked from guild.\n "..guild.name)
	client.owner:send("Kicked from guild.\n "..guild.name)
end)

client:on('guildUnavailable', function(guild)
	print("Guild unavailable.\n "..guild.name)
	client.owner:send("Guild unavailable.\n "..guild.name)
end)

clock:on("min", function()
local pc,err=pcall(function()
	if not muteTable then return end
	for k,v in pairs(muteTable) do
		if v[3]~="false" then
			local guild=client:getGuild(v[3])
			if guild then
				local channel=get(guild.textChannels,"general")
				if channel then
					local member=guild:getMember(k)
					if not member then 
						if banned(k,guild) then
							table.removeKey(muteTable,k)
							muteUpdate(getMutePrint())
						elseif not client:getUser(k) then
							table.removeKey(muteTable,k)
							muteUpdate(getMutePrint())
						else
							v[3]="false"
							muteUpdate(getMutePrint())
						end 
					else
						local role=get(guild.roles,"Muted")
						if role then
							if tonumber(v[1])<=os.time() then
								if member then
									member:removeRole(role)
									channel:send{embed={description=member.name.." has been automatically unmuted.",color=discordia.Color.fromRGB(255,0,0).value},content=member.mentionString}
									local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
									if logChannel then sendEmbed(logChannel,member.name.." has been automatically unmuted.") end
									table.removeKey(muteTable,k)
									muteUpdate(getMutePrint())
								end
							end
						end
					end
				end
			end
		end
	end
end)
if not pc then logError("Bot crashed!","First clock:on",err) end
end)

clock:on("min", function(date)
local pc,err=pcall(function()
	if not warnTable then return end
	local m=os.date("%M")
-- 	if (m % 10 == 0) then
		warnPrint=""
		for k,v in pairs(warnTable) do
			if tonumber(v[2])<=0 then 
				table.removeKey(warnTable,k)
				warnUpdate(getWarnPrint())
			elseif v[3]~="false" then
				local guild=client:getGuild(v[3])
				if guild then
					local channel=get(guild.textChannels,"general")
					if channel then
						local member=guild:getMember(k)
						if not member then 
							if banned(k,guild) then
								table.removeKey(warnTable,k)
								warnUpdate(getWarnPrint())
							elseif not client:getUser(k) then
								table.removeKey(warnTable,k)
								warnUpdate(getWarnPrint())
							else
								v[3]="false"
								warnUpdate(getWarnPrint())
							end
						else
							if tonumber(v[2])>=4 and tonumber(v[2])<100 then
								user=member.user
								table.removeKey(warnTable,k)
								sendEmbed(user:getPrivateChannel(),"You have been banned from #TeamRuby for exceeding the warn limit.")
								sendEmbed(channel,user.name.." has been automatically banned for exceeding the warn limit.")
								member:ban()
								local logChannel=get(guild.textChannels,"nsfw-lurkchannel")
								if logChannel then sendEmbed(logChannel,user.name.." has been automatically banned for exceeding the warn limit.") end
							else
								local role=get(guild.roles,"WARNING "..v[2])
								if role then
									if tonumber(v[1])<=os.time() then
										if member then
											v[2]=tonumber(v[2])-1
											member:removeRole(role)
											if tonumber(v[2])>0 then v[1]=os.time()+604800 end
											channel:send{embed={description=member.name.."'s warning level has been automatically decreased to "..v[2]..".",color=discordia.Color.fromRGB(255,0,0).value,footer={text="Time until warning level is decreased: "..secondsToClock2(tonumber(v[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(v[2])..".",icon_url=icons[tonumber(v[2])+1]}},content=member.mentionString}
											local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
											if logChannel then sendEmbed(logChannel,member.name.."'s warning level has been automatically decreased to "..v[2]..".") end
											if tonumber(v[2])<=0 then table.removeKey(warnTable,k) end
											warnUpdate(getWarnPrint())
										end
									end
								end
							end
						end
					end
				end
			end
 		end
--	end
end)
if not pc then logError("Bot crashed!","Second clock:on",err) end
end)

clock:on("min", function(date)
local pc,err=pcall(function()
	if not warnTable then return end
	if date.min % 5 == 0 then
		local aWarningNum=0
		local iWarningNum=0
		for k,v in pairs(warnTable) do if v[3]~="false" then aWarningNum=aWarningNum+1 else iWarningNum=iWarningNum+1 end end
		aWarningNum=tostring(aWarningNum)
		iWarningNum=tostring(iWarningNum)
	    if not io.open("status.toggle","r") then
		    client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
	    else
	        client:setStatus(online)
	    end
	end
end)
if not pc then logError("Bot crashed!","Third clock:on",err) end
end)

client:on("memberJoin", function(member)
local pc,err=pcall(function()
	if not warnTable then return end
	if warnTable[member.id] then
		entry=warnTable[member.id]
		if tonumber(entry[2])>0 then
			entry[3]=member.guild.id
			entry[1]=os.time()+604800
			for i=1, tonumber(entry[2]) do
				local role=get(member.guild.roles,"WARNING "..i)
				if role then member:addRole(role) end
			end
			local channel=get(member.guild.textChannels,"general")
			if channel then sendEmbed(channel,member.name.."'s warning level has been automatically re-increased to "..entry[2]..".","Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end
			warnTable[member.id]=entry
			warnUpdate(getWarnPrint())
		end
	end
	if not muteTable then return end
	if muteTable[member.id] then
		entry=muteTable[member.id]
		entry[3]=member.guild.id
		entry[1]=os.time()+entry[2]
		local role=get(member.guild.roles,"Muted")
		if role then
			member:addRole(role)
			local channel=get(member.guild.textChannels,"general")
			if channel then sendEmbed(channel,member.name.." has been automatically re-muted for "..secondsToClock2(entry[2])..".") end
		else
			client.owner:send("Error: muted role not found in "..member.guild.name..".")
		end
		muteTable[member.id]=entry
		muteUpdate(getMutePrint())
	end
	if not persistTable then return end
	if persistTable[member.id] then
		local function s(num)
			if num==1 then return "" else return "s" end
		end
		local rolesGiven = ""
		local roleCount = 0
		for k,v in pairs(persistTable[member.id]) do
			local role=member.guild:getRole(v)
			if role then 
				member:addRole(role)
				rolesGiven = rolesGiven..role.name..", "
				roleCount = roleCount + 1
			end
		end
		rolesGiven = rolesGiven:sub(1,#rolesGiven-2)
		local channel = get(member.guild.textChannels,"general")
		if channel then sendEmbed(channel,member.name.." has been given back the following role"..s(roleCount)..": "..rolesGiven..".") end
		persistTable[member.id]=nil
		persistUpdate(getPersistPrint())
	end
end)
if not pc then logError("Bot crashed!","memberJoin",err) end
end)

client:on("memberLeave", function(member)
local pc,err=pcall(function()
	if banned(member,member.guild) then return end
	if not warnTable then return end
	if warnTable[member.id] then
		entry=warnTable[member.id]
		entry[3]="false"
		warnTable[member.id]=entry
		warnUpdate(getWarnPrint())
	end
	if not muteTable then return end
	if muteTable[member.id] then
		entry=muteTable[member.id]
		entry[3]="false"
		muteTable[member.id]=entry
		muteUpdate(getMutePrint())
	end
	if not persistTable then return end
	local persists={}
	for r in member.roles:iter() do
		for k,v in pairs(persistRoles) do
			if r.id==v then table.insert(persists,r.id) end
		end
	end
	if persists[1] then
		persistTable[member.id]=persists
		persistUpdate(getPersistPrint())
	end
end)
if not pc then logError("Bot crashed!","memberLeave",err) end
end)

client:on("userBan", function(user,guild)
local pc,err=pcall(function()
	local channel=get(guild.textChannels,"general")
	if not io.open("ban_messages.toggle","r") and channel then sendEmbed(channel,user.name.." has been banned from "..guild.name..".") end
	if not warnTable then return end
	if warnTable[user.id] then
		table.removeKey(warnTable,user.id)
		warnUpdate(getWarnPrint())
	end
	if not muteTable then return end
	if muteTable[user.id] then
		table.removeKey(muteTable,user.id)
		muteUpdate(getMutePrint())
	end
end)
if not pc then logError("Bot crashed!","userBan",err) end
end)

client:on("reactionAdd", function(reaction)
local pc,err=pcall(function()
	if io.open("starboard.toggle","r") then return end
	if not starTable then return end
	if type(reaction.emojiName)~="string" then return end
	if string.byte(reaction.emojiName)~=string.byte(starEmojis[1]) then return end
	local message=reaction.message
	if not message.guild then return end
	if message.embed then return end
	local member = message.member
	if not member then return end
	local guild = message.guild
	local channel = message.channel
	local starChannel=get(guild.textChannels,"starboard")
	if not starChannel then return end
	if channel==starChannel then return end
	for k,v in pairs(starEmojis) do if reaction.count>=k then emoji=v end end
	emoji=emoji or starEmojis[1]
	key=nil
	for k,v in ipairs(starTable) do local temp=table.keyByValue(v,message.id) if temp then key=k end end
	if key then
		local entry=starTable[key]
		local sbMessage=starChannel:getMessage(entry[2])
		if not sbMessage then
			local sbMessage=starChannel:send{
				content=emoji.."**"..reaction.count.."**".." "..channel.mentionString,
				embed={
					author={
						name=member.name.."  ("..member.username.."#"..member.discriminator..")",
						icon_url=member.avatarUrl
					},
					description=message.content,
					image=message.attachment,
					color=discordia.Color.fromRGB(255,0,0).value
				}
			}
			if #starTable>50 then table.remove(starTable,1) end
			table.insert(starTable,{message.id,sbMessage.id})
			starUpdate(getStarPrint())
			return
		end
		sbMessage:setContent(emoji.."**"..reaction.count.."**".." "..channel.mentionString)
	else
		local sbMessage=starChannel:send{
			content=emoji.."**"..reaction.count.."**".." "..channel.mentionString,
			embed={
				author={
					name=member.name.."  ("..member.username.."#"..member.discriminator..")",
					icon_url=member.avatarUrl
				},
				description=message.content,
				image=message.attachment,
				color=discordia.Color.fromRGB(255,0,0).value
			}
		}
		if #starTable>50 then table.remove(starTable,1) end
		table.insert(starTable,{message.id,sbMessage.id})
		starUpdate(getStarPrint())
	end
end)
if not pc then logError("Bot crashed!","reactionAdd",err) end
end)

client:on("reactionAddUncached", function(channel,messageId,hash)
local pc,err=pcall(function()
	if io.open("starboard.toggle","r") then return end
	if not starTable then return end
	if hash~="\226\173\144" then return end
	if not channel then return end
	local message=channel:getMessage(messageId)
	if not message then return end
	if message.embed then return end
	local member = message.member
	if not member then return end
	local guild = message.guild
	if not guild then return end
	local starChannel=get(guild.textChannels,"starboard")
	if not starChannel then return end
	if channel==starChannel then return end
	for msgReaction in message.reactions:iter() do if type(msgReaction.emojiName)=="string" and string.byte(msgReaction.emojiName)==string.byte(starEmojis[1]) then reaction=msgReaction end end
	if not reaction then return end
	for k,v in pairs(starEmojis) do if reaction.count>=k then emoji=v end end
	emoji=emoji or starEmojis[1]
	key=nil
	for k,v in ipairs(starTable) do local temp=table.keyByValue(v,message.id) if temp then key=k end end
	if key then
		local entry=starTable[key]
		local sbMessage=starChannel:getMessage(entry[2])
		if not sbMessage then
			local sbMessage=starChannel:send{
				content=emoji.."**"..reaction.count.."**".." "..channel.mentionString,
				embed={
					author={
						name=member.name.."  ("..member.username.."#"..member.discriminator..")",
						icon_url=member.avatarUrl
					},
					description=message.content,
					image=message.attachment,
					color=discordia.Color.fromRGB(255,0,0).value
				}
			}
			if #starTable>50 then table.remove(starTable,1) end
			table.insert(starTable,{message.id,sbMessage.id})
			starUpdate(getStarPrint())
			return
		end
		sbMessage:setContent(emoji.."**"..reaction.count.."**".." "..channel.mentionString)
	else
		local sbMessage=starChannel:send{
			content=emoji.."**"..reaction.count.."**".." "..channel.mentionString,
			embed={
				author={
					name=member.name.."  ("..member.username.."#"..member.discriminator..")",
					icon_url=member.avatarUrl
				},
				description=message.content,
				image=message.attachment,
				color=discordia.Color.fromRGB(255,0,0).value
			}
		}
		if #starTable>50 then table.remove(starTable,1) end
		table.insert(starTable,{message.id,sbMessage.id})
		starUpdate(getStarPrint())
	end
end)
if not pc then logError("Bot crashed!","reactionAddUncached",err) end
end)

client:on("reactionRemove", function(reaction)
local pc,err=pcall(function()
	if io.open("starboard_remove.toggle","r") then return end
	if not starTable then return end
	if type(reaction.emojiName)~="string" then return end
	if string.byte(reaction.emojiName)~=string.byte(starEmojis[1]) then return end
	local message=reaction.message
	if not message.guild then return end
	if message.embed then return end
	local member = message.member
	if not member then return end
	local guild = message.guild
	local channel = message.channel
	local starChannel=get(guild.textChannels,"starboard")
	if not starChannel then return end
	if channel==starChannel then return end
	for k,v in pairs(starEmojis) do if reaction.count>=k then emoji=v end end
	emoji=emoji or starEmojis[1]
	key=nil
	for k,v in ipairs(starTable) do local temp=table.keyByValue(v,message.id) if temp then key=k end end
	if key then
		local entry=starTable[key]
		local sbMessage=starChannel:getMessage(entry[2])
		if not sbMessage then return end
		temp=nil
		for msgReaction in message.reactions:iter() do if string.byte(msgReaction.emojiName)==string.byte(starEmojis[1]) then temp=msgReaction end end
		if not temp or reaction.count<=0 then 
			sbMessage:delete()
			table.remove(starTable,key)
			starUpdate(getStarPrint())
		else 
			sbMessage:setContent(emoji.."**"..reaction.count.."**".." "..channel.mentionString) 
		end
	end
end)
if not pc then logError("Bot crashed!","reactionRemove",err) end
end)

client:on("reactionRemoveUncached", function(channel,messageId,hash)
local pc,err=pcall(function()
	if io.open("starboard_remove.toggle","r") then return end
	if not starTable then return end
	if hash~="\226\173\144" then return end
	if not channel then return end
	local message=channel:getMessage(messageId)
	if not message then return end
	if message.embed then return end
	local member = message.member
	if not member then return end
	local guild = message.guild
	if not guild then return end
	local starChannel=get(guild.textChannels,"starboard")
	if not starChannel then return end
	if channel==starChannel then return end
	for msgReaction in message.reactions:iter() do if type(msgReaction.emojiName)=="string" and string.byte(msgReaction.emojiName)==string.byte(starEmojis[1]) then reaction=msgReaction end end
	if not reaction then return end
	for k,v in pairs(starEmojis) do if reaction.count>=k then emoji=v end end
	emoji=emoji or starEmojis[1]
	key=nil
	for k,v in ipairs(starTable) do local temp=table.keyByValue(v,message.id) if temp then key=k end end
	if key then
		local entry=starTable[key]
		local sbMessage=starChannel:getMessage(entry[2])
		if not sbMessage then return end
		temp=nil
		for msgReaction in message.reactions:iter() do if string.byte(msgReaction.emojiName)==string.byte(starEmojis[1]) then temp=msgReaction end end
		if not temp or reaction.count<=0 then 
			sbMessage:delete()
			table.remove(starTable,key)
			starUpdate(getStarPrint())
		else 
			sbMessage:setContent(emoji.."**"..reaction.count.."**".." "..channel.mentionString) 
		end
	end
end)
if not pc then logError("Bot crashed!","reactionRemoveUncached",err) end
end)

client:on("messageCreate",function(message)
local pc,err=pcall(function()
::mcstart::
	if message.author==client.user then return end
	if message.channel.type == discordia.enums.channelType.private then 
		sendEmbed(message.channel,"Your message has been forwarded to "..client.owner.name..".")
		if message.content~="" then client.owner:send("**DM from "..message.author.name.."#"..message.author.discriminator..":**\n"..message.content) end
		if message.attachment then local res,data=http.request("GET",message.attachment.url) if res.code<300 then client.owner:send{content="**Attachment from "..message.author.name.."#"..message.author.discriminator..":** "..message.attachment.filename,file={message.attachment.filename,data}} end end
		if message.embed then client.owner:send{content="**Embed from "..message.author.name.."#"..message.author.discriminator..":**",embed=message.embed} end
		return 
	end
	local author = message.author
	local member = message.member
	if not author then return end
	if author.bot then return end
	local guild = message.guild
	local channel = message.channel
	if author.bot and author~=client.user then return end
	local cmd, arg = message.content:match('(%S+)%s+(.*)')
	cmd = cmd or message.content
	argPrint = arg or "nil"
	argTable = string.split(arg,'%s')
	
	if message.content:lower():match("discord.gg") then
		if hasPermission(member,"manageRoles") then return end
		local text=message.content:lower():gsub("discord.gg%/rubychan","")
		if not text:match("discord.gg") then return end
		message:delete()
		if timeout then return end
		timeout=true
		timer.setTimeout(4000,function() timeout=false end)
		arg=message.author.mentionString.." | Advertising is not allowed on this server!"
		cmd=prefix.."warn"
		if channel.name=="server-suggestions" and not io.open("suggestions.toggle","r") then
			local general=get(guild.textChannels,"general")
			if general then message=general:send("Match.") channel=general end
		else
			message=message:reply("Match.")
		end
	end

	if message.content:lower():match("youtube.com/watch%?v=%S") then
		if hasPermission(member,"manageRoles") then return end
		if message.channel.name=="stream-song-requests" or message.channel.name=="bot-channel" then return end
		local lowContent=message.content:lower()
		local _,_,lowerCaseUrl=lowContent:find("youtube.com/watch%?v=([a-zA-Z0-9_%-]+)")
		local start,stop=lowContent:find(lowerCaseUrl,1,true)
		if not start then print(message.content,lowerCaseUrl) end
		local url=message.content:sub(start,stop)
		local _,body=http.request("GET","https://www.googleapis.com/youtube/v3/videos?id="..url.."&part=snippet&key="..youtubeAPIKey)
		local channelID=body:match('"channelId": "(%S+)"')
		if channelID then
			local _,body=http.request("GET","https://www.googleapis.com/youtube/v3/channels?id="..channelID.."&part=snippet&key="..youtubeAPIKey)
			local authorName=body:match('"title": (%b"")'):gsub('"',""):lower()
			if authorName then
				if authorName:match("rubychan") then return end
				if message.member.name:lower():find(authorName,1,true) or message.member.username:lower():find(authorName,1,true) or authorName:find(message.member.name:lower(),1,true) or authorName:find(message.member.username:lower(),1,true) then 
					message:delete()
					arg=message.author.mentionString.." | Advertising is not allowed on this server!"
					cmd=prefix.."warn"
					if channel.name=="server-suggestions" and not io.open("suggestions.toggle","r") then
						local general=get(guild.textChannels,"general")
						if general then message=general:send("Match.") channel=general end
					else
						message=message:reply("Match.")
					end 
				end
			end
		end
	end

	if message.content:lower():match("youtu%.be/%S") then
		if hasPermission(member,"manageRoles") then return end
		if message.channel.name=="stream-song-requests" or message.channel.name=="bot-channel" then return end
		local lowContent=message.content:lower()
		local _,_,lowerCaseUrl=lowContent:find("youtu%.be/([a-zA-Z0-9_%-]+)")
		local start,stop=lowContent:find(lowerCaseUrl,1,true)
		local url=message.content:sub(start,stop)
		local _,body=http.request("GET","https://www.googleapis.com/youtube/v3/videos?id="..url.."&part=snippet&key="..youtubeAPIKey)
		local channelID=body:match('"channelId": "(%S+)"')
		if channelID then
			local _,body=http.request("GET","https://www.googleapis.com/youtube/v3/channels?id="..channelID.."&part=snippet&key="..youtubeAPIKey)
			local authorName=body:match('"title": (%b"")'):gsub('"',""):lower()
			if authorName then
				if authorName:match("rubychan") then return end
				if message.member.name:lower():find(authorName,1,true) or message.member.username:lower():find(authorName,1,true) or authorName:find(message.member.name:lower(),1,true) or authorName:find(message.member.username:lower(),1,true) then 
					message:delete()
					arg=message.author.mentionString.." | Advertising is not allowed on this server!"
					cmd=prefix.."warn"
					if channel.name=="server-suggestions" and not io.open("suggestions.toggle","r") then
						local general=get(guild.textChannels,"general")
						if general then message=general:send("Match.") channel=general end
					else
						message=message:reply("Match.")
					end
				end
			end
		end
	end
	
	if channel.name=="server-suggestions" and not io.open("suggestions.toggle","r") then
		if isDenied(member,"suggest") then message:delete() return end
		if message.content:lower():match("youtube.com/watch%?v=") or message.content:lower():match("youtu%.be/") then message:delete() return end
		for _,v in ipairs(suggestionsEmojis) do if message then message:addReaction(v) end end
		return
	end

	if cmd == prefix.."lua" and message.author==client.owner then
		message:delete()
		exec(arg, message)
		return
	end
	
	if cmd == prefix.."say" and message.author==client.owner then
		message:delete()
		if not arg then return end
		sendEmbed(channel,arg)
		return
	end

	if cmd == prefix.."debug" and message.author==client.owner then
		message:delete()
		if not arg then return end
		if argTable[1]=="log" and argTable[2] then
			local arg2=arg:gsub("log ","",1)
			print(arg2)
			return
		end
		if argTable[1]=="status" then
			local aWarningNum=0
			local iWarningNum=0
			for k,v in pairs(warnTable) do if v[3]~="false" then aWarningNum=aWarningNum+1 else iWarningNum=iWarningNum+1 end end
			aWarningNum=tostring(aWarningNum)
			iWarningNum=tostring(iWarningNum)
            if not io.open("status.toggle","r") then
			    client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
            else
                client:setStatus(online)
            end
            sendEmbed(channel,"Refreshed status.")
            return
		end
		if argTable[1]=="logdump" then
			local fLines={}
            for line in io.lines("discordia.log") do
                table.insert(fLines,line)
            end
            local cCount=0
            local output=""
            for i=#fLines,1,-1 do
                cCount=cCount+#fLines[i]
                if cCount>=40000 then break end
                output=fLines[i].."\n"..output
            end
            client.owner:send{file={"log_dump.txt",output},content="**Log dump:**"}
			return
		end
		if argTable[1]=="bf" and argTable[2] then
			local input=arg:gsub(argTable[1].." ","")
			local bfInput=input:gsub("[^%>%<%+%-%.%,%[%]]","")
			local txtInput=input:gsub("[%>%<%+%-%.%,%[%]\n]","")
			local output=""
			local bf = {
			    ["+"] = "t[i] = t[i] + 1 ",
			    ["-"] = "t[i] = t[i] - 1 ",
			    [">"] = "i = i + 1 ",
			    ["<"] = "i = i - 1 ",
			    ["."] = "w(t[i]) ",
			    [","] = "t[i] = r() ",
			    ["["] = "while t[i] ~= 0 do ",
			    ["]"] = "end ",
			}
			local fn, err = loadstring(bfInput:gsub(".", bf), "bf", "t", {
			    i = 0,
			    t = setmetatable({}, {__index = function() return 0 end}),
			    r = function() letter=txtInput:match(".") or "" txtInput=txtInput:gsub(letter,"",1) return letter:byte() end,
			    w = function(c) output=output..string.char(c) end
			})
			if not fn then message:reply(code(err)) return end
			pc,err=pcall(fn)
			if not pc then message:reply(code(err)) return end
			if output=="" then output="nil" end
			message:reply{embed={title="Brainf*** Interpreter",fields={{name="Input:",value=code(input),inline=false},{name="Output:",value=code(output),inline=false}},color=discordia.Color.fromRGB(255,0,0).value}}
			return
		end
		if argTable[1]=="toggle" and argTable[2] then
			if not toggles[argTable[2]] then return end
			if io.open(toggles[argTable[2]],"r") then
				os.execute("rm "..toggles[argTable[2]])
				sendEmbed(channel,"Toggle `"..argTable[2].."` has been enabled.")
			else
				local f=io.open(toggles[argTable[2]],"w")
				f:write(" ")
				f:close()
				sendEmbed(channel,"Toggle `"..argTable[2].."` has been disabled.")
			end
			return
		end
		if argTable[1]=="ping" then
			local newMsg=channel:send("Pinging...")
			if newMsg then local createdAt=newMsg.createdAt newMsg:delete() sendEmbed(channel,"Ping: "..math.abs(math.floor(((createdAt - message.createdAt)*1000))).." ms") end
			return
		end
		if argTable[1]=="list" then
			local lines={}
			for k,v in pairs(warnTable) do
				user=client:getUser(k)
				if user then table.insert(lines,user.name.."\n"..k.."\n"..v[3].."\n") else table.insert(lines,"err\n"..k.."\n"..v[3].."\n") end
			end
			lines = table.concat(lines, '\n')
			if #lines > 1978 then
				lines = lines:sub(1, 1978)
				lines = lines.."\n\n<CUT OFF>"
			end
			message:reply(code(lines))
			return
		end
	end

	if cmd == prefix.."shutdown" and (message.author==client.owner or message.member==guild.owner) then
		message:delete()
		print("exiting")
		client.owner:send("Killed by "..message.author.name..".")
		sendEmbed(channel,"Shutting down.")
		client:stop()
		os.exit()
	end
	
	if cmd == prefix.."warnings" then
		message:delete()
		if isDenied(member,"view-warnings") then return end
		if arg then
			id=arg:match("%D+(%d+)%D") or member.id
		else
			id=member.id
		end
		local checkMember=guild:getMember(id)
		if not checkMember then sendEmbed(channel,"Member not found.") return end
		if not warnTable[id] then sendEmbed(channel,checkMember.name.." does not have a warning level.\nNote: warnings can also be viewed as roles.","Time until warning level is decreased: "..secondsToClock2(0)..".\nNumber of warnings until ban: 4.",icons[1]) return end
		sendEmbed(channel,checkMember.name.." has a warning level of "..warnTable[id][2]..". \nNote: warnings can also be viewed as roles.","Time until warning level is decreased: "..secondsToClock2(tonumber(warnTable[id][1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(warnTable[id][2])..".",icons[tonumber(warnTable[id][2])+1])
		return
	end

	if cmd == prefix.."changelog" then
		message:delete()
		local changelog=fs.readFileSync("changelog.txt")
		changelog=changelog:gsub("%<prefix%>",prefix)
		if #changelog>2000 then
			local splitChangelog={""}
			local messageNum,counter=1,1
			for l in changelog:gmatch("[^\n]+") do
				if counter>=2000 then
					counter=1+#l+1
					messageNum=messageNum+1
					splitChangelog[messageNum]=l.."\n"
				else
					splitChangelog[messageNum]=splitChangelog[messageNum]..l.."\n"
					counter=counter+#l+1
				end
			end
			for k,currentPortion in ipairs(splitChangelog) do
				local title=""
				if k==1 then
					title="Changelog"
				end
				channel:send{
					embed={
						title=title,
						description=currentPortion,
						color=discordia.Color.fromRGB(255,0,0).value
					}
				}
				timer.sleep(1000)
			end
		else
			channel:send{
				embed={
					title="Changelog",
					description=changelog,
					color=discordia.Color.fromRGB(255,0,0).value
				}
			}
		end
		return
	end

	if cmd == prefix.."version" then
		local changelog=fs.readFileSync("changelog.txt")
		local version=changelog:match("%*%*([^%*]+)%*%*") or "error"
		sendEmbed(channel,"Version: "..version)
	end

	if cmd == prefix.."mention" then
		message:delete()
		if not arg then return end
		--for m in guild:findMembers(function(e) return e.discriminator == discrim and e.username == name end) do print(m) end
		local mentionedUser
		for u in message.mentionedUsers:iter() do mentionedUser=u end
		if mentionedUser then
			message:reply("Mention from "..message.member.name..": "..mentionedUser.mentionString)
		else
			arg=arg:gsub("^@",""):lower()
			local discrim = arg:match("%#(%d%d%d%d)")
			local n = 0
			if discrim then
				local name = arg:match("(.+)%#%d%d%d%d")
				if name then
					local m=guild.members:find(function(e) return e.discriminator == discrim and (e.username:lower():find(name,1,true) or e.name:lower():find(name,1,true)) end) 
					if m then message:reply("Mention from **"..message.member.name.."** using `"..prefix.."mention`: "..m.mentionString) else message:reply("Mention from **"..message.member.name.."** using `"..prefix.."mention`: could not find member `"..arg.."`") end
				else
					local m=guild.members:find(function(e) return e.discriminator == discrim end)
					if m then message:reply("Mention from **"..message.member.name.."** using `"..prefix.."mention`: "..m.mentionString) else message:reply("Mention from **"..message.member.name.."** using `"..prefix.."mention`: could not find member `"..arg.."`") end
				end
			else
				local m=guild.members:find(function(e) return e.username:lower():find(arg,1,true) or e.name:find(arg,1,true) end)
				if m then message:reply("Mention from **"..message.member.name.."** using `"..prefix.."mention`: "..m.mentionString) else message:reply("Mention from **"..message.member.name.."** using `"..prefix.."mention`: could not find member `"..arg.."`") end
			end
		end
		return
	end

	--[[
	Command removed, but may be re-added

	if cmd == prefix.."roll" then
		message:delete()
		if isDenied(member,"roll") then return end
		local rolls,sides,modifier="","",""
		if arg then
			rolls,sides=arg:match("(%d*)d(%d+)")
			if not sides then return end
			if rolls=="" then rolls="1" end
			modifier=arg:match("d"..sides.."(%p%d+)")
		else
			rolls,sides,modifier="1","20",nil
		end
		if not rolls or not sides then return end
		local result=0
		for i=1,tonumber(rolls) do
			local handle=io.popen("date +%s%N | cut -b1-13")
			local ms=tonumber(handle:read("*n"))
			handle:close()
			math.randomseed(ms)
			result=result+math.random(sides)
		end
		if modifier then result=result+modifier else modifier="" end
		sendEmbed(channel,member.name.." rolled "..rolls.."d"..sides..modifier.." and got "..result..".")
		return
	end
	]]

	if cmd == prefix.."deny" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention> <deny key>") return end
		if argTable[1]=="list" then
			local list=""
			for k,v in pairs(denies) do
				list=list.."\n**Key:** "..k..". **Role name:** "..v[1]..". **Effect:** user can no longer "..v[2].."."
			end
			list=list:gsub("^\n","",1)
			channel:send{embed={title="Deny Tags",description=list,color=discordia.Color.fromRGB(255,0,0).value}}
			return
		end
		if not argTable[2] then sendUsage(message.author,cmd,"<mention> <deny key>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local denyMember=guild:getMember(id)
		if not denyMember then return end
		if denyMember.user==client.owner then denyMember=message.member end
		if denyMember.bot then return end
		if not denies[argTable[2]] then return end
		if isDenied(denyMember,argTable[2]) then sendEmbed(channel,denyMember.name.." has already been denied the ability to "..denies[argTable[2]][2]..".") return end
		local role=get(guild.roles,denies[argTable[2]][1])
		if not role then return end
		denyMember:addRole(role)
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		sendEmbed(channel,denyMember.name.." has now been denied the ability to "..denies[argTable[2]][2].."."..reason)
		local logChannel=get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,denyMember.name.." has now been denied the ability to "..denies[argTable[2]][2].."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end

	if cmd == prefix.."allow" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention> <deny key>") return end
		if argTable[1]=="list" then
			local list="**Denies**"
			for k,v in pairs(denies) do
				list=list.."\n**Key:** "..k..". **Role name:** "..v[1]..". **Effect:** user can no longer "..v[2].."."
			end
			channel:send{embed={title="Deny Tags",description=list,color=discordia.Color.fromRGB(255,0,0).value}}
			return
		end
		if not argTable[2] then sendUsage(message.author,cmd,"<mention> <deny key>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local allowMember=guild:getMember(id)
		if not allowMember then return end
		if allowMember.user==client.owner then allowMember=message.member end
		if allowMember.bot then return end
		if not denies[argTable[2]] then return end
		if not isDenied(allowMember,argTable[2]) then sendEmbed(channel,allowMember.name.." already has the ability to "..denies[argTable[2]][2]..".") return end
		local role=get(guild.roles,denies[argTable[2]][1])
		if not role then return end
		allowMember:removeRole(role)
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		sendEmbed(channel,allowMember.name.." now has the ability to "..denies[argTable[2]][2].."."..reason)
		local logChannel=get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,allowMember.name.." now has the ability to "..denies[argTable[2]][2].."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end

	if cmd == prefix.."banid" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<user id>") return end
		local id=arg:match("%d+")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:banUser(user) then sendEmbed(channel,user.name.." has been ID banned."..reason) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,user.name.." has been ID banned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."unbanid" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<user id>") return end
		local id=arg:match("%d+")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:unbanUser(user) then sendEmbed(channel,user.name.." has been ID unbanned."..reason) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,user.name.." has been ID unbanned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."voiceban" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local vbMember = guild:getMember(id)
		if not member then return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		local vbRole = get(guild.roles,"voice-banned")
		if not vbRole then return end
		if vbMember:addRole(vbRole) then
			sendEmbed(channel,vbMember.name.." has been banned from the voice channels."..reason)
			local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
			if logChannel then sendEmbed(logChannel,vbMember.name.." has been banned from the voice channels."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		else
			sendEmbed(channel,"Unable to ban "..vbMember.name.." from the voice channels.")
		end
	end
	
	if cmd == prefix.."voiceunban" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local vbMember = guild:getMember(id)
		if not member then return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		local vbRole = get(guild.roles,"voice-banned")
		if not vbRole then return end
		if vbMember:removeRole(vbRole) then
			sendEmbed(channel,vbMember.name.." has been unbanned from the voice channels."..reason)
			local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
			if logChannel then sendEmbed(logChannel,vbMember.name.." has been unbanned from the voice channels."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		else
			sendEmbed(channel,"Unable to unban "..vbMember.name.." from the voice channels.")
		end
	end
	
	if cmd == prefix.."ban" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:getMember(id) then sendEmbed(user,"You have been banned from #TeamRuby."..reason) end
		if guild:banUser(user) then sendEmbed(channel,user.name.." has been banned."..reason) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,user.name.." has been banned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."unban" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:unbanUser(user) then sendEmbed(channel,user.name.." has been unbanned."..reason) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,user.name.." has been unbanned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."mute" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention> [time (#w/#d/#h/#m)]") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local silent=arg:match("%-%-silent")
		local muteMember=guild:getMember(id)
		if not muteMember then return end
		if muteMember.user==client.owner then muteMember=message.member end
		if muteMember.bot then return end
		local muteUser=muteMember.user
		local initialTime=0
		local stringTimes=arg:match(id.."%>([^%|]+)") or ""
		for num,mod in stringTimes:gmatch("(%d+)(%a)") do
			initialTime=initialTime+getSeconds(num,mod)
		end
		if not initialTime then initialTime=3600 end
		if initialTime>1209600 then initialTime=1209600 end
		if initialTime<=0 then initialTime=3600 end
		if muteTable[id] then if not silent then sendEmbed(channel,muteMember.name.." is already muted.") end return end
		local entry={0,0,guild.id}
		local role=get(guild.roles,"Muted")
		if not role then if not silent then sendEmbed(channel,muteMember.name.." could not be muted.") end return end
		muteMember:addRole(role)
		entry[1]=os.time()+initialTime
		entry[2]=initialTime
		muteTable[id]=entry
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if not silent then sendEmbed(channel,muteMember.name.." has been muted for "..secondsToClock2(initialTime).."."..reason) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,muteMember.name.." has been muted for "..secondsToClock2(initialTime).."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		muteUpdate(getMutePrint())
		return
	end

	if cmd == prefix.."unmute" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local silent=arg:match("%-%-silent")
		local muteMember=guild:getMember(id)
		if not muteMember then return end
		if muteMember.bot then return end
		local muteUser=muteMember.user
		local entry=muteTable[id]
		local role=get(guild.roles,"Muted")
		if not entry then 
			if role and muteMember:hasRole(role) then
				muteMember:removeRole(role)
				local reason = arg:match("| (.+)")
				if reason then reason=" (Reason: "..reason..")" else reason="" end
				if not silent then sendEmbed(channel,muteMember.name.." has been unmuted."..reason) end
				local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
				if logChannel then sendEmbed(logChannel,muteMember.name.." has been unmuted."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
			else
				if not silent then sendEmbed(channel,muteMember.name.." is not muted.") end
			end
			return
		end
		if not role then if not silent then sendEmbed(channel,muteMember.name.." could not be unmuted.") end return end
		muteMember:removeRole(role)
		table.removeKey(muteTable,id)
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if not silent then sendEmbed(channel,muteMember.name.." has been unmuted."..reason) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,muteMember.name.." has been unmuted."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		muteUpdate(getMutePrint())
		return
	end
	
	if cmd == prefix.."warn" then
		message:delete()
		
		if not hasPermission(message.member,"manageRoles") then return end
			
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
			
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		
		local silent=arg:match("%-%-silent")
		local warnMember=guild:getMember(id)
		if not warnMember then return end
			
		if warnMember.user==client.owner and not message.member.bot then warnMember=message.member id=warnMember.id end
		if warnMember.bot then return end
			
		local warnUser=warnMember.user
		local entry=warnTable[id]
		if not entry then 
			entry={0,0,guild.id}
		end
		entry[2]=entry[2]+1
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if entry[2]>=4 and entry[2]<100 then 
			table.removeKey(warnTable,id)
			sendEmbed(channel,warnUser.name.." has been banned for exceeding the warn limit."..reason)
			sendEmbed(warnUser:getPrivateChannel(),"You have been banned from #TeamRuby for exceeding the warn limit."..reason)
			warnMember:ban()
			local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
			if logChannel then sendEmbed(logChannel,warnUser.name.." has been banned for exceeding the warn limit."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		else
			role=get(guild.roles,"WARNING "..entry[2])
			if not role then if not silent then entry[2]=entry[2]-1 sendEmbed(channel,warnMember.name.."'s warning level could not be changed, so is still at "..entry[2] ..".","Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end return end
			warnMember:addRole(role)
			entry[1]=os.time()+604800
			warnTable[id]=entry
			if not silent then sendEmbed(channel,warnMember.name.."'s warning level has been increased to "..entry[2].."."..reason,"Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end
			local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
			if logChannel then sendEmbed(logChannel,warnMember.name.."'s warning level has been increased to "..entry[2].."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		end
		warnUpdate(getWarnPrint())
		return
	end
	
	if cmd == prefix.."unwarn" then
		message:delete()
		if not hasPermission(member,"manageRoles") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local silent=arg:match("%-%-silent")
		local warnMember=guild:getMember(id)
		if not warnMember then return end
		if warnMember.bot then return end
		local warnUser=warnMember.user
		local entry=warnTable[id]
		if not entry then if not silent then sendEmbed(channel,warnMember.name.." does not have a warning level.","Time until warning is decreased: "..secondsToClock2(0)..".\nNumber of warnings until ban: 4.",icons[1]) end return end
		if tonumber(entry[2])<=0 then if not silent then sendEmbed(channel,warnMember.name.." does not have a warning level.","Time until warning level is decreased: "..secondsToClock2(0)..".\nNumber of warnings until ban: 4.",icons[1]) end table.removeKey(warnTable,id) warnUpdate(getWarnPrint()) return end 
		role=get(guild.roles,"WARNING "..entry[2])
		if not role then if not silent then sendEmbed(channel,warnMember.name.."'s warning level could not be changed, so is still at "..entry[2]..".","Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end return end
		warnMember:removeRole(role)
		entry[2]=entry[2]-1
		if tonumber(entry[2])<=0 then
			table.removeKey(warnTable,id)
			entry[1]=os.time()
		else
			entry[1]=os.time()+604800
			warnTable[id]=entry
		end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if not silent then sendEmbed(channel,warnMember.name.."'s warning level has been decreased to "..entry[2].."."..reason,"Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end
		local logChannel = get(guild.textChannels,"nsfw-lurkchannel")
		if logChannel then sendEmbed(logChannel,warnMember.name.."'s warning level has been decreased to "..entry[2].."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		warnUpdate(getWarnPrint())
		return
	end
end)
if not pc then logError("Bot crashed!","messageCreate",err) end
end)

client:run("Bot "..token)
clock:start()
