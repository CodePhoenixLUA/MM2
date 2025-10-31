--put ts in autoexecute reall
repeat task.wait() until game:IsLoaded()

local list = {
    "does anyone has a free common plz ill be super grateful",
    "please free gray stuff im just starting out",
    "can I get some spare bad stuff I'm new to MM2 trading plz"
}

local text1 = game.Players.LocalPlayer.PlayerGui.MainGUI.Game.Leaderboard.Container.TradeRequest
text1:GetPropertyChangedSignal("Visible"):Connect(function()
    if text1.Visible == true then
        task.wait(1)
        game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("AcceptRequest"):FireServer()
    end
end)

local text2 = game.Players.LocalPlayer.PlayerGui.TradeGUI.Container.Trade.TheirOffer.Accepted

function allowTrade()
    local args = {
    	285646582
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Trade"):WaitForChild("AcceptTrade"):FireServer(unpack(args))
end

text2:GetPropertyChangedSignal("Visible"):Connect(function()
    if text2.Visible == true then
        allowTrade()  
    end
end)

local chatService = game:GetService("TextChatService")
_G.autochat = true
while _G.autochat do
    for i,v in pairs(list) do
        chatService.TextChannels.RBXGeneral:SendAsync(v)
        task.wait(30)
    end
    
    function serverhop()
        local Servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for i,v in pairs(Servers.data) do
            if v.playing ~= v.maxPlayers then
                game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, v.id)
            end
        end
    end
    
    serverhop()
end
