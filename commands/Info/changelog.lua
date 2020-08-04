local commandHandler = require("commandHandler")
local discordia = require("discordia")
local fs = require("fs")
local timer = require("timer")

local function sendChangelog(channel, prefix, lang, latestOnly)
	local changelog=fs.readFileSync("changelog.txt")
	changelog=changelog:gsub("%&prefix%;", prefix)
	if latestOnly then
		changelog=changelog:gsub("\n\n.*","")
	end
	if #changelog>2000 then
		local splitChangelog={""}
		local messageNum, counter=1, 0
		for l in changelog:gmatch("[^\n]+") do
			local line = l.."\n"
			if counter+#line>=2000 then
				counter=#line
				messageNum=messageNum+1
				splitChangelog[messageNum]=line
			else
				splitChangelog[messageNum]=splitChangelog[messageNum]..line
				counter=counter+#line
			end
		end
		for k,currentPortion in ipairs(splitChangelog) do
			local title=""
			if k==1 then
				title=lang.commands.changelog.title
			end
			channel:send{
				embed={
					title=title,
					description=currentPortion,
					color=discordia.Color.fromHex("00ff00").value
				}
			}
			timer.sleep(1000)
		end
	else
		channel:send{
			embed={
				title=lang.commands.changelog.title,
				description=changelog,
				color=discordia.Color.fromHex("00ff00").value
			}
		}
	end
end

return {
	name = "changelog",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		sendChangelog(message.channel, guildSettings.prefix, lang, false)
	end,
	onEnable = function(self, guildSettings, lang, conn)
		return true
	end,
	onDisable = function(self, guildSettings, lang, conn)
		return true
	end,
	subcommands = {

		latest = {
			name = "changelog latest",
			run = function(self, message, argString, args, guildSettings, lang, conn)
				sendChangelog(message.channel, guildSettings.prefix, lang, true)
			end,
			subcommands = {}
		}

	}
}