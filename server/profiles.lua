Profiles = {}

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

function Profiles.GetByLicense(license)
    local result = Query(
        'SELECT * FROM ' .. Config.Database.profiles .. ' WHERE license = ?',
        { license }
    )
    return result and result[1] or nil
end

function Profiles.GetByUsername(username)
    local result = Query(
        'SELECT * FROM ' .. Config.Database.profiles .. ' WHERE username = ?',
        { username }
    )
    return result and result[1] or nil
end

function Profiles.Create(license, username)
    local existingByLicense = Profiles.GetByLicense(license)
    if existingByLicense then
        return existingByLicense
    end

    local existingByUsername = Profiles.GetByUsername(username)
    if existingByUsername then
        return nil, 'Alias already taken'
    end

    Insert(
        'INSERT INTO ' .. Config.Database.profiles .. ' (license, username, crypto) VALUES (?, ?, ?)',
        { license, username, 0 }
    )

    return Profiles.GetByLicense(license)
end

function Profiles.UpdateUsername(license, newUsername)
    local existing = Profiles.GetByUsername(newUsername)
    if existing then
        return false, 'Alias already taken'
    end

    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET username = ? WHERE license = ?',
        { newUsername, license }
    )

    Update(
        'UPDATE ' .. Config.Database.listings .. ' SET seller_username = ? WHERE seller_license = ?',
        { newUsername, license }
    )

    return true
end

function Profiles.AddCrypto(license, amount, description)
    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET crypto = crypto + ? WHERE license = ?',
        { amount, license }
    )

    Insert(
        'INSERT INTO ' .. Config.Database.crypto_history .. ' (license, type, amount, description) VALUES (?, ?, ?, ?)',
        { license, 'add', amount, description or '' }
    )
end

function Profiles.RemoveCrypto(license, amount, description)
    local profile = Profiles.GetByLicense(license)
    if not profile or profile.crypto < amount then
        return false, 'Insufficient CRM'
    end

    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET crypto = crypto - ? WHERE license = ?',
        { amount, license }
    )

    Insert(
        'INSERT INTO ' .. Config.Database.crypto_history .. ' (license, type, amount, description) VALUES (?, ?, ?, ?)',
        { license, 'remove', amount, description or '' }
    )

    return true
end

function Profiles.TransferCrypto(fromLicense, toLicense, amount, description)
    local fromProfile = Profiles.GetByLicense(fromLicense)
    if not fromProfile or fromProfile.crypto < amount then
        return false, 'Insufficient CRM'
    end

    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET crypto = crypto - ? WHERE license = ?',
        { amount, fromLicense }
    )

    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET crypto = crypto + ? WHERE license = ?',
        { amount, toLicense }
    )

    Insert(
        'INSERT INTO ' .. Config.Database.crypto_history .. ' (license, type, amount, description) VALUES (?, ?, ?, ?)',
        { fromLicense, 'transfer_out', amount, description or '' }
    )

    Insert(
        'INSERT INTO ' .. Config.Database.crypto_history .. ' (license, type, amount, description) VALUES (?, ?, ?, ?)',
        { toLicense, 'transfer_in', amount, description or '' }
    )

    return true
end

function Profiles.GetCryptoHistory(license, limit)
    local result = Query(
        'SELECT * FROM ' .. Config.Database.crypto_history .. ' WHERE license = ? ORDER BY created_at DESC LIMIT ?',
        { license, limit or 50 }
    )
    return result or {}
end

function Profiles.GetCryptoHistoryForGraph(license)
    local result = Query(
        'SELECT created_at, type, amount FROM ' .. Config.Database.crypto_history .. ' WHERE license = ? ORDER BY created_at ASC',
        { license }
    )
    return result or {}
end

function Profiles.IncrementStat(license, stat, amount)
    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET ' .. stat .. ' = ' .. stat .. ' + ? WHERE license = ?',
        { amount or 1, license }
    )
end

return Profiles
