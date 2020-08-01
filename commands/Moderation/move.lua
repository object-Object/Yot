local utils = require("miscUtils")
local commandHandler = require("commandHandler")
local http = require("coro-http")
local json = require("json")
local timer = require("timer")

return {
	name = "move",
	visible = true,
	permissions = {"manageMessages"},
	run = function(self, message, argString, args, guildSettings, lang, conn)
		if #args<2 then
			commandHandler.sendUsage(message.channel, guildSettings, lang, self)
			return
		end

		-- get startMessage
		local startMessage
		if args[3] then
			startMessage = utils.messageFromString(args[3], message.channel)
			if not startMessage then
				utils.sendEmbed(message.channel, f(lang.error.invalid_message, "`"..args[1].."`"), "ff0000")
				return
			end
		end

		-- get message(s) to move
		local selectedMessage = utils.messageFromString(args[1], message.channel)
		local messagesToMove
		if selectedMessage then
			messagesToMove = {selectedMessage}
		else
			local num = tonumber(args[1]:match("^(%d+)$"))
			if not num or num<1 or num>100 then
				utils.sendEmbed(message.channel, f(lang.error.invalid_message_2, "`"..args[1].."`"), "ff0000")
				return
			end
			-- need to only get messages before the command message so we don't move it
			-- toArray sorts it by timestamp so the messages are moved in order
			if startMessage then
				num=num-1
				if num>0 then
					messagesToMove = message.channel:getMessagesBefore(startMessage.id, num):toArray("timestamp")
				else
					messagesToMove = {}
				end
				table.insert(messagesToMove, startMessage)
			else
				messagesToMove = message.channel:getMessagesBefore(message.id, num):toArray("timestamp")
			end
		end

		-- get target channel
		local targetChannel = utils.channelFromString(args[2], message.guild)
		if not (targetChannel and targetChannel.guild and targetChannel.guild.id==message.guild.id) then
			utils.sendEmbed(message.channel, f(lang.error.invalid_channel, "`"..args[2].."`"), "ff0000")
			return
		elseif targetChannel.id==message.channel.id then
			utils.sendEmbed(message.channel, lang.error.cant_move_to_same_channel, "ff0000")
			return
		end

		-- checks to make sure move is possible
		local selfMember = message.guild:getMember(message.client.user.id)
		if not selfMember:hasPermission(targetChannel, "manageWebhooks") then
			utils.sendEmbed(message.channel, "The messages could not be moved because Yot does not have the `manageWebhooks` permission.", "ff0000")
			return
		elseif not selfMember:hasPermission(targetChannel, "manageMessages") then
			utils.sendEmbed(message.channel, "The messages could not be moved because Yot does not have the `manageMessages` permission.", "ff0000")
			return
		end

		-- get webhook url, create if doesn't exist
		local entry, _ = conn:exec("SELECT webhook_id FROM webhooks WHERE channel_id = '"..targetChannel.id.."';")
		local webhook = entry and message.client:getWebhook(entry.webhook_id[1])
		if not webhook then
			-- if webhook is nil, then either entry didn't exist or the webhook has been deleted
			webhook = targetChannel:createWebhook(lang.move.webhook_name)
			if entry then
				conn:exec("UPDATE webhooks SET webhook_id = '"..webhook.id.."' WHERE channel_id = '"..targetChannel.id.."';")
			else
				conn:exec("INSERT INTO webhooks (channel_id, webhook_id) VALUES ('"..targetChannel.id.."', '"..webhook.id.."');")
			end
		end

		local numMessages = #messagesToMove
		utils.sendEmbed(targetChannel, f(lang.pl(lang.move.moved_here, numMessages), numMessages, message.channel.mentionString), "00ff00")
		local movingMessage = utils.sendEmbed(message.channel, f(lang.pl(lang.move.moving_away, numMessages), numMessages, targetChannel.mentionString), "00ff00", f(lang.move.eta, utils.secondsToTime(numMessages, lang)))
		local API = message.client._api
		local method = "POST"
		local endpoint = "/webhooks/"..webhook.id.."/"..webhook.token
		for _, moveMessage in ipairs(messagesToMove) do
			local member = message.guild:getMember(moveMessage.author.id)
			local name = member and member.name or moveMessage.author.name
			name = name:gsub("([Cc])([Ll][Yy][Dd][Ee])","%1 %2") -- Discord doesn't allow webhook names to contain Clyde so we add a space between C and L, case insensitive
			local payload = {
				content = moveMessage.content,
				username = name,
				avatar_url = moveMessage.author.avatarURL,
				embeds = moveMessage.embeds,
				allowed_mentions = {parse={}}
			}
			local files = {}
			if moveMessage.attachments then
				for _, attachment in ipairs(moveMessage.attachments) do
					local res, file = http.request("GET", attachment.url)
					if not (res.code>=200 and res.code<300) then
						res, file = http.request("GET", attachment.proxy_url)
					end
					if res.code>=200 and res.code<300 then
						table.insert(files, {attachment.filename, file})
					end
				end
			end
			API:request(method, endpoint, payload, nil, files)
			moveMessage:delete()
			timer.sleep(1000)
		end
		movingMessage:delete()
		utils.sendEmbed(message.channel, f(lang.pl(lang.move.moved_away, numMessages), numMessages, targetChannel.mentionString), "00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}