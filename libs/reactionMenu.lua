local discordia = require("discordia")
local utils = require("miscUtils")

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

rm.showPage = function(message, authorId, menu, page, lang)
	message:clearReactions()
	local embed = {
		color = discordia.Color.fromHex("00ff00").value
	}
	embed.title = page.title
	local description = {
		(page.description and page.description.."\n"),
		rm.reactions.exit.." "..lang.reaction_menu.exit,
		rm.reactions.back.." "..lang.reaction_menu.back
	}
	
	if page.choices then
		for num, choice in ipairs(page.choices) do
			table.insert(description, rm.reactions.choices[num].." "..choice.name..(choice.value and " ("..choice.value..")" or ""))
		end
	end
	embed.description = table.concat(description, "\n")

	message:setEmbed(embed)

	message:addReaction(rm.reactions.exit)
	message:addReaction(rm.reactions.back)
	if page.choices then
		for num=1, #page.choices do
			message:addReaction(rm.reactions.choices[num])
		end
	end

	local eventName, object1, object2

	::waitFor::
	eventName, object1, object2 = nil, nil, nil
	if page.isPrompt then
		eventName, object1, object2 = utils.waitForAny(message.client, "messageCreate", "reactionAdd", menu.timeout, 
			function(m) return m.author.id==authorId end,
			function(r, a) return a==authorId end)
	else
		local success
		success, object1, object2 = message.client:waitFor("reactionAdd", menu.timeout, 
			function(r, a) return a==authorId end)
		eventName = success and "reactionAdd" or false
	end

	if not eventName then
		rm.timeout(message, lang)
	elseif eventName=="messageCreate" then
		object1:delete()
		rm.showPage(message, authorId, menu, page:onPrompt(object1), lang)
	elseif eventName=="reactionAdd" then
		if not rm.validReactions[object1.emojiName] then
			object1:delete(object2)
			goto waitFor
		elseif object1.emojiName==rm.reactions.exit then
			rm.exit(message, lang)
		elseif object1.emojiName==rm.reactions.back then
			rm.showPage(message, authorId, menu, page.parentPage, lang)
		else
			for num, reaction in ipairs(rm.reactions.choices) do
				if object1.emojiName==reaction then
					rm.showPage(message, authorId, menu, (page.choices[num].onChoose and page.choices[num]:onChoose() or page.choices[num].destination), lang)
					break
				end
			end
		end
	end
end

rm.exit = function(message, lang)
	message:clearReactions()
	message:setEmbed{
		title = lang.reaction_menu.exit_title,
		description = lang.reaction_menu.exit_desc,
		color = discordia.Color.fromHex("00ff00").value
	}
end

rm.timeout = function(message, lang)
	message:clearReactions()
	message:setEmbed{
		title = lang.reaction_menu.timed_out_title,
		description = lang.reaction_menu.timed_out_desc,
		color = discordia.Color.fromHex("ff0000").value
	}
end

rm.send = function(channel, authorId, menu, lang)
	menu.timeout = menu.timeout or 120000 -- 2 minutes
	local message = utils.sendEmbed(channel, lang.reaction_menu.setting_up, "00ff00")
	rm.showPage(message, authorId, menu, menu.startPage, lang)
end

return rm