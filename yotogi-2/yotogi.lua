local discordia = require("discordia")
local http = require("coro-http")
local timer = require("timer")
local json = require("json")
local utils = require("./miscUtils")
local sql = require("sqlite3")
local options = require("options")

local conn = sql.open("yotogi.db")

local client = discordia.Client(options.clientOptions)
local clock = discordia.Clock()
discordia.extensions()

local commandHandler = require("./commandHandler")
commandHandler.load()
local moduleHandler = require("./moduleHandler")
moduleHandler.load()

local function setupGuild(id)
	local disabledModules = {}
	for modName, mod in pairs(moduleHandler.modules) do
		if mod.disabledByDefault then
			disabledModules[modName] = true
		end
	end
	local disabledModulesStr = json.encode(disabledModules)
	conn:exec("INSERT INTO guild_settings (guild_id, disabled_modules) VALUES ('"..id.."', '"..disabledModulesStr.."')")
end

local function doModulesPcall(event, guild, conn, ...)
	local success, err = pcall(function(...)
		local guildSettings = utils.getGuildSettings(guild.id, conn)
		if not guildSettings then
			setupGuild(guild.id)
			guildSettings = utils.getGuildSettings(guild.id, conn)
		end
		moduleHandler.doModules(event, guildSettings, ...)
	end, ...)
	if not success then
		utils.logError(guild, err)
		print("Bot crashed! Guild: "..member.guild.name.." ("..member.guild.id..")\n"..err)
	end
end

clock:on("min", function()
	for guild in client.guilds:iter() do
		doModulesPcall("clock.min", guild, conn, guild, conn)
	end
end)

client:on("ready", function()
	utils.setGame(client, conn)
end)

client:on("guildCreate", function(guild)
	if not utils.getGuildSettings(guild.id, conn) then
		setupGuild(guild.id)
	end
end)

client:on("memberJoin", function(member)
	doModulesPcall("client.memberJoin", member.guild, conn, member, conn)
end)

client:on("memberLeave", function(member)
	doModulesPcall("client.memberLeave", member.guild, conn, member, conn)
end)

client:on("userBan", function(user, guild)
	doModulesPcall("client.userBan", guild, conn, user, guild, conn)
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

		moduleHandler.doModules("client.messageCreate", guildSettings, message, conn)

		commandHandler.doCommands(message, guildSettings, conn)
	end)
	if not success then
		utils.logError(message.guild, err)
		print("Bot crashed! Guild: "..message.guild.name.." ("..message.guild.id..")\n"..err)
	end
end)

client:on("messageUpdate", function(message)
	if not message.guild then return end
	doModulesPcall("client.messageUpdate", message.guild, conn, message, conn)
end)

client:on("messageDelete", function(message)
	if not message.guild then return end
	doModulesPcall("client.messageDelete", message.guild, conn, message, conn)
end)

clock:start()
client:run("Bot "..options.token)