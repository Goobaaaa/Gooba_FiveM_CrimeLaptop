local Profiles = {}

function Profiles.GetByLicense(license)
    local result = MySQL.query.await(
        'SELECT * FROM ' .. Config.Database.profiles .. ' WHERE license = ?',
        { license }
    )
    return result and result[1] or nil
end

function Profiles.GetByUsername(username)
    local result = MySQL.query.await(
        'SELECT * FROM ' .. Config.Database.profiles .. ' WHERE username = ?',
        { username }
    )
    return result and result[1] or nil
end

function Profiles.Create(license, username)
    local existing = Profiles.GetByUsername(username)
    if existing then
        return nil, 'Alias already taken'
    end

    MySQL.insert.await(
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

    MySQL.update.await(
        'UPDATE ' .. Config.Database.profiles .. ' SET username = ? WHERE license = ?',
        { newUsername, license }
    )

    MySQL.update.await(
        'UPDATE ' .. Config.Database.listings .. ' SET seller_username = ? WHERE seller_license = ?',
        { newUsername, license }
    )

    return true
end

function Profiles.AddBalance(license, amount)
    MySQL.update.await(
        'UPDATE ' .. Config.Database.profiles .. ' SET balance = balance + ? WHERE license = ?',
        { amount, license }
    )
end

function Profiles.RemoveBalance(license, amount)
    local profile = Profiles.GetByLicense(license)
    if not profile or profile.balance < amount then
        return false, 'Insufficient balance'
    end

    MySQL.update.await(
        'UPDATE ' .. Config.Database.profiles .. ' SET balance = balance - ? WHERE license = ?',
        { amount, license }
    )
    return true
end

function Profiles.IncrementStat(license, stat, amount)
    MySQL.update.await(
        'UPDATE ' .. Config.Database.profiles .. ' SET ' .. stat .. ' = ' .. stat .. ' + ? WHERE license = ?',
        { amount or 1, license }
    )
end

return Profiles
