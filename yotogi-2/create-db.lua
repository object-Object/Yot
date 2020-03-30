local sql = require("sqlite3")
local conn = sql.open("yotogi.db")
local options = require("options")

print("Creating database...")
conn:exec([[
CREATE TABLE IF NOT EXISTS guild_settings (
	guild_id TEXT PRIMARY KEY,
	persistent_roles TEXT DEFAULT "{}",
	disabled_commands TEXT DEFAULT "{}",
	disabled_modules TEXT DEFAULT "{}",
	command_permissions TEXT DEFAULT "{}",
	prefix TEXT DEFAULT "]]..options.defaultPrefix..[[",
	warning_length REAL DEFAULT ]]..options.warningLength..[[,
	default_mute_length REAL DEFAULT ]]..options.muteLength..[[,
	warning_kick_level REAL DEFAULT ]]..options.warningKickLevel..[[,
	warning_ban_level REAL DEFAULT ]]..options.warningBanLevel..[[,
	delete_command_messages BOOLEAN DEFAULT 0 NOT NULL CHECK (delete_command_messages IN (0,1)),
	public_log_channel TEXT,
	staff_log_channel TEXT
);
CREATE TABLE IF NOT EXISTS warnings (
	guild_id TEXT,
	user_id TEXT,
	level REAL,
	end_timestamp REAL,
	is_active BOOLEAN DEFAULT 1 NOT NULL CHECK (is_active IN (0,1)),
	PRIMARY KEY (guild_id, user_id),
	FOREIGN KEY (guild_id) REFERENCES guild_settings(guild_id)
);
CREATE TABLE IF NOT EXISTS mutes (
	guild_id TEXT,
	user_id TEXT,
	duration REAL,
	end_timestamp REAL,
	is_active BOOLEAN DEFAULT 1 NOT NULL CHECK (is_active IN (0,1)),
	PRIMARY KEY (guild_id, user_id),
	FOREIGN KEY (guild_id) REFERENCES guild_settings(guild_id)
);
CREATE TABLE IF NOT EXISTS persistent_roles (
	guild_id TEXT,
	user_id TEXT,
	roles TEXT,
	PRIMARY KEY (guild_id, user_id),
	FOREIGN KEY (guild_id) REFERENCES guild_settings(guild_id)
);
]])
print("Done.")