BlackMarket = {}

local function Query(sql, params)
    local p = promise.new()
    exports.oxmysql:execute(sql, params, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

local function Insert(sql, params)
    local p = promise.new()
    exports.oxmysql:insert(sql, params, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

local function Update(sql, params)
    local p = promise.new()
    exports.oxmysql:update(sql, params, function(result)
        p:resolve(result)
    end)
    return Citizen.Await(p)
end

function BlackMarket.GetListings(search, filter)
    local query = 'SELECT * FROM ' .. Config.Database.listings .. ' WHERE status = ?'
    local params = { 'active' }
    local conditions = {}

    if search and search ~= '' then
        table.insert(conditions, '(item_name LIKE ? OR item_label LIKE ? OR seller_username LIKE ?)')
        local s = '%' .. search .. '%'
        table.insert(params, s)
        table.insert(params, s)
        table.insert(params, s)
    end

    if filter and filter ~= 'all' then
        table.insert(conditions, 'item_name = ?')
        table.insert(params, filter)
    end

    if #conditions > 0 then
        query = query .. ' AND ' .. table.concat(conditions, ' AND ')
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 50'

    return Query(query, params) or {}
end

function BlackMarket.GetPlayerListings(license)
    local result = Query(
        'SELECT * FROM ' .. Config.Database.listings .. ' WHERE seller_license = ? ORDER BY created_at DESC',
        { license }
    )
    return result or {}
end

function BlackMarket.CreatePendingListing(license, username, itemName, itemLabel, amount, price)
    if not itemName or not itemLabel or not price or price < 1 then
        return false, 'Invalid listing data'
    end

    if price > Config.BlackMarket.MaxPrice then
        return false, 'Price too high'
    end

    local count = Query(
        'SELECT COUNT(*) as count FROM ' .. Config.Database.listings .. ' WHERE seller_license = ? AND status IN (?, ?)',
        { license, 'pending', 'active' }
    )

    if count and count[1] and count[1].count >= Config.BlackMarket.MaxListingsPerPlayer then
        return false, 'Maximum listings reached (' .. Config.BlackMarket.MaxListingsPerPlayer .. ')'
    end

    local id = Insert(
        'INSERT INTO ' .. Config.Database.listings .. ' (seller_license, seller_username, item_name, item_label, amount, price, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
        { license, username, itemName, itemLabel, amount, price, 'pending' }
    )

    return true, id
end

function BlackMarket.ActivateListing(listingId)
    Update(
        'UPDATE ' .. Config.Database.listings .. ' SET status = ? WHERE id = ? AND status = ?',
        { 'active', listingId, 'pending' }
    )
end

function BlackMarket.GetPendingListing(id)
    local result = Query(
        'SELECT * FROM ' .. Config.Database.listings .. ' WHERE id = ? AND status = ?',
        { id, 'pending' }
    )
    return result and result[1] or nil
end

function BlackMarket.GetListing(id)
    local result = Query(
        'SELECT * FROM ' .. Config.Database.listings .. ' WHERE id = ?',
        { id }
    )
    return result and result[1] or nil
end

function BlackMarket.DeleteListing(id)
    Query(
        'DELETE FROM ' .. Config.Database.listings .. ' WHERE id = ?',
        { id }
    )
end

function BlackMarket.CancelListing(id, license)
    Update(
        'UPDATE ' .. Config.Database.listings .. ' SET status = ? WHERE id = ? AND seller_license = ?',
        { 'cancelled', id, license }
    )
end

function BlackMarket.DeleteListingsByLicense(license)
    Query(
        'DELETE FROM ' .. Config.Database.listings .. ' WHERE seller_license = ?',
        { license }
    )
end

return BlackMarket
