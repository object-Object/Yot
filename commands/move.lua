local utils = require("../miscUtils")
local commandHandler = require("../commandHandler")

-- create a new webhook in channel and insert it into the database
local function addWebhook(channel, conn)

end

return {
	name = "move",
	description = "Move a specified message, or specified number of recent messages (1 to 100), to another channel. If a specific message is being moved, it must be in the channel in which you are running the command.",
	usage = "move <message id, link to message, or specified number of messages (1 to 100)> <channel mention (e.g. #general) or id>",
	visible = true,
	permissions = {"manageMessages"},
	run = function(self, message, argString, args, guildSettings, conn)
		if #args<2 then
			commandHandler.sendUsage(message.channel, guildSettings.prefix, self.name)
			return
		end

		-- get message(s) to move
		local selectedMessage = utils.messageFromString(args[1], message.channel)
		local messagesToMove
		if selectedMessage then
			messagesToMove = {selectedMessage}
		else
			local num = tonumber(args[1]:match("^(%d+)$"))
			if not num then
				utils.sendEmbed(message.channel, "`"..args[1].."` is not a valid message id, link to a message, or number of messages to move. Messages being moved must be in the channel in which the command is run.", "ff0000")
				return
			elseif num<1 or num>100 then
				utils.sendEmbed(message.channel, "Number of messages must be between 1 and 100, inclusive.", "ff0000")
				return
			end
			-- need to only get messages before the command message so we don't move it
			-- toArray sorts it by timestamp so the messages are moved in order
			messagesToMove = message.channel:getMessagesBefore(message.id, num):toArray("timestamp")
		end

		-- get target channel
		local targetChannel = utils.channelFromString(args[2], message.guild)
		if not (targetChannel and targetChannel.guild and targetChannel.guild.id==message.guild.id) then
			utils.sendEmbed(message.channel, "`"..args[2].."` is not a valid channel mention or id.", "ff0000")
			return
		elseif targetChannel.id==message.channel.id then
			utils.sendEmbed(message.channel, "Messages cannot be moved to the channel in which they were sent.", "ff0000")
			return
		end

		-- checks to make sure move is possible
		local selfMember = message.guild:getMember(message.client.user.id)
		if not selfMember:hasPermission(targetChannel, "manageWebhooks") then
			utils.sendEmbed(message.channel, "The messages could not be moved because Yotogi does not have the `manageWebhooks` permission.", "ff0000")
			return
		elseif not selfMember:hasPermission(targetChannel, "manageMessages") then
			utils.sendEmbed(message.channel, "The messages could not be moved because Yotogi does not have the `manageMessages` permission.", "ff0000")
			return
		end

		-- get webhook url, create if doesn't exist
		local entry, _ = conn:exec("SELECT webhook_id FROM webhooks WHERE channel_id = '"..targetChannel.id.."';")
		local webhook
		if entry then
			webhook = message.client:getWebhook(entry.webhook_id[1])
		end
		if not webhook then
			-- if webhook is nil, then either entry didn't exist or the webhook has been deleted
			webhook = targetChannel:createWebhook("Yotogi System Webhook")
			if entry then
				conn:exec("UPDATE webhooks SET webhook_id = '"..webhook.id.."' WHERE channel_id = '"..targetChannel.id.."';")
			else
				conn:exec("INSERT INTO webhooks (channel_id, webhook_id) VALUES ('"..targetChannel.id.."', '"..webhook.id.."');")
			end
		end

		local numMessages = #messagesToMove
		local s = utils.s(numMessages)
		utils.sendEmbed(targetChannel, "Moved "..numMessages.." message"..s.." to this channel from "..message.channel.mentionString..":", "00ff00")
		for _, moveMessage in ipairs(messagesToMove) do
			local member = message.guild:getMember(moveMessage.author.id)
			local name = member and member.name or moveMessage.author.name
			name = name:gsub("([Cc])([Ll][Yy][Dd][Ee])","%1 %2") -- Discord doesn't allow webhook names to contain Clyde so we add a space between C and L, case insensitive
			message.client._api:executeWebhook(webhook.id, webhook.token, {
				content = moveMessage.content,
				username = name,
				avatar_url = moveMessage.author.avatarURL,
				file = moveMessage.attachment, -- files don't currently work
				embeds = moveMessage.embed and {moveMessage.embed},
				allowed_mentions = {parse={}} -- disable all mentions to avoid double pinging people
			})
			moveMessage:delete()
		end
		utils.sendEmbed(message.channel, "Moved "..numMessages.." message"..s.." to "..targetChannel.mentionString..".", "00ff00")
	end,
	onEnable = function(self, message, guildSettings)
		return true
	end,
	onDisable = function(self, message, guildSettings)
		return true
	end,
	subcommands = {}
}