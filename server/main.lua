print('[Crime Laptop] Server script loading...')

CreateThread(function()
    while not exports.oxmysql do
        Wait(100)
    end

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `crime_laptop_profiles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `license` VARCHAR(60) NOT NULL UNIQUE,
            `username` VARCHAR(50) NOT NULL UNIQUE,
            `crypto` INT DEFAULT 0,
            `jobs_completed` INT DEFAULT 0,
            `items_sold` INT DEFAULT 0,
            `total_earned` INT DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `crime_laptop_listings` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `seller_license` VARCHAR(60) NOT NULL,
            `seller_username` VARCHAR(50) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `item_label` VARCHAR(100) NOT NULL,
            `amount` INT NOT NULL DEFAULT 1,
            `price` INT NOT NULL,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_seller` (`seller_license`),
            INDEX `idx_item` (`item_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `crime_laptop_crypto_history` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `license` VARCHAR(60) NOT NULL,
            `type` VARCHAR(20) NOT NULL,
            `amount` INT NOT NULL,
            `description` VARCHAR(255) DEFAULT '',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    exports.oxmysql:execute([[
        ALTER TABLE `crime_laptop_listings`
        ADD COLUMN IF NOT EXISTS `status` ENUM('pending', 'active', 'sold', 'cancelled') DEFAULT 'pending'
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS `crime_laptop_purchases` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `buyer_license` VARCHAR(60) NOT NULL,
            `listing_id` INT NOT NULL,
            `pickup_name` VARCHAR(100) NOT NULL,
            `status` ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX `idx_buyer` (`buyer_license`),
            INDEX `idx_listing` (`listing_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    DebugPrint('Database tables ready')
end)

local function GetPlayerLicense(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, 'license:') then
            return id
        end
    end
    return nil
end

local function GetProfile(source)
    local license = GetPlayerLicense(source)
    if not license then return nil end
    return Profiles.GetByLicense(license)
end

local function NotifyClient(source, message, msgType)
    TriggerClientEvent('crime_laptop:client:notify', source, message, msgType or 'info')
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    DebugPrint('Crime Laptop resource started on server')
end)

RegisterNetEvent('crime_laptop:server:requestOpen', function()
    local source = source
    print('[Crime Laptop] Server received requestOpen from player ' .. source)
    local profile = GetProfile(source)
    if profile then
        print('[Crime Laptop] Profile found: ' .. profile.username)
        TriggerClientEvent('crime_laptop:client:openLaptop', source, true, profile)
    else
        print('[Crime Laptop] No profile found, showing login')
        TriggerClientEvent('crime_laptop:client:openLaptop', source, false, nil)
    end
end)

RegisterNetEvent('crime_laptop:server:register', function(username)
    local source = source

    local license = GetPlayerLicense(source)
    if not license then
        TriggerClientEvent('crime_laptop:client:openLaptop', source, false, nil, 'License not found')
        return
    end

    if not username or #username < 3 then
        TriggerClientEvent('crime_laptop:client:openLaptop', source, false, nil, 'Alias must be at least 3 characters')
        return
    end

    if #username > 20 then
        TriggerClientEvent('crime_laptop:client:openLaptop', source, false, nil, 'Alias must be 20 characters or less')
        return
    end

    if not string.match(username, '^[%w_]+$') then
        TriggerClientEvent('crime_laptop:client:openLaptop', source, false, nil, 'Alias can only contain letters, numbers, and underscores')
        return
    end

    local profile, err = Profiles.Create(license, username)

    if profile then
        print('[Crime Laptop] Player ' .. source .. ' registered as: ' .. username)
        TriggerClientEvent('crime_laptop:client:openLaptop', source, true, profile)
    else
        print('[Crime Laptop] Registration failed for ' .. source .. ': ' .. tostring(err))
        TriggerClientEvent('crime_laptop:client:openLaptop', source, false, nil, err or 'Registration failed')
    end
end)

RegisterNetEvent('crime_laptop:server:getProfile', function()
    local source = source
    local profile = GetProfile(source)
    if profile then
        TriggerClientEvent('crime_laptop:client:profileData', source, profile)
    end
end)

