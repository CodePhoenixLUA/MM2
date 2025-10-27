local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService").TextChannels.RBXGeneral
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local placeId = game.PlaceId
local currentJobId = game.JobId

function fetchItemValues()
    local urls = {
        "https://supremevaluelist.com/mm2/godlies.html",
        "https://supremevaluelist.com/mm2/uniques.html",
        "https://supremevaluelist.com/mm2/ancients.html",
        "https://supremevaluelist.com/mm2/vintages.html",
        "https://supremevaluelist.com/mm2/chromas.html",
        "https://supremevaluelist.com/mm2/legendaries.html",
        "https://supremevaluelist.com/mm2/rares.html",
        "https://supremevaluelist.com/mm2/uncommons.html",
        "https://supremevaluelist.com/mm2/commons.html",
        "https://supremevaluelist.com/mm2/pets.html",
        "https://supremevaluelist.com/mm2/misc.html"
    }

    local valuesTable = {}
    local nameCounts = {}

    for _, url in ipairs(urls) do
        local Response = request({
            Url = url,
            Method = "GET"
        })

        if Response and Response.Body then
            local mainContent = Response.Body:match('<div class="itemlist">(.-)</div>') or Response.Body

            for itemBlock in mainContent:gmatch('<tr>.-<td class="itemimage">(.-)</tr>') do
                local originalName = itemBlock:match('<div class="itemhead">(.-)</div>')
                if originalName then
                    originalName = originalName:gsub("<.->", ""):gsub("%s+$", ""):gsub("^%s+", "")

                    local valueTag = itemBlock:match('<b class="itemvalue">(.-)</b>')
                    if valueTag then 
                        local cleanValue = valueTag:gsub(",", "")
                        local numericValue = tonumber(cleanValue)

                        if numericValue and numericValue >= 1 then

                            local imageUrl = itemBlock:match('<img.-src="(.-)"') or 
                                           itemBlock:match("background%-image:url%('(.-)'%)")

                            local rangedValue = itemBlock:match('Ranged Value.-%[<b class="itemrange">(.-)</b>%]') or
                                              itemBlock:match('Ranged Value.-%[<b>(.-)</b>%]') or "N/A"
                            rangedValue = rangedValue:gsub("^%s+", ""):gsub("%s+$", "")

                            local stability = itemBlock:match('Stability.-<b class="itemstability">(.-)</b>') or
                                            itemBlock:match('Stability.-<b>(.-)</b>') or "Unknown"
                            stability = stability:gsub("^%s+", ""):gsub("%s+$", "")

                            local demandText = itemBlock:match('Demand.-<b>(.-)</b>') or "0"
                            local demand = tonumber(demandText:match("%d+")) or 0

                            local rarityText = itemBlock:match('Rarity.-<b>(.-)</b>') or "0"
                            local rarity = tonumber(rarityText:match("%d+")) or 0

                            local origin = itemBlock:match('Origin.-<span class="itemorigin">(.-)</span>') or 
                                         itemBlock:match('Origin.-<span>(.-)</span>') or "Unknown"
                            origin = origin:gsub("^%s+", ""):gsub("%s+$", "")

                            local lastChangeText = itemBlock:match('Last Change in Value.-<b>(.-)</b>') or "0"
                            local lastChange = tonumber(lastChangeText:match("[%-%d]+")) or 0

                            nameCounts[originalName] = (nameCounts[originalName] or 0) + 1
                            local finalName = originalName

                            if nameCounts[originalName] > 1 then
                                finalName = originalName .. " " .. nameCounts[originalName]
                            end

                            local itemEntry = {
                                name = originalName,
                                value = numericValue,
                                image = imageUrl,
                                rangedValue = rangedValue,
                                stability = stability,
                                demand = demand,
                                rarity = rarity,
                                origin = origin,
                                lastChange = lastChange
                            }
                            valuesTable[finalName] = itemEntry
                        end
                    end
                end
            end
        end
    end

    if next(valuesTable) ~= nil then
        local jsonData = HttpService:JSONEncode(valuesTable)
        writefile("mm2_values_filtered.json", jsonData)
    end

    return valuesTable
end

