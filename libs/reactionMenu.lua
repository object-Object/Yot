local discordia = require("discordia")
local utils = require("miscUtils")
local timer = require("timer")

local rm = {}

rm.reactions = {
	exit = "🛑",
	back = "⬅",
	choices = {
		"1️⃣",
		"2️⃣",
		"3️⃣",
		"4️⃣",
		"5️⃣",
		"6️⃣",
		"7️⃣",
		"8️⃣",
		"9️⃣"
	}
}

rm.validReactions = {["🛑"]=true, ["⬅"]=true, ["1️⃣"]=true, ["2️⃣"]=true, ["3️⃣"]=true, ["4️⃣"]=true, ["5️⃣"]=true, ["6️⃣"]=true, ["7️⃣"]=true, ["8️⃣"]=true, ["9️⃣"]=true}

local exit = function(message, lang)
	message:clearReactions()
	message:setEmbed{
		title = lang.reaction_menu.exit_title,
		description = lang.reaction_menu.exit_desc,
		color = discordia.Color.fromHex("00ff00").value
	}
end

local timeout = function(message, lang)
	message:clearReactions()
	message:setEmbed{
		title = lang.reaction_menu.timed_out_title,
		description = lang.reaction_menu.timed_out_desc,
		color = discordia.Color.fromHex("ff0000").value
	}
end

-- returns the next page to go to
local showPage = function(message, authorId, menu, page, lang, isFirstPage)
	message:clearReactions()
	local embed = {
		color = discordia.Color.fromHex("00ff00").value
	}
	embed.title = page.title

	local description = {}
	if page.description then table.insert(description, page.description.."\n") end
	if not isFirstPage then table.insert(description, rm.reactions.back.." "..lang.reaction_menu.back) end
	table.insert(description, rm.reactions.exit.." "..lang.reaction_menu.exit)
	if page.choices then
		table.insert(description, "")
		for num, choice in ipairs(page.choices) do
			table.insert(description, rm.reactions.choices[num].." "..choice.name..(choice.value and " ("..choice:value(menu, lang)..")" or ""))
		end
	end
	embed.description = table.concat(description, "\n")

	message:setEmbed(embed)

	if not isFirstPage then message:addReaction(rm.reactions.back) end
	message:addReaction(rm.reactions.exit)
	if page.choices then
		for num=1, #page.choices do
			message:addReaction(rm.reactions.choices[num])
		end
	end

	local eventName, object1, object2

	while true do
		if page.isPrompt then
			eventName, object1, object2 = utils.waitForAny(message.client, "messageCreate", "reactionAdd", menu.timeout, 
				function(m) return m.author.id==authorId and m.channel.id==message.channel.id end,
				function(r, a) return r.message.id==message.id and a~=r.client.user.id end)
		else
			local success
			success, object1, object2 = message.client:waitFor("reactionAdd", menu.timeout, 
				function(r, a) return r.message.id==message.id and a~=r.client.user.id end)
			eventName = success and "reactionAdd" or false
		end

		if not eventName then
			timeout(message, lang)
			return false
		elseif eventName=="messageCreate" then
			object1:delete() -- delete the user's message to keep things pretty
			return page:onPrompt(menu, lang, object1)
		elseif eventName=="reactionAdd" then
			if not rm.validReactions[object1.emojiName] or object2~=authorId or (isFirstPage and object1.emojiName==rm.reactions.back) then
				object1:delete(object2) -- delete the extraneous reaction and keep waiting for a good one
			elseif object1.emojiName==rm.reactions.exit then
				exit(message, lang)
				return false
			elseif object1.emojiName==rm.reactions.back then
				return true
			else
				for num, reaction in ipairs(rm.reactions.choices) do
					if object1.emojiName==reaction then
						return page.choices[num].onChoose and page.choices[num]:onChoose(menu, lang) or page.choices[num].destination
					end
				end
			end
		end
	end
end

rm.send = function(channel, authorId, menu, lang)
	menu.timeout = menu.timeout or 120000 -- 2 minutes
	local message = utils.sendEmbed(channel, lang.reaction_menu.setting_up, "00ff00")
	local history = {}
	local currentPage = menu.startPage
	local nextPage = showPage(message, authorId, menu, currentPage, lang, true)
	while nextPage do
		if nextPage==true then
			nextPage = table.remove(history) or menu.startPage
		elseif not currentPage.isPrompt and currentPage~=nextPage then
			table.insert(history, currentPage)
		end
		currentPage = nextPage
		nextPage = showPage(message, authorId, menu, nextPage, lang, #history==0)
	end
end

return rm