RegisterNetEvent('crime_laptop:server:changeAlias', function(newAlias)
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    if not newAlias or #newAlias < 3 or #newAlias > 20 then
        NotifyClient(source, 'Alias must be 3-20 characters', 'error')
        return
    end

    local success, err = Profiles.UpdateUsername(license, newAlias)
    if success then
        local profile = GetProfile(source)
        TriggerClientEvent('crime_laptop:client:profileData', source, profile)
        NotifyClient(source, 'Alias changed to: ' .. newAlias, 'success')
    else
        NotifyClient(source, err or 'Failed to change alias', 'error')
    end
end)

RegisterNetEvent('crime_laptop:server:getListings', function(search, filter)
    local source = source
    local listings = BlackMarket.GetListings(search, filter)
    TriggerClientEvent('crime_laptop:client:listingsData', source, listings)
end)

RegisterNetEvent('crime_laptop:server:getPendingListings', function()
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local listings = BlackMarket.GetPlayerListings(license)
    local pending = {}
    for _, listing in ipairs(listings) do
        if listing.status == 'pending' then
            pending[#pending + 1] = listing
        end
    end
    TriggerClientEvent('crime_laptop:client:pendingListings', source, pending)
end)

RegisterNetEvent('crime_laptop:server:getInventory', function()
    local source = source
    local items = {}

    if FrameworkName == 'ox_inventory' then
        local inventory = exports['ox_inventory']:GetInventory(source, false)
        if inventory and inventory.items then
            for _, item in pairs(inventory.items) do
                if item.count > 0 and not item.weapon then
                    items[#items + 1] = {
                        name = item.name,
                        label = item.label or item.name,
                        count = item.count
                    }
                end
            end
        end
    elseif FrameworkName == 'qbox' then
        local player = exports['qbx_core']:GetPlayer(source)
        if player then
            for _, item in pairs(player.PlayerData.items) do
                if item.amount > 0 then
                    items[#items + 1] = {
                        name = item.name,
                        label = item.label or item.name,
                        count = item.amount
                    }
                end
            end
        end
    elseif FrameworkName == 'qb-core' then
        local player = Framework.Functions.GetPlayer(source)
        if player then
            for _, item in pairs(player.PlayerData.items) do
                if item.amount > 0 then
                    items[#items + 1] = {
                        name = item.name,
                        label = item.label or item.name,
                        count = item.amount
                    }
                end
            end
        end
    elseif FrameworkName == 'esx' then
        local player = Framework.GetPlayerFromId(source)
        if player then
            for _, item in pairs(player.getInventory()) do
                if item.count > 0 then
                    items[#items + 1] = {
                        name = item.name,
                        label = item.label or item.name,
                        count = item.count
                    }
                end
            end
        end
    end

    TriggerClientEvent('crime_laptop:client:inventoryData', source, items)
end)

RegisterNetEvent('crime_laptop:server:createListing', function(data)
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local profile = GetProfile(source)
    if not profile then
        NotifyClient(source, 'Profile not found', 'error')
        return
    end

    local itemName = data.itemName
    local itemLabel = data.itemLabel
    local amount = data.amount or 1
    local price = data.price or 0

    if not itemName or not itemLabel then
        NotifyClient(source, 'Invalid item data', 'error')
        return
    end

    if amount < 1 then
        NotifyClient(source, 'Amount must be at least 1', 'error')
        return
    end

    if price < 1 then
        NotifyClient(source, 'Price must be at least 1 CRM', 'error')
        return
    end

    local hasItem = FrameworkHasItem(source, itemName)
    if not hasItem then
        NotifyClient(source, 'You don\'t have this item', 'error')
        return
    end

    local success, err = BlackMarket.CreatePendingListing(license, profile.username, itemName, itemLabel, amount, price)
    if success then
        local dropoffIndex = math.random(#Config.DropoffLocations)
        local dropoff = Config.DropoffLocations[dropoffIndex]
        TriggerClientEvent('crime_laptop:client:setDropoff', source, dropoff)
        NotifyClient(source, 'Listing created! Go to ' .. dropoff.name .. ' to drop off the item.', 'success')
    else
        NotifyClient(source, err or 'Failed to create listing', 'error')
    end
end)

RegisterNetEvent('crime_laptop:server:depositListing', function(listingId)
    local source = source
    print('[Crime Laptop] depositListing called by player ' .. source .. ' for listing ' .. tostring(listingId))
    local license = GetPlayerLicense(source)
    if not license then return end

    local listing = BlackMarket.GetPendingListing(listingId)
    if not listing then
        print('[Crime Laptop] No pending listing found for id: ' .. tostring(listingId))
        NotifyClient(source, 'Listing not found or already deposited', 'error')
        return
    end

    if listing.seller_license ~= license then
        NotifyClient(source, 'This is not your listing', 'error')
        return
    end

    BlackMarket.ActivateListing(listingId)
    NotifyClient(source, 'Item deposited! Listing is now active on the Black Market.', 'success')

    local listings = BlackMarket.GetListings('', 'all')
    TriggerClientEvent('crime_laptop:client:listingsData', source, listings)
end)

RegisterNetEvent('crime_laptop:server:depositAtDropoff', function()
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local profile = GetProfile(source)
    if not profile then return end

    local allListings = BlackMarket.GetPlayerListings(license)

    for _, listing in ipairs(allListings) do
        if listing.status == 'pending' then
            local hasItem = FrameworkHasItem(source, listing.item_name)
            if not hasItem then
                NotifyClient(source, 'You don\'t have the required item: ' .. listing.item_label, 'error')
                return
            end

            local removed = FrameworkRemoveItem(source, listing.item_name, listing.amount)
            if not removed then
                NotifyClient(source, 'Failed to remove item from inventory', 'error')
                return
            end

            BlackMarket.ActivateListing(listing.id)
            NotifyClient(source, 'Item deposited! Listing is now active on the Black Market.', 'success')
            TriggerClientEvent('crime_laptop:client:clearDropoff', source)

            local myListings = BlackMarket.GetPlayerListings(license)
            TriggerClientEvent('crime_laptop:client:myListingsData', source, myListings)
            return
        end
    end

    for _, listing in ipairs(allListings) do
        if listing.status == 'cancelled' then
            FrameworkGiveItem(source, listing.item_name, listing.amount)
            BlackMarket.DeleteListing(listing.id)
            NotifyClient(source, 'Collected ' .. listing.amount .. 'x ' .. listing.item_label, 'success')
            TriggerClientEvent('crime_laptop:client:clearDropoff', source)

            local myListings = BlackMarket.GetPlayerListings(license)
            TriggerClientEvent('crime_laptop:client:myListingsData', source, myListings)
            return
        end
    end

    local p = promise.new()
    exports.oxmysql:execute(
        'SELECT * FROM crime_laptop_purchases WHERE buyer_license = ? AND status = ?',
        { license, 'pending' },
        function(result)
            p:resolve(result)
        end
    )
    local purchases = Citizen.Await(p)

    if purchases and purchases[1] then
        local purchase = purchases[1]
        local listing = BlackMarket.GetListing(purchase.listing_id)

        if not listing then
            NotifyClient(source, 'Listing no longer available', 'error')
            exports.oxmysql:execute('DELETE FROM crime_laptop_purchases WHERE id = ?', { purchase.id })
            TriggerClientEvent('crime_laptop:client:clearDropoff', source)
            return
        end

        if buyerProfile.crypto < listing.price then
            NotifyClient(source, 'Insufficient CRM. You need ' .. listing.price .. ' CRM', 'error')
            exports.oxmysql:execute('DELETE FROM crime_laptop_purchases WHERE id = ?', { purchase.id })
            TriggerClientEvent('crime_laptop:client:clearDropoff', source)
            return
        end

        local success, err = Profiles.RemoveCrypto(license, listing.price, 'Black Market purchase: ' .. listing.item_label)
        if not success then
            NotifyClient(source, err or 'Insufficient CRM', 'error')
            exports.oxmysql:execute('DELETE FROM crime_laptop_purchases WHERE id = ?', { purchase.id })
            TriggerClientEvent('crime_laptop:client:clearDropoff', source)
            return
        end

        Profiles.AddCrypto(listing.seller_license, listing.price, 'Black Market sale: ' .. listing.item_label)
        Profiles.IncrementStat(listing.seller_license, 'items_sold', listing.amount)
        Profiles.IncrementStat(listing.seller_license, 'total_earned', listing.price)

        BlackMarket.DeleteListing(listing.id)

        local given = FrameworkGiveItem(source, listing.item_name, listing.amount)
        if not given then
            Profiles.AddCrypto(license, listing.price, 'Refund: purchase failed')
            NotifyClient(source, 'Failed to give item', 'error')
            exports.oxmysql:execute('DELETE FROM crime_laptop_purchases WHERE id = ?', { purchase.id })
            TriggerClientEvent('crime_laptop:client:clearDropoff', source)
            return
        end

        exports.oxmysql:execute('UPDATE crime_laptop_purchases SET status = ? WHERE id = ?', { 'completed', purchase.id })

        NotifyClient(source, 'Collected ' .. listing.amount .. 'x ' .. listing.item_label .. '!', 'success')
        TriggerClientEvent('crime_laptop:client:clearDropoff', source)

        local sellerSource = nil
        for _, playerId in ipairs(GetPlayers()) do
            local playerLicense = GetPlayerLicense(tonumber(playerId))
            if playerLicense == listing.seller_license then
                sellerSource = tonumber(playerId)
                break
            end
        end

        if sellerSource then
            NotifyClient(sellerSource, 'Your listing sold: ' .. listing.amount .. 'x ' .. listing.item_label .. ' for ' .. listing.price .. ' CRM', 'success')
        end

        local myListings = BlackMarket.GetPlayerListings(license)
        TriggerClientEvent('crime_laptop:client:myListingsData', source, myListings)
        return
    end

    NotifyClient(source, 'Nothing to collect or deposit', 'error')
end)

RegisterNetEvent('crime_laptop:server:getMyListings', function()
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local listings = BlackMarket.GetPlayerListings(license)
    TriggerClientEvent('crime_laptop:client:myListingsData', source, listings)
end)

RegisterNetEvent('crime_laptop:server:cancelListing', function(data)
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local listingId = data.listingId
    local listing = BlackMarket.GetListing(listingId)

    if not listing then
        NotifyClient(source, 'Listing not found', 'error')
        return
    end

    if listing.seller_license ~= license then
        NotifyClient(source, 'This is not your listing', 'error')
        return
    end

    if listing.status ~= 'active' and listing.status ~= 'pending' then
        NotifyClient(source, 'Cannot cancel this listing', 'error')
        return
    end

    BlackMarket.CancelListing(listingId, license)

    if listing.status == 'pending' then
        TriggerClientEvent('crime_laptop:client:clearDropoff', source)
        NotifyClient(source, 'Listing cancelled. Drop-off removed.', 'success')
    elseif listing.status == 'active' then
        local dropoffIndex = math.random(#Config.DropoffLocations)
        local dropoff = Config.DropoffLocations[dropoffIndex]
        TriggerClientEvent('crime_laptop:client:setDropoff', source, dropoff)
        BlackMarket.CreateCancelledListing(license, profile.username, listing.item_name, listing.item_label, listing.amount, listing.price)
        NotifyClient(source, 'Listing cancelled. Go to ' .. dropoff.name .. ' to collect your item.', 'success')
    end

    local myListings = BlackMarket.GetPlayerListings(license)
    TriggerClientEvent('crime_laptop:client:myListingsData', source, myListings)
end)

RegisterNetEvent('crime_laptop:server:buyListing', function(listingId)
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local listing = BlackMarket.GetListing(listingId)
    if not listing then
        NotifyClient(source, 'Listing not found', 'error')
        return
    end

    if listing.status ~= 'active' then
        NotifyClient(source, 'This listing is no longer available', 'error')
        return
    end

    if listing.seller_license == license then
        NotifyClient(source, 'You cannot buy your own listing', 'error')
        return
    end

    local buyerProfile = GetProfile(source)
    if not buyerProfile then
        NotifyClient(source, 'Profile not found', 'error')
        return
    end

    if buyerProfile.crypto < listing.price then
        NotifyClient(source, 'Insufficient CRM. You need ' .. listing.price .. ' CRM', 'error')
        return
    end

    local pickupIndex = math.random(#Config.DropoffLocations)
    local pickup = Config.DropoffLocations[pickupIndex]

    local p = promise.new()
    exports.oxmysql:insert(
        'INSERT INTO crime_laptop_purchases (buyer_license, listing_id, pickup_name, status) VALUES (?, ?, ?, ?)',
        { license, listingId, pickup.name, 'pending' },
        function(result)
            p:resolve(result)
        end
    )
    Citizen.Await(p)

    TriggerClientEvent('crime_laptop:client:setDropoff', source, pickup)
    NotifyClient(source, 'Purchase initiated! Go to ' .. pickup.name .. ' to collect your item.', 'success')
end)

RegisterNetEvent('crime_laptop:server:transferCrypto', function(toUsername, amount)
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    if not toUsername or #toUsername < 3 then
        NotifyClient(source, 'Invalid recipient alias', 'error')
        return
    end

    if not amount or amount <= 0 then
        NotifyClient(source, 'Invalid amount', 'error')
        return
    end

    local fromProfile = GetProfile(source)
    if not fromProfile then
        NotifyClient(source, 'Profile not found', 'error')
        return
    end

    if fromProfile.crypto < amount then
        NotifyClient(source, 'Insufficient CRM', 'error')
        return
    end

    local toProfile = Profiles.GetByUsername(toUsername)
    if not toProfile then
        NotifyClient(source, 'Recipient not found', 'error')
        return
    end

    if toProfile.license == license then
        NotifyClient(source, 'Cannot transfer to yourself', 'error')
        return
    end

    local success, err = Profiles.TransferCrypto(license, toProfile.license, amount, 'Transfer to ' .. toUsername)
    if success then
        NotifyClient(source, 'Sent ' .. amount .. ' CRM to ' .. toUsername, 'success')
        local profile = GetProfile(source)
        if profile then
            TriggerClientEvent('crime_laptop:client:profileData', source, profile)
        end
    else
        NotifyClient(source, err or 'Transfer failed', 'error')
    end
end)

RegisterNetEvent('crime_laptop:server:getCryptoHistory', function()
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local history = Profiles.GetCryptoHistory(license, 50)
    TriggerClientEvent('crime_laptop:client:cryptoHistory', source, history)
end)

RegisterNetEvent('crime_laptop:server:getCryptoGraph', function()
    local source = source
    local license = GetPlayerLicense(source)
    if not license then return end

    local history = Profiles.GetCryptoHistoryForGraph(license)
    TriggerClientEvent('crime_laptop:client:cryptoGraph', source, history)
end)

RegisterCommand('resetprofile', function(source, args, rawCommand)
    if source ~= 0 then
        print('[Crime Laptop] This command can only be run from the server console')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        print('[Crime Laptop] Usage: resetprofile <playerServerId>')
        print('[Crime Laptop] This will delete the player\'s profile, listings, and crypto history')
        return
    end

    local license = GetPlayerLicense(targetId)
    if not license then
        print('[Crime Laptop] No license found for player ' .. targetId .. ' (player may be offline)')
        return
    end

    print('[Crime Laptop] Resetting profile for player ' .. targetId .. ' (license: ' .. license .. ')')

    exports.oxmysql:execute('DELETE FROM ' .. Config.Database.profiles .. ' WHERE license = ?', { license })
    exports.oxmysql:execute('DELETE FROM ' .. Config.Database.listings .. ' WHERE seller_license = ?', { license })
    exports.oxmysql:execute('DELETE FROM ' .. Config.Database.crypto_history .. ' WHERE license = ?', { license })

    print('[Crime Laptop] Profile reset complete for player ' .. targetId)
end, false)
