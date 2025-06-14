local Validators = {}

---@param quests table
---@param questKeys DatabaseQuestKeys
function Validators.checkRequiredSourceItems(quests, questKeys)
    print("\n\27[36mSearching for sourceItemId and itemObjectiveId entries in quest.requiredSourceItems...\27[0m")
    local matchingQuests = {}
    for questId, questData in pairs(quests) do
        local sourceItemId = questData[questKeys.sourceItemId]
        local requiredSourceItems = questData[questKeys.requiredSourceItems]
        if sourceItemId and requiredSourceItems then
            for index = 1, #requiredSourceItems do
                if requiredSourceItems[index] == sourceItemId then
                    matchingQuests[questId] = "sourceItemId in requiredSourceItems: " .. sourceItemId
                    break
                end
            end
        end

        local objectives = questData[questKeys.objectives]
        if requiredSourceItems and objectives and objectives[3] then
            for _, itemObjective in pairs(objectives[3]) do
                for index = 1, #requiredSourceItems do
                    if requiredSourceItems[index] == itemObjective[1] then
                        matchingQuests[questId] = "itemObjectiveId in requiredSourceItems: " .. itemObjective[1]
                        break
                    end
                end
            end
        end
    end

    local count = 0
    for _ in pairs(matchingQuests) do count = count + 1 end

    if count > 0 then
        print("\27[31mFound " .. count .. " quests with sourceItemId or itemObjectiveId in requiredSourceItems:\27[0m")
        for questId, reason in pairs(matchingQuests) do
            print("\27[31m- Quest " .. questId .. " (" .. reason .. ")\27[0m")
        end

        os.exit(1)
        return matchingQuests
    else
        print("\27[32mNo quests found with sourceItemId or itemObjectiveId in requiredSourceItems\27[0m")
        return nil
    end
end

---@param quests table
---@param questKeys DatabaseQuestKeys
function Validators.checkPreQuestExclusiveness(quests, questKeys)
    print("\n\27[36mSearching for quests with preQuestSingle and preQuestGroup entries...\27[0m")
    local invalidQuests = {}
    for questId, questData in pairs(quests) do
        local preQuestSingle = questData[questKeys.preQuestSingle]
        local preQuestGroup = questData[questKeys.preQuestGroup]
        if preQuestSingle and next(preQuestSingle) and preQuestGroup and next(preQuestGroup) then
            invalidQuests[questId] = true
        end
    end

    local count = 0
    for _ in pairs(invalidQuests) do count = count + 1 end

    if count > 0 then
        print("\27[31mFound " .. count .. " quests with both preQuestSingle and preQuestGroup entries:\27[0m")
        for questId, _ in pairs(invalidQuests) do
            print("\27[31m- Quest " .. questId .. "\27[0m")
        end

        os.exit(1)
        return invalidQuests
    else
        print("\27[32mNo quests found with both preQuestSingle and preQuestGroup entries\27[0m")
        return nil
    end
end

---If a quest has a parent quest, then the parent quest must have the child quest in its childQuests list.
---This also must hold vice versa: If a quest has child quests, then each child quest must have the parent quest set.
---@param quests table
---@param questKeys DatabaseQuestKeys
function Validators.checkParentChildQuestRelations(quests, questKeys)
    print("\n\27[36mSearching for parent and child quest relations...\27[0m")
    local invalidQuests = {}
    for questId, questData in pairs(quests) do
        local parentQuestId = questData[questKeys.parentQuest]
        if parentQuestId and parentQuestId > 0 then
            local parentQuest = quests[parentQuestId]

            if (not parentQuest) then
                invalidQuests[questId] = "parent quest " .. parentQuestId .. " is missing/hidden in the database"
            elseif (not parentQuest[questKeys.childQuests]) then
                invalidQuests[parentQuestId] = "quest has no childQuests. " .. questId .. " is listing it as parent quest"
            else
                local found = false
                for _, childQuestId in pairs(parentQuest[questKeys.childQuests]) do
                    if childQuestId == questId then
                        found = true
                        break
                    end
                end

                if (not found) then
                    invalidQuests[parentQuestId] = "quest " .. questId .. " is missing in childQuests list"
                end
            end
        end

        local childQuests = questData[questKeys.childQuests]
        if childQuests then
            for _, childQuestId in pairs(childQuests) do
                local childQuest = quests[childQuestId]
                if (not childQuest) then
                    invalidQuests[childQuestId] = "quest is missing/hidden in the database. parentQuest is " .. questId
                elseif (not childQuest[questKeys.parentQuest]) then
                    invalidQuests[childQuestId] = "quest has no parentQuest. " .. questId .. " is listing it as child quest"
                end
            end
        end
    end

    local count = 0
    for _ in pairs(invalidQuests) do count = count + 1 end

    if count > 0 then
        print("\27[31mFound " .. count .. " quests with invalid parent and child quest relations:\27[0m")
        for questId, reason in pairs(invalidQuests) do
            print("\27[31m- Quest " .. questId .. " (" .. reason .. ")\27[0m")
        end

        os.exit(1)
        return invalidQuests
    else
        print("\27[32mNo quests found with invalid parent and child quest relations\27[0m")
        return nil
    end
