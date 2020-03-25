return {
	name = "warn",
	description = "Warn a user.",
	usage = "warn <mention or id> [reason]",
	visible = true,
	permissions = {"kickMembers","banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		
	end,
	onEnable = function(self, message, guildSettings) -- function called when this command is enabled, return true if enabling can proceed
		return true
	end,
	onDisable = function(self, message, guildSettings) -- function called when this command is disabled, return true if disabling can proceed
		return true
	end,
	subcommands = {}
}