function scanInventories()
    local allPlayersData = {}
    local players = Players:GetPlayers()
    local localPlayer = Players.LocalPlayer

    for _, player in ipairs(players) do
        local playerName = player.Name
        local success, result = pcall(function()
            return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("GetFullInventory"):InvokeServer(playerName)
        end)

        if success and result then
            local playerData = {
                Weapons = {},
                Pets = {},
                isplayerlocalplr = (player == localPlayer)
            }

            if result.Weapons and result.Weapons.Owned then
                for weaponName, count in pairs(result.Weapons.Owned) do
                    if weaponName ~= "DefaultKnife" and weaponName ~= "DefaultGun" then
                        playerData.Weapons[weaponName] = count
                    end
                end
            end

            if result.Pets and result.Pets.Owned then
                for petName, count in pairs(result.Pets.Owned) do
                    playerData.Pets[petName] = count
                end
            end
            allPlayersData[playerName] = playerData
        end
    end

    writefile('mm2_players_inventory.json', HttpService:JSONEncode(allPlayersData))
    return allPlayersData
end

function enhanceData(rawInventory, valuesData)
    local hugeListContent = readfile('hugelist.txt')
    local listStart = hugeListContent:find('{')
    local listEnd = hugeListContent:find('}', -1, true)
    local listTableStr = hugeListContent:sub(listStart, listEnd)
    local hugeList = loadstring('return ' .. listTableStr)()

    local ingameToListName = {}
    local validItems = {}
    for _, item in ipairs(hugeList) do
        ingameToListName[item.ingamename] = item.listname
        validItems[item.ingamename] = true
    end

    local enhancedData = {}
    for playerName, playerData in pairs(rawInventory) do
        local enhancedPlayerData = {
            Pets = {},
            Weapons = {},
            isplayerlocalplr = playerData.isplayerlocalplr
        }

        for weaponName, count in pairs(playerData.Weapons) do
            if validItems[weaponName] then
                local listName = ingameToListName[weaponName]
                local itemData = valuesData[listName]

                if itemData then
                    enhancedPlayerData.Weapons[listName] = {
                        ingamename = weaponName,
                        count = count,
                        value = itemData.value,
                        totalValue = itemData.value * count,
                        rarity = itemData.rarity,
                        origin = itemData.origin,
                        rangedValue = itemData.rangedValue,
                        image = itemData.image,
                        lastChange = itemData.lastChange,
                        stability = itemData.stability,
                        demand = itemData.demand,
                        isoptrade = (itemData.value >= 200)
                    }
                end
            end
        end

        for petName, count in pairs(playerData.Pets) do
            if validItems[petName] then
                local listName = ingameToListName[petName]
                local itemData = valuesData[listName]

                if itemData then
                    enhancedPlayerData.Pets[listName] = {
                        ingamename = petName,
                        count = count,
                        value = itemData.value,
                        totalValue = itemData.value * count,
                        rarity = itemData.rarity,
                        origin = itemData.origin,
                        rangedValue = itemData.rangedValue,
                        image = itemData.image,
                        lastChange = itemData.lastChange,
                        stability = itemData.stability,
                        demand = itemData.demand,
                        isoptrade = (itemData.value >= 200)
                    }
                end
            end
        end

        if next(enhancedPlayerData.Weapons) ~= nil or next(enhancedPlayerData.Pets) ~= nil then
            enhancedData[playerName] = enhancedPlayerData
        end
    end

    writefile('mm2_enhanced_inventory.json', HttpService:JSONEncode(enhancedData))
    return enhancedData
end

function setupTeleportFailureHandler()
    local success, err = pcall(function()
        if not CoreGui:FindFirstChild("RobloxPromptGui") then
            local promptGui = CoreGui:WaitForChild("RobloxPromptGui", 5) 
            if not promptGui then
                return
            end
        end

        local promptOverlay = CoreGui.RobloxPromptGui:FindFirstChild("promptOverlay")
        if not promptOverlay then
            promptOverlay = CoreGui.RobloxPromptGui:WaitForChild("promptOverlay", 5)
            if not promptOverlay then
                return
            end
        end

        promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                local errorTitle = child:WaitForChild("TitleFrame", 2):WaitForChild("ErrorTitle", 2)
                if errorTitle then
                    errorTitle:GetPropertyChangedSignal("Text"):Connect(function()
                        if errorTitle.Text == "Teleport Failed" then
                            serverHop()
                        end
                    end)
                end
            end
        end)
    end)
end

function serverHop()
    local success, result = pcall(function()
        local Servers = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
        ))

        if Servers and Servers.data then
            for i, v in ipairs(Servers.data) do
                if v.playing < v.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(placeId, v.id) --THANKS WHOEVER POST THIS SERVER HOP ON GITHUB I LOVE YOUU
                    return true
                end
            end
        end
        return false
    end)

    if not success then
        task.wait(5)
        serverHop()
    elseif not result then
        task.wait(5)
        serverHop()
    end
end

