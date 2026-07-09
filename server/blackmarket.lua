local BlackMarket = {}

function BlackMarket.GetListings(search, filter)
    local query = 'SELECT * FROM ' .. Config.Database.listings
    local params = {}
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
        query = query .. ' WHERE ' .. table.concat(conditions, ' AND ')
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 50'

    return MySQL.query.await(query, params) or {}
end

function BlackMarket.CreateListing(license, username, itemName, itemLabel, amount, price)
    if not itemName or not itemLabel or not price or price < Config.BlackMarket.MinPrice then
        return false, 'Invalid listing data'
    end

    if price > Config.BlackMarket.MaxPrice then
        return false, 'Price too high'
    end

    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM ' .. Config.Database.listings .. ' WHERE seller_license = ?',
        { license }
    )

    if count and count >= Config.BlackMarket.MaxListingsPerPlayer then
        return false, 'Maximum listings reached (' .. Config.BlackMarket.MaxListingsPerPlayer .. ')'
    end

    MySQL.insert.await(
        'INSERT INTO ' .. Config.Database.listings .. ' (seller_license, seller_username, item_name, item_label, amount, price) VALUES (?, ?, ?, ?, ?, ?)',
        { license, username, itemName, itemLabel, amount, price }
    )

    return true
end

function BlackMarket.GetListing(id)
    local result = MySQL.query.await(
        'SELECT * FROM ' .. Config.Database.listings .. ' WHERE id = ?',
        { id }
    )
    return result and result[1] or nil
end

function BlackMarket.DeleteListing(id)
    MySQL.query.await(
        'DELETE FROM ' .. Config.Database.listings .. ' WHERE id = ?',
        { id }
    )
end

function BlackMarket.DeleteListingsByLicense(license)
    MySQL.query.await(
        'DELETE FROM ' .. Config.Database.listings .. ' WHERE seller_license = ?',
        { license }
    )
end

return BlackMarket
