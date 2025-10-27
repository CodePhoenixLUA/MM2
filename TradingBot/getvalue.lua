local HttpService = game:GetService("HttpService")

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