end

function Validators.checkQuestStarters(quests, questKeys, npcs, objects, items)
    print("\n\27[36mSearching for quest starters...\27[0m")
    local invalidQuests = {}
    for questId, questData in pairs(quests) do
        local startedBy = questData[questKeys.startedBy]
        if startedBy then
            for _, npcStarter in pairs(startedBy[1] or {}) do
                if not npcs[npcStarter] then
                    invalidQuests[questId] = "NPC starter " .. npcStarter .. " is missing in the database"
                end
            end
            for _, objectStarter in pairs(startedBy[2] or {}) do
                if not objects[objectStarter] then
                    invalidQuests[questId] = "Object starter " .. objectStarter .. " is missing in the database"
                end
            end
            for _, itemStarter in pairs(startedBy[3] or {}) do
                if not items[itemStarter] then
                    invalidQuests[questId] = "Item starter " .. itemStarter .. " is missing in the database"
                end
            end
        end
    end

    local count = 0
    for _ in pairs(invalidQuests) do count = count + 1 end

    if count > 0 then
        print("\27[31mFound " .. count .. " quests with invalid quest starters:\27[0m")
        for questId, reason in pairs(invalidQuests) do
            print("\27[31m- Quest " .. questId .. " (" .. reason .. ")\27[0m")
        end

        os.exit(1)
        return invalidQuests
    else
        print("\27[32mNo quests found with invalid quest starters\27[0m")
        return nil
    end
end

function Validators.checkObjectives(quests, questKeys, npcs, objects, items)
    print("\n\27[36mSearching for invalid quest objectives...\27[0m")
    local invalidQuests = {}
    for questId, questData in pairs(quests) do
        local objectives = questData[questKeys.objectives]
        if objectives then
            for _, npcObjective in pairs(objectives[1] or {}) do
                local npcId = npcObjective[1]
                if not npcs[npcId] then
                    if not invalidQuests[questId] then
                        invalidQuests[questId] = {}
                    end
                    table.insert(invalidQuests[questId], "NPC objective " .. npcId .. " is missing in the database")
                end
            end
            for _, objectObjective in pairs(objectives[2] or {}) do
                local objectId = objectObjective[1]
                if not objects[objectId] then
                    if not invalidQuests[questId] then
                        invalidQuests[questId] = {}
                    end
                    table.insert(invalidQuests[questId], "Object objective " .. objectId .. " is missing in the database")
                end
            end
            for _, itemObjective in pairs(objectives[3] or {}) do
                local itemId = itemObjective[1]
                if not items[itemId] then
                    if not invalidQuests[questId] then
                        invalidQuests[questId] = {}
                    end
                    table.insert(invalidQuests[questId], "Item objective " .. itemId .. " is missing in the database")
                end
            end
        end
    end

    local count = 0
    for _ in pairs(invalidQuests) do count = count + 1 end

    if count > 0 then
        print("\27[31mFound " .. count .. " quests with invalid objectives:\27[0m")
        for questId, reasons in pairs(invalidQuests) do
            print("\27[31m- Quest " .. questId .. ":")
            for _, reason in ipairs(reasons) do
                print("  - " .. reason)
            end
            print("\27[0m")
        end

        os.exit(1)
        return invalidQuests
    else
        print("\27[32mNo quests found with invalid objectives\27[0m")
        return nil
    end
end

return Validators
