if isServer() then return end

local json = require('json')
local table = table
local getSoundManager = getSoundManager
local getPlayer = getPlayer
local print = print
local addSound = addSound
local BodyPartType = BodyPartType
local sendClientCommand = sendClientCommand
local ipairs = ipairs

local onServerCommand = function(module, command, args)
    args = args or {}

    print(module .. ': client command received: ' .. command .. ' ' .. json:encode_pretty(args))

    if command == 'comegetsome' then
        local player = getPlayer()
        if player ~= nil and (player:getUsername() == args.username or args.username == nil) then
            addSound(player, player:getX(), player:getY(), player:getZ(), 200, 600)
            getSoundManager():PlayWorldSound("comegetsome", player:getCurrentSquare(), 1.0, 200, 0.7, true)
        end
    end

    if command == 'slap' then
        local player = getPlayer()
        if player ~= nil and (player:getUsername() == args.username or args.username == nil) then
            getSoundManager():PlayWorldSound("slap", player:getCurrentSquare(), 1.0, 9000, 1, true)
            local bodyPartType = BodyPartType.FromString("Head")
            local bodyPartIndex = BodyPartType.ToIndex(bodyPartType)
            local playerBodyDamage = player:getBodyDamage()
            local bodyParts = playerBodyDamage:getBodyParts()
            local head = bodyParts:get(bodyPartIndex)
            head:AddDamage(5)
        end
    end

    if command == 'message' then
        local player = getPlayer()
        if player ~= nil and (player:getUsername() == args.to or args.to == nil) then
            print(args.text)
        end
    end

    if command == 'gift' then
        local player = getPlayer()
        if player ~= nil and (player:getUsername() == args.username or args.username == nil) then
            local inv = player:getInventory()
            for _, item in ipairs(args.items) do
                inv:AddItem(item);
            end
        end
    end

    if command == 'teleport' then
        local player = getPlayer()
        player:setPosition(args.x, args.y, player:getZ())
    end
end

local everyOneMinute = function()
    local player = getPlayer()

    if player ~= nil then
        local playerInventory = player:getInventory()
        local inventory = {}
        local inventoryItems = playerInventory:getItems()

        for i = 0, inventoryItems:size() - 1 do
            local item = inventoryItems:get(i)
            table.insert(inventory, {
                name = item:getDisplayName(),
                type = item:getType()
            })
        end

        local args = {
            username = player:getUsername(),
            inventory = inventory
        }

        sendClientCommand('BrainSlug', 'playerInventory', args)
    end
end

local onPlayerDeath = function()
    sendClientCommand('BrainSlug', 'playerDied', { username = getPlayer():getUsername() })
end

Events.OnPlayerDeath.Add(onPlayerDeath)
Events.EveryOneMinute.Add(everyOneMinute)
Events.OnServerCommand.Add(onServerCommand)