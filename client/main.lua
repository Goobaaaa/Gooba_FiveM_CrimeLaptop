local isLaptopOpen = false
local dropboxBlips = {}
local dropoffBlip = nil
local dropoffRadiusBlip = nil
local pendingListings = {}
local activeDropoff = nil
local isDepositing = false

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

local function CreateDropboxBlips()
    for _, blip in ipairs(dropboxBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    dropboxBlips = {}

    if not Config.SecureDropbox.ShowBlips then return end

    for _, loc in ipairs(Config.SecureDropbox.Locations) do
        local blip = AddBlipForCoord(loc.coords.x, loc.coords.y, loc.coords.z)
        SetBlipSprite(blip, Config.SecureDropbox.BlipSprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.SecureDropbox.BlipScale)
        SetBlipColour(blip, Config.SecureDropbox.BlipColor)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Secure Dropbox - ' .. loc.name)
        EndTextCommandSetBlipName(blip)
        dropboxBlips[#dropboxBlips + 1] = blip
    end
end

local function RemoveDropboxBlips()
    for _, blip in ipairs(dropboxBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    dropboxBlips = {}
end

local function ClearDropoffBlip()
    if dropoffBlip and DoesBlipExist(dropoffBlip) then
        RemoveBlip(dropoffBlip)
    end
    if dropoffRadiusBlip and DoesBlipExist(dropoffRadiusBlip) then
        RemoveBlip(dropoffRadiusBlip)
    end
    dropoffBlip = nil
    dropoffRadiusBlip = nil
    activeDropoff = nil
end

local function SetDropoffBlip(location)
    ClearDropoffBlip()

    SetNewWaypoint(location.coords.x, location.coords.y)

    local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
    SetBlipSprite(blip, 408)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 5)
    SetBlipFlashes(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Drop-off: ' .. location.name)
    EndTextCommandSetBlipName(blip)

    local radiusBlip = AddBlipForRadius(location.coords.x, location.coords.y, location.coords.z, 50.0)
    SetBlipColour(radiusBlip, 5)
    SetBlipAlpha(radiusBlip, 80)

    dropoffBlip = blip
    dropoffRadiusBlip = radiusBlip
    activeDropoff = location

    CreateThread(function()
        while activeDropoff do
            Wait(0)
            DrawMarker(
                1,
                activeDropoff.coords.x, activeDropoff.coords.y, activeDropoff.coords.z - 0.95,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                3.0, 3.0, 0.5,
                255, 100, 100, 100,
                false, false, 2, false, nil, nil, false
            )
        end
    end)
end

local function GetNearestDropbox()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local closestDist = Config.SecureDropbox.InteractionDistance + 1.0
    local closestLoc = nil

    for _, loc in ipairs(Config.SecureDropbox.Locations) do
        local dist = #(playerCoords - loc.coords)
        if dist < closestDist then
            closestDist = dist
            closestLoc = loc
        end
    end

    return closestLoc, closestDist
end

local function GetNearestDropoff()
    if not activeDropoff then return nil, 999 end
    local playerCoords = GetEntityCoords(PlayerPedId())
    local dist = #(playerCoords - activeDropoff.coords)
    return activeDropoff, dist
end

local function PlayDropoffAnimation(ped, cb)
    isDepositing = true
    FreezeEntityPosition(ped, true)

    local dict = Config.DropoffAnimation.dict
    local anim = Config.DropoffAnimation.name

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, Config.DropoffAnimation.duration, 0, 0, false, false, false)

    Wait(Config.DropoffAnimation.duration)

    ClearPedTasks(ped)
    RemoveAnimDict(dict)
    FreezeEntityPosition(ped, false)
    isDepositing = false

    if cb then cb() end
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function OpenDropboxUI()
    TriggerServerEvent('crime_laptop:server:getPendingListings')
    CreateThread(function()
        Wait(200)
        SendNUIMessage({ action = 'showDropbox' })
        SetNuiFocus(true, true)
    end)
end

CreateThread(function()
    CreateDropboxBlips()

    while true do
        Wait(500)
        if isDepositing then
            Wait(500)
        else
            local playerCoords = GetEntityCoords(PlayerPedId())

            if activeDropoff then
                local dx = playerCoords.x - activeDropoff.coords.x
                local dy = playerCoords.y - activeDropoff.coords.y
                local dist2d = math.sqrt(dx * dx + dy * dy)

                if dist2d < 2.0 then
                    Wait(0)
                    if dist2d < 1.5 then
                        if IsControlJustReleased(0, 38) then
                            local ped = PlayerPedId()
                            PlayDropoffAnimation(ped, function()
                                TriggerServerEvent('crime_laptop:server:depositAtDropoff')
                            end)
                        end
                    end
                end
            end

            local nearAny = false
            for _, loc in ipairs(Config.SecureDropbox.Locations) do
                local dist = #(playerCoords - loc.coords)
                if dist < 20.0 then
                    nearAny = true
                    break
                end
            end

            if nearAny then
                Wait(0)
                local loc, dist = GetNearestDropbox()
                if loc and dist < Config.SecureDropbox.InteractionDistance then
                    DrawText3D(loc.coords.x, loc.coords.y, loc.coords.z + 1.0, '~r~[E]~w~ Use Secure Dropbox')
                    if IsControlJustReleased(0, 38) then
                        OpenDropboxUI()
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('crime_laptop:client:setDropoff', function(location)
    SetDropoffBlip(location)
end)

RegisterNetEvent('crime_laptop:client:clearDropoff', function()
    ClearDropoffBlip()
end)

RegisterNetEvent('crime_laptop:client:pendingListings', function(listings)
    pendingListings = listings or {}
    SendNUIMessage({
        action = 'pendingListings',
        listings = pendingListings
    })
end)

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

RegisterNetEvent('crime_laptop:client:myListingsData', function(listings)
    SendNUIMessage({
        action = 'myListingsData',
        listings = listings
    })
end)

RegisterNetEvent('crime_laptop:client:inventoryData', function(items)
    SendNUIMessage({
        action = 'inventoryData',
        items = items
    })
end)

RegisterNetEvent('crime_laptop:client:notify', function(message, msgType)
    SendNUIMessage({
        action = 'notify',
        message = message,
        type = msgType or 'info'
    })
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

RegisterNUICallback('getInventory', function(data, cb)
    TriggerServerEvent('crime_laptop:server:getInventory')
    cb({ ok = true })
end)

RegisterNUICallback('createListing', function(data, cb)
    TriggerServerEvent('crime_laptop:server:createListing', data)
    cb({ ok = true })
end)

RegisterNUICallback('depositListing', function(data, cb)
    TriggerServerEvent('crime_laptop:server:depositListing', data.listingId)
    cb({ ok = true })
end)

RegisterNUICallback('buyListing', function(data, cb)
    TriggerServerEvent('crime_laptop:server:buyListing', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('getMyListings', function(data, cb)
    TriggerServerEvent('crime_laptop:server:getMyListings')
    cb({ ok = true })
end)

RegisterNUICallback('cancelListing', function(data, cb)
    TriggerServerEvent('crime_laptop:server:cancelListing', data)
    cb({ ok = true })
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

RegisterNUICallback('close', function(data, cb)
    CloseLaptop()
    cb({ ok = true })
end)

RegisterNUICallback('closeDropbox', function(data, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('clearDropoff', function(data, cb)
    ClearDropoffBlip()
    cb({ ok = true })
end)

RegisterCommand('laptop', function()
    OpenLaptop()
end, false)

RegisterCommand('mycoords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local msg = string.format('vector3(%.2f, %.2f, %.2f) heading %.1f', coords.x, coords.y, coords.z, heading)
    print('[Coords] ' .. msg)
    TriggerEvent('chat:addMessage', { args = { 'Coords', msg } })
end, false)

exports('OpenLaptop', OpenLaptop)
