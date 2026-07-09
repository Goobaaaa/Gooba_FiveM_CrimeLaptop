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
            `balance` INT DEFAULT 0,
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
        print('[Crime Laptop] Player ' .. source .. ' (' .. license .. ') registered as: ' .. username)
        TriggerClientEvent('crime_laptop:client:openLaptop', source, true, profile)
    else
        print('[Crime Laptop] Registration failed for player ' .. source .. ': ' .. tostring(err))
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

    if price < Config.BlackMarket.MinPrice then
        NotifyClient(source, 'Minimum price is $' .. Config.BlackMarket.MinPrice, 'error')
        return
    end

    local hasItem = FrameworkHasItem(source, itemName)
    if not hasItem then
        NotifyClient(source, 'You don\'t have this item', 'error')
        return
    end

    local removed = FrameworkRemoveItem(source, itemName, amount)
    if not removed then
        NotifyClient(source, 'Failed to remove item', 'error')
        return
    end

    local success, err = BlackMarket.CreateListing(license, profile.username, itemName, itemLabel, amount, price)
    if success then
        NotifyClient(source, 'Listing created', 'success')
        local listings = BlackMarket.GetListings('', 'all')
        TriggerClientEvent('crime_laptop:client:listingsData', source, listings)
    else
        FrameworkGiveItem(source, itemName, amount)
        NotifyClient(source, err or 'Failed to create listing', 'error')
    end
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

    if listing.seller_license == license then
        NotifyClient(source, 'You cannot buy your own listing', 'error')
        return
    end

    local buyerProfile = GetProfile(source)
    if not buyerProfile then
        NotifyClient(source, 'Profile not found', 'error')
        return
    end

    if buyerProfile.balance < listing.price then
        NotifyClient(source, 'Insufficient balance', 'error')
        return
    end

    local success, err = Profiles.RemoveBalance(license, listing.price)
    if not success then
        NotifyClient(source, err or 'Insufficient balance', 'error')
        return
    end

    Profiles.AddBalance(listing.seller_license, listing.price)
    Profiles.IncrementStat(listing.seller_license, 'items_sold', listing.amount)
    Profiles.IncrementStat(listing.seller_license, 'total_earned', listing.price)

    BlackMarket.DeleteListing(listingId)

    local given = FrameworkGiveItem(source, listing.item_name, listing.amount)
    if not given then
        Profiles.AddBalance(license, listing.price)
        NotifyClient(source, 'Failed to give item', 'error')
        return
    end

    NotifyClient(source, 'Purchased ' .. listing.amount .. 'x ' .. listing.item_label, 'success')

    local sellerSource = nil
    for _, playerId in ipairs(GetPlayers()) do
        local playerLicense = GetPlayerLicense(tonumber(playerId))
        if playerLicense == listing.seller_license then
            sellerSource = tonumber(playerId)
            break
        end
    end

    if sellerSource then
        NotifyClient(sellerSource, 'Your listing sold: ' .. listing.amount .. 'x ' .. listing.item_label .. ' for $' .. listing.price, 'success')
    end
end)

RegisterCommand('resetprofile', function(source, args, rawCommand)
    local targetId = tonumber(args[1]) or source
    local license = GetPlayerLicense(targetId)
    if not license then
        print('[Crime Laptop] No license found for player ' .. targetId)
        return
    end

    exports.oxmysql:execute('DELETE FROM ' .. Config.Database.profiles .. ' WHERE license = ?', { license })
    exports.oxmysql:execute('DELETE FROM ' .. Config.Database.listings .. ' WHERE seller_license = ?', { license })
    print('[Crime Laptop] Reset profile for player ' .. targetId .. ' (license: ' .. license .. ')')
end, false)
