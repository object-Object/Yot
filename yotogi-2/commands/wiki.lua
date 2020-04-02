local utils = require("../miscUtils")
local options = require("../options")
local discordia = require("discordia")
local qs = require("querystring")
local http = require("coro-http")
local json = require("json")

local function searchWiki(searchTerms)
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

local function formatWikiResults(titleResults,textResults)
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

return {
	name = "wiki",
	description = "Search the Fragments Wiki.",
	usage = "wiki [search terms]",
	visible = false,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if message.guild.id~=options.fragmentsGuildId then return end
		if argString=="" then
			message.channel:send{
				embed={
					fields={{
						name="Missing search terms.",
						value="Main page: https://fragments.objectobject.ca/wiki/Main_Page"
					}},
					color=discordia.Color.fromHex("ff0000").value
				}
			}
			return
		end
		local fields=formatWikiResults(searchWiki(argString))
		if fields then
			message.channel:send{
				embed={
					fields=fields,
					color=discordia.Color.fromHex("00ff00").value
				}
			}
		else
			utils.sendEmbed(message.channel, "No results found.", "ff0000")
		end
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}