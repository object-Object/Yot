local discordia = require("discordia")

local utils = {}

utils.escapePatterns = function(str)
	return str:gsub("([^%w])", "%%%1")
end

utils.createLookupTable = function(input)
	local output={}
	for _,v in pairs(input) do
		output[v]=true
	end
	return output
end

utils.sendEmbed = function(channel,text,color,footer_text,footer_icon)
	local colorValue=color and discordia.Color.fromHex(color).value or nil
	local msg=channel:send{
		embed={
			description=text,
			color=colorValue,
			footer={
				text=footer_text,
				icon_url=footer_icon
			}
		}
	}
	return msg
end

utils.logError = function(client, section, err)
	return client.owner:send{
		embed = {
			title = "Bot crashed!",
			description = "```\n"..err.."```",
			color = discordia.Color.fromHex("ff0000").value,
			timestamp = discordia.Date():toISO('T', 'Z')
		}
	}
end

utils.s = function(num)
	return num==1 and "" or "s"
end

return utils