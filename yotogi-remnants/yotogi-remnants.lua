local discordia = require('discordia')
local discordiaOptions = {cacheAllMembers=true}
local client = discordia.Client(discordiaOptions)
local clock = discordia.Clock()
local http = require('coro-http')
local parse = require('url').parse
local timer = require('timer')
local json = require('json')
local qs = require('querystring')
local pp = require('pretty-print')
discordia.extensions()

local timeout=false

local f=io.open("settings","r")
local settings=f:read("*a"):split("%s")
f:close()

local persistRoles={
}

local englishToMorse={["a"]=".-",["b"]="-...",["c"]="-.-.",["d"]="-..",["e"]=".",["f"]="..-.",["g"]="--.",["h"]="....",["i"]="..",["j"]=".---",["k"]="-.-",["l"]=".-..",["m"]="--",["n"]="-.",["o"]="---",["p"]=".--.",["q"]="--.-",["r"]=".-.",["s"]="...",["t"]="-",["u"]="..-",["v"]="...-",["w"]=".--",["x"]="-..-",["y"]="-.--",["z"]="--..",["1"]=".----",["2"]="..---",["3"]="...--",["4"]="....-",["5"]=".....",["6"]="-....",["7"]="--...",["8"]="---..",["9"]="----.",["0"]="-----",[" "]="/"}
local morseToEnglish={}
for k,v in pairs(englishToMorse) do
	morseToEnglish[v]=k
end

local snipes={}
local logChannelName="log"
local token=settings[1]
local prefix=settings[2]
local icons={"https://i.imgur.com/Nasd4Zu.jpg","https://i.imgur.com/E4gkEdu.jpg","https://i.imgur.com/c8tw60A.jpg","https://i.imgur.com/xegOTLd.jpg"}

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
    client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
end

function getWarnPrint()
	local warnPrint=""
	for k,v in pairs(warnTable) do
		if v[2]~=0 then warnPrint=warnPrint..k.." "..v[1].." "..v[2].." "..v[3].."\n" end
	end
	return warnPrint
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
	if not num or not mod then num,mod=0,0 else num,mod=tonumber(num),modifiers[mod] end
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

function sendEmbed(channel,arg,footer_text,footer_icon)
	if not channel or not arg then error() end
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

function searchWiki(searchTerms)
	local headers={}
	local payload={
		action="query",
		format="json",
		list="search",
		srsearch=qs.urlencode(searchTerms),
		srnamespace="0|2|4|6|12|14|3000",
		srwhat="text",
		srlimit=10
	}
	local url="https://fragments.objectobject.ca/w/api.php?origin=*"
	for k,v in pairs(payload) do
		url=url.."&"..k.."="..v
	end
	local _,titleResult=http.request("GET",url.."&srwhat=title")
	titleResult=json.decode(titleResult)
	local _,textResult=http.request("GET",url.."&srwhat=text")
	textResult=json.decode(textResult)
	return titleResult.query and titleResult.query.search or {}, textResult.query and textResult.query.search or {}
end

function formatWikiResults(titleResults,textResults)
	local titleOutput=""
	local textOutput=""
	local fields={}

	for k,r in ipairs(titleResults) do
		titleOutput=titleOutput.."**"..k..".** ["..r.title.."](https://fragments.objectobject.ca/wiki/"..r.title:gsub(" ","_")..")\n"
	end
	for k,r in ipairs(textResults) do
		textOutput=textOutput.."**"..k..".** ["..r.title.."](https://fragments.objectobject.ca/wiki/"..r.title:gsub(" ","_")..")\n"
	end

	if titleOutput~="" then
		table.insert(fields,{
			name="Page title matches:",
			value=titleOutput,
			inline=false
		})
	end
	if textOutput~="" then
		table.insert(fields,{
			name="Page text matches:",
			value=textOutput,
			inline=false
		})
	end

	return #fields>0 and fields or false
end

warnDownload()
persistDownload()

client:on("ready", function()
    p("Logged in! Prefix: "..prefix)
    local aWarningNum=0
	local iWarningNum=0
	for k,v in pairs(warnTable) do if v[3]~="false" then aWarningNum=aWarningNum+1 else iWarningNum=iWarningNum+1 end end
    aWarningNum=tostring(aWarningNum)
    iWarningNum=tostring(iWarningNum)
    client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
end)

client:on('guildAvailable', function(guild)
	print(guild.name.."\nID: "..guild.id.."\n")
end)

client:on('guildCreate', function(guild)
	print("Added to guild.\n"..guild.name.."\n")
	client.owner:send("Added to guild.\n"..guild.name)
end)


client:on('guildDelete', function(guild)
	print("Kicked from guild.\n"..guild.name.."\n")
	client.owner:send("Kicked from guild.\n"..guild.name.."\n")
end)

