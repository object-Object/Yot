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
	if not (channel and text) then return end
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

return utils