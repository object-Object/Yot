local discordia = require("discordia")
local http = require("coro-http")
local timer = require("timer")
local utils = require("./miscUtils")
local sql = require("sqlite3")
local options = require("options")

conn = sql.open("yotogi.db")

local client = discordia.Client(options.clientOptions)
local clock = discordia.Clock()
discordia.extensions()

local commandHandler = require("./commandHandler")
commandHandler.load()
local eventHandler = require("./eventHandler")
eventHandler.load()

local function setupGuild(id)
	conn:exec("INSERT INTO guild_settings (guild_id) VALUES ("..id..")")
end

client:on("ready", function()
	utils.setGame(client, conn)
end)

client:on("guildCreate", function(guild)
	if not utils.getGuildSettings(guild.id, conn) then
		setupGuild(guild.id)
	end
end)

client:on("messageCreate", function(message)
	local success, err = pcall(function()
		if message.author.bot then return end
		if message.channel.type == discordia.enums.channelType.private then 
			utils.sendEmbed(message.channel, "Your message has been forwarded to "..client.owner.name..".", "00ff00")
			utils.sendEmbed(client.owner:getPrivateChannel(), "**DM from "..message.author.name.."#"..message.author.discriminator..":**", "00ff00")
			client.owner:send(message)
			return
		end
		if not message.guild then return end
		local guildSettings = utils.getGuildSettings(message.guild.id, conn)
		if not guildSettings then
			setupGuild(message.guild.id)
			guildSettings = utils.getGuildSettings(message.guild.id, conn)
		end

		eventHandler.doEvents("client.messageCreate", guildSettings, message)

		commandHandler.doCommands(message, guildSettings, conn)
	end)
	if not success then
		utils.logError(client, "messageCreate", err)
		print("Bot crashed! "..err)
	end
end)

client:run("Bot "..options.token)