client:on('guildUnavailable', function(guild)
	print("Guild offline?\n"..guild.name.."\n")
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
								sendEmbed(user:getPrivateChannel(),"You have been banned from the server for exceeding the warn limit.")
								sendEmbed(channel,user.name.." has been automatically banned for exceeding the warn limit.")
								member:ban()
								local logChannel=get(guild.textChannels,logChannelName)
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
											local logChannel = get(guild.textChannels,logChannelName)
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
if not pc then logError("Bot crashed!","First clock:on",err) end
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
		client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
	end
end)
if not pc then logError("Bot crashed!","Second clock:on",err) end
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
	if not warnTable then return end
	if warnTable[user.id] then
		table.removeKey(warnTable,user.id)
		warnUpdate(getWarnPrint())
	end
end)
if not pc then logError("Bot crashed!","userBan",err) end
end)

client:on("messageDelete", function(message)
local pc,err=pcall(function()
	snipes[message.channel.id]=message
	local logChannel = get(message.guild.textChannels,logChannelName)
	if logChannel then
		local content=message.content
		if content=="" then content="**<Couldn't get message content>**" end
		local name
		if message.member then name=message.member.name else name=message.author.name end
		logChannel:send{
			embed={
				author = {
					name = "Message sent by "..name.." deleted in #"..message.channel.name,
					icon_url = message.author:getAvatarURL()
				},
				description = content,
				footer = {
					text = "Author: "..message.author.tag.." | Message ID: "..message.id
				},
				color = discordia.Color.fromRGB(255,0,0).value,
				timestamp = discordia.Date():toISO('T', 'Z')
			}
		}
	end
end)
if not pc then logError("Bot crashed!","messageDelete",err) end
end)

