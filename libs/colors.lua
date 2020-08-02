local utils = require("miscUtils")
local http = require("coro-http")
local discordia = require("discordia")
local options = discordia.storage.options

local colors = {}

-- code: 6-digit hex color, case doesn't matter
colors.getColorURL = function(code, client, conn)
	assert(type(code)=="string", "Expected string, got "..type(code))
	assert(#code==6, "Expected code length of 6, got length of "..#code)
	assert(code:match("%W")==nil, "Found non-alphanumeric characters in code")

	code = code:lower()

	local selectStmt = conn:prepare("SELECT url FROM colors WHERE code = ?;")
	local color, _ = selectStmt:reset():bind(code):resultset("k")
	color = utils.formatRow(color)

	if not color then
		local API = client._api
		local method = "POST"
		local endpoint = "/webhooks/"..options.webhooks.colors.id.."/"..options.webhooks.colors.token
		local payload = {content="#"..code}
		local files = {}
		local res, file = http.request("GET", "http://www.singlecolorimage.com/get/"..code.."/100x100")
		if not (res.code>=200 and res.code<300 and file) then
			return false
		end
		table.insert(files, {code..".png", file})
		local url = API:request(method, endpoint, payload, nil, files).attachments[1].url

		local insertStmt = conn:prepare("INSERT INTO colors (code, url) VALUES (?, ?);")
		insertStmt:reset():bind(code, url):step()

		return url
	end

	return color.url
end

return colors