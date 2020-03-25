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

local jsonGuildSettings=utils.createLookupTable{
	"disabled_commands",
	"persistent_roles",
	"command_permissions"
}

local function setupGuild(id)
	conn:exec("INSERT INTO guild_settings (guild_id) VALUES ("..id..")")
end

local function getGuildSettings(id)
	local settings,_ = conn:exec("SELECT * FROM guild_settings WHERE guild_id="..id..";","k")
	for k,v in pairs(settings) do
		v=v[1]
		if jsonGuildSettings[k] then
			v=json.decode(v)
		end
		settings[k]=v
	end
	return settings
end

client:on("messageCreate", function(message)
	if message.author.bot then return end
	local guildSettings = getGuildSettings(message.guild.id)
	if not guildSettings then
		setupGuild(message.guild.id)
		guildSettings = getGuildSettings(message.guild.id)
	end

	commandHandler.doCommand(message,guildSettings, conn)
end)

client:run("Bot "..options.token)