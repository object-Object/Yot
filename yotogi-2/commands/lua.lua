local commandHandler = require("../commandHandler")
local pp = require('pretty-print')

local function printLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = tostring(select(i, ...))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

local function prettyLine(...)
	local ret = {}
	for i = 1, select('#', ...) do
		local arg = pp.strip(pp.dump(select(i, ...)))
		table.insert(ret, arg)
	end
	return table.concat(ret, '\t')
end

local function code(str)
	return string.format('```\n%s```', str)
end

return {
	name = "lua",
	description = "Execute arbitrary Lua code.",
	usage = "lua <code (may be in a full code block)>",
	visible = false,
	permissions = {"yotogi.botOwner"},
	run = function(message, argString, args, guildSettings)
		if argString=="" then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, "lua")
			return
		end

		argString = argString:gsub('```\n?', '')

		local lines = {}
		local iolines = {}

		local sandbox = table.copy(_G, localtable)
		sandbox.message = message
		sandbox.client = message.client
		sandbox.guildSettings = guildSettings
		sandbox.code = code
		sandbox.timer = require("timer")
		sandbox.discordia = require("discordia")
		sandbox.utils = require("../miscUtils")
		
		sandbox.io.write = function(...)
			table.insert(iolines, printLine(...))
		end

		sandbox.print = function(...)
			table.insert(lines, printLine(...))
		end

		sandbox.p = function(...)
			table.insert(lines, prettyLine(...))
		end

		local fn, syntaxError = load(argString, 'DiscordBot', 't', sandbox)
		if not fn then return message:reply(code(syntaxError)) end

		local success, runtimeError = pcall(fn)
		if not success then return message:reply(code(runtimeError)) end

		lines = table.concat(lines, '\n')
		iolines = table.concat(iolines)

		if lines~="" then message:reply(lines) end
		if iolines~="" then message:reply(iolines) end
	end,
	subcommands = {}
}