FrameworkName = nil
Framework = nil

local function DetectFramework()
    if GetResourceState('ox_inventory') == 'started' then
        FrameworkName = 'ox_inventory'
    elseif GetResourceState('qbx_core') == 'started' then
        FrameworkName = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
        FrameworkName = 'qb-core'
    elseif GetResourceState('es_extended') == 'started' then
        Framework = exports['es_extended']:getSharedObject()
        FrameworkName = 'esx'
    end
    DebugPrint('Framework: ' .. tostring(FrameworkName))
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DetectFramework()
end)

CreateThread(function()
    DetectFramework()
end)

function FrameworkNotify(playerId, msg, msgType)
    if not FrameworkName then return end
    if IsDuplicityVersion() then
        if FrameworkName == 'ox_inventory' or FrameworkName == 'qbox' then
            TriggerClientEvent('ox_lib:notify', playerId, { description = msg, type = msgType or 'inform' })
        elseif FrameworkName == 'qb-core' then
            TriggerClientEvent('QBCore:Notify', playerId, msg, msgType or 'primary')
        elseif FrameworkName == 'esx' then
            TriggerClientEvent('esx:showNotification', playerId, msg)
        end
    else
        if FrameworkName == 'ox_inventory' or FrameworkName == 'qbox' then
            exports['ox_lib']:notify({ description = msg, type = msgType or 'inform' })
        elseif FrameworkName == 'qb-core' then
            TriggerEvent('QBCore:Notify', msg, msgType or 'primary')
        elseif FrameworkName == 'esx' then
            TriggerEvent('esx:showNotification', msg)
        end
    end
end

function FrameworkHasItem(playerId, itemName)
    if not FrameworkName then return false end
    if FrameworkName == 'ox_inventory' then
        if IsDuplicityVersion() then
            local result = exports['ox_inventory']:Search(playerId, 'count', itemName)
            if type(result) == 'number' then return result > 0 end
            if type(result) == 'table' and result[itemName] then return result[itemName] > 0 end
            return false
        else
            local result = exports['ox_inventory']:Search('count', itemName)
            if type(result) == 'number' then return result > 0 end
            if type(result) == 'table' and result[itemName] then return result[itemName] > 0 end
            return false
        end
    elseif FrameworkName == 'qbox' then
        local player = exports['qbx_core']:GetPlayer(playerId)
        return player and player.Functions.GetItemByName(itemName) ~= nil
    elseif FrameworkName == 'qb-core' then
        local player = Framework.Functions.GetPlayer(playerId)
        return player and player.Functions.GetItemByName(itemName) ~= nil
    elseif FrameworkName == 'esx' then
        local player = Framework.GetPlayerFromId(playerId)
        local item = player and player.getInventoryItem(itemName)
        return item and item.count > 0
    end
    return false
end

function FrameworkGiveItem(playerId, itemName, amount)
    if not FrameworkName then return false end
    if FrameworkName == 'ox_inventory' then
        return exports['ox_inventory']:AddItem(playerId, itemName, amount)
    elseif FrameworkName == 'qbox' then
        local player = exports['qbx_core']:GetPlayer(playerId)
        if not player then return false end
        player.Functions.AddItem(itemName, amount)
        return true
    elseif FrameworkName == 'qb-core' then
        local player = Framework.Functions.GetPlayer(playerId)
        if not player then return false end
        player.Functions.AddItem(itemName, amount)
        return true
    elseif FrameworkName == 'esx' then
        local player = Framework.GetPlayerFromId(playerId)
        if not player then return false end
        player.addInventoryItem(itemName, amount)
        return true
    end
    return false
end

function FrameworkRemoveItem(playerId, itemName, amount)
    if not FrameworkName then return false end
    if FrameworkName == 'ox_inventory' then
        return exports['ox_inventory']:RemoveItem(playerId, itemName, amount)
    elseif FrameworkName == 'qbox' then
        local player = exports['qbx_core']:GetPlayer(playerId)
        if not player then return false end
        player.Functions.RemoveItem(itemName, amount)
        return true
    elseif FrameworkName == 'qb-core' then
        local player = Framework.Functions.GetPlayer(playerId)
        if not player then return false end
        player.Functions.RemoveItem(itemName, amount)
        return true
    elseif FrameworkName == 'esx' then
        local player = Framework.GetPlayerFromId(playerId)
        if not player then return false end
        player.removeInventoryItem(itemName, amount)
        return true
    end
    return false
end

function FrameworkGetPlayerName(source)
    if not FrameworkName then return 'Unknown' end
    if FrameworkName == 'qbox' then
        local player = exports['qbx_core']:GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.charinfo then
            return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end
    elseif FrameworkName == 'qb-core' then
        local player = Framework.Functions.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.charinfo then
            return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end
    elseif FrameworkName == 'esx' then
        local player = Framework.GetPlayerFromId(source)
        if player then
            return player.getName()
        end
    end
    return GetPlayerName(source)
end
