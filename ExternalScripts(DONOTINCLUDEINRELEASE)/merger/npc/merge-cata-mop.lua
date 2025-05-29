local cata = require('cataNpcDB')
local mop = require('mopNpcDB')
local mopTrinity = require('mopNpcDB-trinity')
local mopWowhead = require('wowheadNpcDB')

local npcKeys = {
    ['name'] = 1, -- string
    ['minLevelHealth'] = 2, -- int
    ['maxLevelHealth'] = 3, -- int
    ['minLevel'] = 4, -- int
    ['maxLevel'] = 5, -- int
    ['rank'] = 6, -- int, see https://github.com/cmangos/issues/wiki/creature_template#rank
    ['spawns'] = 7, -- table {[zoneID(int)] = {coordPair(floatVector2D),...},...}
    ['waypoints'] = 8, -- table {[zoneID(int)] = {coordPair(floatVector2D),...},...}
    ['zoneID'] = 9, -- guess as to where this NPC is most common
    ['questStarts'] = 10, -- table {questID(int),...}
    ['questEnds'] = 11, -- table {questID(int),...}
    ['factionID'] = 12, -- int, see https://github.com/cmangos/issues/wiki/FactionTemplate.dbc
    ['friendlyToFaction'] = 13, -- string, Contains "A" and/or "H" depending on NPC being friendly towards those factions. nil if hostile to both.
    ['subName'] = 14, -- string, The title or function of the NPC, e.g. "Weapon Vendor"
    ['npcFlags'] = 15, -- int, Bitmask containing various flags about the NPCs function (Vendor, Trainer, Flight Master, etc.).
    -- For flag values see https://github.com/cmangos/mangos-classic/blob/172c005b0a69e342e908f4589b24a6f18246c95e/src/game/Entities/Unit.h#L536
}

for npcId, data in pairs(mop) do
    local trinityNpc = mopTrinity[npcId]
    if trinityNpc then
        -- iterate npcKeys and take the values from mopTrinity if mop doesn't have them
        for _, index in pairs(npcKeys) do
            if not data[index] and trinityNpc[index] then
                mop[npcId][index] = trinityNpc[index]
            end
        end

        if trinityNpc[npcKeys.spawns] then
            mop[npcId][npcKeys.spawns] = {}
            for zoneId, _ in pairs(trinityNpc[npcKeys.spawns]) do
                if zoneId ~= 0 then
                    if not mop[npcId][npcKeys.zoneID] or mop[npcId][npcKeys.zoneID] == 0 then
                        mop[npcId][npcKeys.zoneID] = zoneId
                    end
                    mop[npcId][npcKeys.spawns][zoneId] = trinityNpc[npcKeys.spawns][zoneId]
                end
            end
        end
    end

    local wowheadNpc = mopWowhead[npcId]
    if wowheadNpc then
        mop[npcId][npcKeys.friendlyToFaction] = wowheadNpc[npcKeys.friendlyToFaction]
        if not data[npcKeys.spawns] and wowheadNpc[npcKeys.spawns] then
            mop[npcId][npcKeys.spawns] = {}
            for zoneId, _ in pairs(wowheadNpc[npcKeys.spawns]) do
                -- Filter out non-MoP zones
                if zoneId <= 6852 or zoneId == 14288 or zoneId == 14334 or zoneId == 15306 or zoneId == 15318 then
                    if not mop[npcId][npcKeys.zoneID] or mop[npcId][npcKeys.zoneID] == 0 then
                        mop[npcId][npcKeys.zoneID] = zoneId
                    end
                    mop[npcId][npcKeys.spawns][zoneId] = wowheadNpc[npcKeys.spawns][zoneId]
                end
            end
        end
        if not data[npcKeys.questStarts] then
            mop[npcId][npcKeys.questStarts] = wowheadNpc[npcKeys.questStarts]
        end
        if not data[npcKeys.questEnds] then
            mop[npcId][npcKeys.questEnds] = wowheadNpc[npcKeys.questEnds]
        end
    end

    -- Override mop entry with cata, since the data is better
    local cataNpc = cata[npcId]
    if cataNpc then
        mop[npcId] = cataNpc
    end
end

