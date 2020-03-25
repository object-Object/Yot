local discordia = require("discordia")
local http = require("coro-http")
local timer = require("timer")
local json = require("json")
local utils = require("./miscUtils")
local sql = require("sqlite3")
local options = require("options")

conn = sql.open("yotogi.db")

local client = discordia.Client(options.clientOptions)
local clock = discordia.Clock()
discordia.extensions()

local commandHandler = require("./commandHandler")
commandHandler.load()
local moduleHandler = require("./moduleHandler")
moduleHandler.load()

local jsonColumns=utils.createLookupTable{
	"disabled_commands",
	"disabled_modules",
	"persistent_roles",
	"command_permissions"
}
local booleanColumns=utils.createLookupTable{
	"delete_command_messages"
}

local function formatRow(row)
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

local function setupGuild(id)
	conn:exec("INSERT INTO guild_settings (guild_id) VALUES ("..id..")")
end

local function getGuildSettings(id)
	local settings,_ = conn:exec("SELECT * FROM guild_settings WHERE guild_id="..id..";","k")
	return formatRow(settings)
end

client:on("guildCreate", function(guild)
	if not getGuildSettings(guild.id) then
		setupGuild(guild.id)
	end
end)

client:on("messageCreate", function(message)
	local success, err = pcall(function()
		if message.author.bot then return end
		local guildSettings = getGuildSettings(message.guild.id)
		if not guildSettings then
			setupGuild(message.guild.id)
			guildSettings = getGuildSettings(message.guild.id)
		end

		moduleHandler.doModules("messageCreate", guildSettings, message)

		commandHandler.doCommand(message, guildSettings, conn)
	end)
	if not success then
		utils.logError(client, "messageCreate", err)
	end
end)

client:run("Bot "..options.token)