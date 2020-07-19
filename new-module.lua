local sql = require("sqlite3")
local conn = sql.open("yot.db")

local guilds, nrow = conn:exec("SELECT guild_id, disabled_modules FROM guild_settings;")
local prep = conn:prepare("UPDATE guild_settings SET disabled_modules = ? WHERE guild_id = ?;")

for row=1,nrow do
	prep:reset():bind(guilds.disabled_modules[row]:gsub("}", ',"join-messages":true,"leave-messages":true}'), guilds.guild_id[row]):step()
end
print("Done")