client:on("messageCreate",function(message)
local pc,err=pcall(function()
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
	
	if channel.name=="wiki_search" then
		local searchTerms=message.content
		if not searchTerms or searchTerms=="" then return end
		local fields=formatWikiResults(searchWiki(searchTerms))
		if fields then
			channel:send{
				embed={
					fields=fields,
					color=discordia.Color.fromRGB(255, 0, 0).value
				}
			}
		else
			sendEmbed(channel,"No results found.")
		end
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

	if message.content:match("%[%[[^%[%]]+%]%]") then
		message:reply("https://fragments.objectobject.ca/wiki/"..message.content:match("%[%[([^%[%]]+)%]%]"):gsub(" ","_"))
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
			client:setGame({name=aWarningNum.." active / "..iWarningNum.." inactive warnings", url="https://www.twitch.tv/ThisIsAFakeTwitchLink"})
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

	if cmd == prefix.."avatar" then
		if not message.mentionedUsers.first then
			sendEmbed(channel,"Invalid input.\nInput mentions for one or more people to get their avatars.")
			return
		end
		local output=""
		for user in message.mentionedUsers:iter() do
			output=output..user.tag..": "..user:getAvatarURL(1024).."\n"
		end
		message:reply(output)
		return
	end

	if cmd == prefix.."morse" then
		if not arg then 
			sendEmbed(channel,"Invalid input.\nInput either text or Morse code.\nText can contain letters, numbers, and spaces.\nMorse code uses `-` as dash and `.` as dot. Separate letters with a space and words with ` / `.")
			return
		end
		local strippedArg=arg:gsub("[^%w%-%.%/ ]",""):lower()
		local output=""
		if strippedArg:match("[^%-%.%/ ]") then
			for c in strippedArg:gmatch(".") do
				if englishToMorse[c] then
					output=output..englishToMorse[c].." "
				end
			end
			if output~="" then
				output=output:sub(1,#output-1)
				sendEmbed(channel,"Morse: `"..output.."`")
			else
				sendEmbed(channel,"Invalid input.\nInput either text or Morse code.\nText can contain letters, numbers, and spaces.\nMorse code uses `-` as dash and `.` as dot. Separate letters with a space and words with ` / `.")
			end
		elseif strippedArg:match("[%-%.%/]") then
			for char in strippedArg:gmatch("%S+") do
				if morseToEnglish[char] then
					output=output..morseToEnglish[char]
				end
			end
			if output~="" then
				sendEmbed(channel,"English: `"..output.."`")
			else
				sendEmbed(channel,"Invalid input.\nInput either text or Morse code.\nText can contain letters, numbers, and spaces.\nMorse code uses `-` as dash and `.` as dot. Separate letters with a space and words with ` / `.")
			end
		else
			sendEmbed(channel,"Invalid input.\nInput either text or Morse code.\nText can contain letters, numbers, and spaces.\nMorse code uses `-` as dash and `.` as dot. Separate letters with a space and words with ` / `.")
		end
		return
	end

	if cmd == prefix.."snipe" then
		local snipe=snipes[channel.id]
		if snipe then
			sendEmbed(channel,snipe.author.mentionString.." got sniped by "..message.author.mentionString.."!")
			channel:send(snipe)
		else
			sendEmbed(channel,message.author.mentionString..", no one's deleted anything in this channel recently.")
		end
		return
	end

	if cmd == prefix.."channels" then
		local textChannelCount=#guild.textChannels
		local voiceChannelCount=#guild.voiceChannels
		local categoryCount=#guild.categories
		local totalChannelCount=textChannelCount+voiceChannelCount+categoryCount
		local r=1.02*(totalChannelCount)
		local g=1.02*(500-(totalChannelCount))
		if r>255 then r=255 end
		if g>255 then g=255 end
		message:reply{
			embed={
				fields={
					{name="Text Channels", value=textChannelCount, inline=true},
					{name="Voice Channels", value=voiceChannelCount, inline=true},
					{name="Categories", value=categoryCount, inline=true},
					{name="Usage", value=totalChannelCount.."/500 (".. 500-totalChannelCount.." remaining)", inline=true}
				},
				color=discordia.Color.fromRGB(r, g, 0).value
			}
		}
		return
	end

	if cmd == prefix.."wiki" then
		if not arg then
			channel:send{
				embed={
					fields={{
						name="Missing search terms.",
						value="Main page: https://fragments.objectobject.ca/wiki/Main_Page"
					}},
					color=discordia.Color.fromRGB(255, 0, 0).value
				}
			}
			return
		end
		local fields=formatWikiResults(searchWiki(arg))
		if fields then
			channel:send{
				embed={
					fields=fields,
					color=discordia.Color.fromRGB(255, 0, 0).value
				}
			}
		else
			sendEmbed(channel,"No results found.")
		end
		return
	end
	
	if cmd == prefix.."warnings" then
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

	if cmd == prefix.."roll" then
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

	if cmd == prefix.."banid" then
		if not member:hasRole("408737147747827712") then return end
		if not arg then sendUsage(message.author,cmd,"<user id>") return end
		local id=arg:match("%d+")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:banUser(user) then sendEmbed(channel,user.name.." has been ID banned."..reason) end
		local logChannel = get(guild.textChannels,logChannelName)
		if logChannel then sendEmbed(logChannel,user.name.." has been ID banned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."unbanid" then
		if not member:hasRole("408737147747827712") then return end
		if not arg then sendUsage(message.author,cmd,"<user id>") return end
		local id=arg:match("%d+")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:unbanUser(user) then sendEmbed(channel,user.name.." has been ID unbanned."..reason) end
		local logChannel = get(guild.textChannels,logChannelName)
		if logChannel then sendEmbed(logChannel,user.name.." has been ID unbanned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."ban" then
		if not member:hasRole("408737147747827712") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:getMember(id) then sendEmbed(user,"You have been banned from the server."..reason) end
		if guild:banUser(user) then sendEmbed(channel,user.name.." has been banned."..reason) end
		local logChannel = get(guild.textChannels,logChannelName)
		if logChannel then sendEmbed(logChannel,user.name.." has been banned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end
	
	if cmd == prefix.."unban" then
		if not member:hasRole("408737147747827712") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local user=client:getUser(id)
		if not user then sendEmbed(channel,"Unable to find user.") return end
		local reason = arg:match("| (.+)")
		if reason then reason=" (Reason: "..reason..")" else reason="" end
		if guild:unbanUser(user) then sendEmbed(channel,user.name.." has been unbanned."..reason) end
		local logChannel = get(guild.textChannels,logChannelName)
		if logChannel then sendEmbed(logChannel,user.name.." has been unbanned."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		return
	end

	if cmd == prefix.."warn" then
		if not member:hasRole("408737147747827712") then return end
		if not arg then sendUsage(message.author,cmd,"<mention>") return end
		local id=arg:match("%D+(%d+)%D")
		if not id then return end
		local silent=arg:match("%-%-silent")
		local warnMember=guild:getMember(id)
		if not warnMember then return end
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
			sendEmbed(warnUser:getPrivateChannel(),"You have been banned from the server for exceeding the warn limit."..reason)
			warnMember:ban()
			local logChannel = get(guild.textChannels,logChannelName)
			if logChannel then sendEmbed(logChannel,warnUser.name.." has been banned for exceeding the warn limit."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		else
			role=get(guild.roles,"WARNING "..entry[2])
			if not role then if not silent then entry[2]=entry[2]-1 sendEmbed(channel,warnMember.name.."'s warning level could not be changed, so is still at "..entry[2] ..".","Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end return end
			warnMember:addRole(role)
			entry[1]=os.time()+604800
			warnTable[id]=entry
			if not silent then sendEmbed(channel,warnMember.name.."'s warning level has been increased to "..entry[2].."."..reason,"Time until warning level is decreased: "..secondsToClock2(tonumber(entry[1])-os.time())..".\nNumber of warnings until ban: "..4-tonumber(entry[2])..".",icons[tonumber(entry[2])+1]) end
			local logChannel = get(guild.textChannels,logChannelName)
			if logChannel then sendEmbed(logChannel,warnMember.name.."'s warning level has been increased to "..entry[2].."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		end
		warnUpdate(getWarnPrint())
		return
	end
	
	if cmd == prefix.."unwarn" then
		if not member:hasRole("408737147747827712") then return end
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
		local logChannel = get(guild.textChannels,logChannelName)
		if logChannel then sendEmbed(logChannel,warnMember.name.."'s warning level has been decreased to "..entry[2].."."..reason,"Responsible staff member: "..message.member.name..". Channel: #"..message.channel.name..".",message.author.avatarUrl) end
		warnUpdate(getWarnPrint())
		return
	end
end)
if not pc then logError("Bot crashed!","messageCreate",err) end
end)

client:run("Bot "..token)
clock:start()
