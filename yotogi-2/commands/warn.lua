return {
	name = "warn",
	description = "Warn a user.",
	usage = "warn <mention or id> [reason]",
	visible = true,
	permissions = {"kickMembers","banMembers"},
	run = function(self, message, argString, args, guildSettings, conn)
		
	end,
	subcommands = {}
}