function findAndAnnounceTrades(enhancedData)
    local optimalTrades = {}
    local localPlayerData
    local otherPlayersData = {}
    local processedPlayers = 0
    local totalPlayers = 0

    for playerName, playerData in pairs(enhancedData) do
        if playerData.isplayerlocalplr then
            localPlayerData = playerData
        else
            otherPlayersData[playerName] = playerData
            totalPlayers = totalPlayers + 1
        end
    end

    if not localPlayerData then
        serverHop()
        return {}
    end

    for otherPlayerName, otherPlayerData in pairs(otherPlayersData) do
        local playerTrades = {}

        for theirWeaponName, theirWeapon in pairs(otherPlayerData.Weapons) do
            for yourWeaponName, yourWeapon in pairs(localPlayerData.Weapons) do
                local profitPercentage = ((theirWeapon.value - yourWeapon.value) / theirWeapon.value) * 100

                if profitPercentage > 0.1 and profitPercentage <= 10 and yourWeapon.value >= 2 then
                    table.insert(playerTrades, {
                        yourItem = yourWeaponName,
                        yourValue = yourWeapon.value,
                        theirItem = theirWeaponName,
                        theirValue = theirWeapon.value,
                        profitPercentage = profitPercentage,
                        valueDifference = theirWeapon.value - yourWeapon.value,
                        yourCount = yourWeapon.count,
                        theirCount = theirWeapon.count,
                        yourItemData = yourWeapon,
                        theirItemData = theirWeapon
                    })
                end
            end
        end

        for theirPetName, theirPet in pairs(otherPlayerData.Pets) do
            for yourPetName, yourPet in pairs(localPlayerData.Pets) do
                local profitPercentage = ((theirPet.value - yourPet.value) / theirPet.value) * 100

                if profitPercentage > 0.1 and profitPercentage <= 10 and yourPet.value >= 2 then
                    table.insert(playerTrades, {
                        yourItem = yourPetName,
                        yourValue = yourPet.value,
                        theirItem = theirPetName,
                        theirValue = theirPet.value,
                        profitPercentage = profitPercentage,
                        valueDifference = theirPet.value - yourPet.value,
                        yourCount = yourPet.count,
                        theirCount = theirPet.count,
                        yourItemData = yourPet,
                        theirItemData = theirPet
                    })
                end
            end
        end

        table.sort(playerTrades, function(a, b)
            return a.profitPercentage > b.profitPercentage
        end)

        if #playerTrades > 0 then
            optimalTrades[otherPlayerName] = playerTrades

            TextChatService:SendAsync(string.format(
                "%s, let me offer for your %s",
                otherPlayerName,
                playerTrades[1].theirItem
            ))

            local args = {
                Players:WaitForChild(otherPlayerName)
            }
            ReplicatedStorage:WaitForChild("Trade"):WaitForChild("SendRequest"):InvokeServer(unpack(args))

            local tradeAccepted = false
            local startTime = os.time()

            while os.time() - startTime < 20 do
                local tradeGui = Players.LocalPlayer.PlayerGui:FindFirstChild("TradeGUI")
                if tradeGui and tradeGui.Enabled then
                    tradeAccepted = true
                    break
                end
                task.wait(0.1)
            end

            if tradeAccepted then
                local bestTrade = playerTrades[1]
                local offerCategory = "Weapons"
                if localPlayerData.Pets[bestTrade.yourItem] then
                    offerCategory = "Pets"
                end
                local args = {
                    bestTrade.yourItemData.ingamename,
                    offerCategory
                }
                ReplicatedStorage:WaitForChild("Trade"):WaitForChild("OfferItem"):FireServer(unpack(args))
                    bestTrade.yourItem, 
                    otherPlayerName, 
                    bestTrade.theirItem, 
                    bestTrade.profitPercentage))
                while true do
                    local tradeGui = Players.LocalPlayer.PlayerGui:FindFirstChild("TradeGUI")
                    if not tradeGui or not tradeGui.Enabled then
                        break
                    end
                    task.wait(0.5)
                end
            else
                ReplicatedStorage:WaitForChild("Trade"):WaitForChild("CancelRequest"):FireServer()
            end
        end

        processedPlayers = processedPlayers + 1
        task.wait(1) 
    end

    if processedPlayers >= totalPlayers then
        serverHop()
    end

    writefile("mm2_optimal_trades.json", HttpService:JSONEncode(optimalTrades))

    return optimalTrades
end

setupTeleportFailureHandler()

local valuesData = fetchItemValues()
local rawInventory = scanInventories()
local enhancedData = enhanceData(rawInventory, valuesData)
local trades = findAndAnnounceTrades(enhancedData)

if trades then
    local totalPlayers = 0
    local totalTrades = 0
    for _, playerTrades in pairs(trades) do
        totalPlayers = totalPlayers + 1
        totalTrades = totalTrades + #playerTrades
    end
end
