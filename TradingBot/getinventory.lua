local allPlayersData = {}

local players = game:GetService("Players"):GetPlayers()

for _, player in ipairs(players) do
    local playerName = player.Name
    local success, result = pcall(function()
        return game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("GetFullInventory"):InvokeServer(playerName)
    end)

    if success and result and result.Weapons and result.Pets then
        local playerData = {
            Weapons = {},
            Pets = {}
        }

        local key, value = next(result.Weapons.Owned)
        while key do
            if key ~= "DefaultKnife" and key ~= "DefaultGun" then
                playerData.Weapons[key] = value
            end
            key, value = next(result.Weapons.Owned, key)
        end

        local petKey, petValue = next(result.Pets.Owned)
        while petKey do
            playerData.Pets[petKey] = petValue
            petKey, petValue = next(result.Pets.Owned, petKey)
        end

        allPlayersData[playerName] = playerData
    end
end

writefile('mm2_players_inventory.json', game:GetService('HttpService'):JSONEncode(allPlayersData))
