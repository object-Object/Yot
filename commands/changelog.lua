local commandHandler = require("../commandHandler")
local discordia = require("discordia")
local fs = require("fs")
local timer = require("timer")

local function sendChangelog(channel, prefix, latestOnly)
	local changelog=fs.readFileSync("changelog.txt")
	changelog=changelog:gsub("%&prefix%;", prefix)
	if latestOnly then
		changelog=changelog:gsub("\n\n.*","")
	end
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
					color=discordia.Color.fromHex("00ff00").value
				}
			}
			timer.sleep(1000)
		end
	else
		channel:send{
			embed={
				title="Changelog",
				description=changelog,
				color=discordia.Color.fromHex("00ff00").value
			}
		}
	end
end

return {
	name = "changelog",
	description = "Show Yot's changelog.",
	usage = "changelog",
	visible = true,
	permissions = {},
	run = function(self, message, argString, args, guildSettings, conn)
		if commandHandler.doSubcommands(message, argString, args, guildSettings, conn, self.name) then return end
		sendChangelog(message.channel, guildSettings.prefix, false)
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {

		latest = {
			name = "changelog latest",
			description = "Show Yot's most recent changelog.",
			usage = "changelog latest",
			run = function(self, message, argString, args, guildSettings, conn)
				sendChangelog(message.channel, guildSettings.prefix, true)
			end,
			subcommands = {}
		}

	}
}