-- add cata NPCs that are not in mop
for npcId, data in pairs(cata) do
    if not mop[npcId] then
        mop[npcId] = data
    end
end

-- add trinity NPCs that are not in mop
for npcId, data in pairs(mopTrinity) do
    if not mop[npcId] then
        mop[npcId] = data
    end
end

local function pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
    end
    return iter
end

-- print to "merged-file.lua"
local file = io.open("merged-file.lua", "w")
print("writing to merged-file.lua")
for npcId, data in pairsByKeys(mop) do
    -- build print string with npcId and data
    local printString = "[" .. npcId .. "] = {"
    printString = printString .. "'" .. data[npcKeys.name]:gsub("'", "\\'") .. "',"
    printString = printString .. data[npcKeys.minLevelHealth] .. ","
    printString = printString .. data[npcKeys.maxLevelHealth] .. ","
    printString = printString .. data[npcKeys.minLevel] .. ","
    printString = printString .. data[npcKeys.maxLevel] .. ","
    printString = printString .. data[npcKeys.rank] .. ","
    if data[npcKeys.spawns] then
        printString = printString .. "{"
        for zoneID, coords in pairsByKeys(data[npcKeys.spawns]) do
            printString = printString .. "[" .. zoneID .. "]={"
            for i, coord in ipairs(coords) do
                if coords[i+1] then
                    if coord[3] then
                        printString = printString .. "{" .. coord[1] .. "," .. coord[2] .. "," .. coord[3] .. "},"
                    else
                        printString = printString .. "{" .. coord[1] .. "," .. coord[2] .. "},"
                    end
                else
                    if coord[3] then
                        printString = printString .. "{" .. coord[1] .. "," .. coord[2] .. "," .. coord[3] .. "}"
                    else
                        printString = printString .. "{" .. coord[1] .. "," .. coord[2] .. "}"
                    end
                end
            end
            printString = printString .. "},"
        end
        printString = printString:sub(1, -2) -- remove trailing comma
        printString = printString .. "},"
    else
        printString = printString .. "nil,"
    end
    if data[npcKeys.waypoints] then
        printString = printString .. "{"
        for zoneID, coords in pairs(data[npcKeys.waypoints]) do
            printString = printString .. "[" .. zoneID .. "]={{"
            for i, coord in pairs(coords[1]) do
                if coords[1][i+1] then
                    printString = printString .. "{" .. coord[1] .. "," .. coord[2] .. "},"
                else
                    printString = printString .. "{" .. coord[1] .. "," .. coord[2] .. "}"
                end
            end
            printString = printString .. "}},"
        end
        printString = printString:sub(1, -2) -- remove trailing comma
        printString = printString .. "},"
    else
        printString = printString .. "nil,"
    end
    printString = printString .. data[npcKeys.zoneID] .. ","
    if data[npcKeys.questStarts] then
        printString = printString .. "{"
        for i, questID in ipairs(data[npcKeys.questStarts]) do
            printString = printString .. questID .. ","
        end
        if printString:sub(-1) == "," then
            printString = printString:sub(1, -2) -- remove trailing comma
        end
        printString = printString .. "},"
    else
        printString = printString .. "nil,"
    end
    if data[npcKeys.questEnds] then
        printString = printString .. "{"
        for i, questID in ipairs(data[npcKeys.questEnds]) do
            printString = printString .. questID .. ","
        end
        if printString:sub(-1) == "," then
            printString = printString:sub(1, -2) -- remove trailing comma
        end
        printString = printString .. "},"
    else
        printString = printString .. "nil,"
    end
    printString = printString .. data[npcKeys.factionID] .. ","
    if data[npcKeys.friendlyToFaction] then
        printString = printString .. "\"" .. data[npcKeys.friendlyToFaction] .. "\","
    else
        printString = printString .. "nil,"
    end
    if data[npcKeys.subName] then
        printString = printString .. "\"" .. data[npcKeys.subName]:gsub("\"", "\\\"") .. "\","
    else
        printString = printString .. "nil,"
    end
    printString = printString .. data[npcKeys.npcFlags]
    printString = printString .. "},"
    file:write(printString .. "\n")
end
print("Done")
