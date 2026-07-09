local isLaptopOpen = false

local function OpenLaptop()
    if isLaptopOpen then return end
    isLaptopOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        hasProfile = false,
        profile = nil
    })

    TriggerServerEvent('crime_laptop:server:requestOpen')
end

local function CloseLaptop()
    if not isLaptopOpen then return end
    isLaptopOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNetEvent('crime_laptop:client:openLaptop', function(hasProfile, profile, errorMsg)
    SendNUIMessage({
        action = 'open',
        hasProfile = hasProfile,
        profile = profile,
        message = errorMsg
    })
end)

RegisterNetEvent('crime_laptop:client:profileData', function(profile)
    SendNUIMessage({
        action = 'profileData',
        profile = profile
    })
end)

RegisterNetEvent('crime_laptop:client:listingsData', function(listings)
    SendNUIMessage({
        action = 'listingsData',
        listings = listings
    })
end)

RegisterNetEvent('crime_laptop:client:notify', function(message, msgType)
    SendNUIMessage({
        action = 'notify',
        message = message,
        type = msgType or 'info'
    })
end)

RegisterNUICallback('register', function(data, cb)
    TriggerServerEvent('crime_laptop:server:register', data.username)
    cb({ ok = true })
end)

RegisterNUICallback('getProfile', function(data, cb)
    TriggerServerEvent('crime_laptop:server:getProfile')
    cb({ ok = true })
end)

RegisterNUICallback('changeAlias', function(data, cb)
    TriggerServerEvent('crime_laptop:server:changeAlias', data.alias)
    cb({ ok = true })
end)

RegisterNUICallback('getListings', function(data, cb)
    TriggerServerEvent('crime_laptop:server:getListings', data.search, data.filter)
    cb({ ok = true })
end)

RegisterNUICallback('createListing', function(data, cb)
    TriggerServerEvent('crime_laptop:server:createListing', data)
    cb({ ok = true })
end)

RegisterNUICallback('buyListing', function(data, cb)
    TriggerServerEvent('crime_laptop:server:buyListing', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('close', function(data, cb)
    CloseLaptop()
    cb({ ok = true })
end)

RegisterNetEvent('crime_laptop:client:cryptoHistory', function(history)
    SendNUIMessage({
        action = 'cryptoHistory',
        history = history
    })
end)

RegisterNetEvent('crime_laptop:client:cryptoGraph', function(history)
    SendNUIMessage({
        action = 'cryptoGraph',
        history = history
    })
end)

RegisterNUICallback('transferCrypto', function(data, cb)
    TriggerServerEvent('crime_laptop:server:transferCrypto', data.toUsername, data.amount)
    cb({ ok = true })
end)

RegisterNUICallback('getCryptoHistory', function(data, cb)
    TriggerServerEvent('crime_laptop:server:getCryptoHistory')
    cb({ ok = true })
end)

RegisterNUICallback('getCryptoGraph', function(data, cb)
    TriggerServerEvent('crime_laptop:server:getCryptoGraph')
    cb({ ok = true })
end)

RegisterCommand('laptop', function()
    OpenLaptop()
end, false)

exports('OpenLaptop', OpenLaptop)
