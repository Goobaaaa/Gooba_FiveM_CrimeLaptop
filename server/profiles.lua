Profiles = {}

local function Query(sql, params)
    return exports.oxmysql:execute(sql, params)
end

local function Insert(sql, params)
    return exports.oxmysql:insert(sql, params)
end

local function Update(sql, params)
    return exports.oxmysql:update(sql, params)
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
        'INSERT INTO ' .. Config.Database.profiles .. ' (license, username, balance) VALUES (?, ?, ?)',
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

function Profiles.AddBalance(license, amount)
    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET balance = balance + ? WHERE license = ?',
        { amount, license }
    )
end

function Profiles.RemoveBalance(license, amount)
    local profile = Profiles.GetByLicense(license)
    if not profile or profile.balance < amount then
        return false, 'Insufficient balance'
    end

    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET balance = balance - ? WHERE license = ?',
        { amount, license }
    )
    return true
end

function Profiles.IncrementStat(license, stat, amount)
    Update(
        'UPDATE ' .. Config.Database.profiles .. ' SET ' .. stat .. ' = ' .. stat .. ' + ? WHERE license = ?',
        { amount or 1, license }
    )
end

return Profiles
