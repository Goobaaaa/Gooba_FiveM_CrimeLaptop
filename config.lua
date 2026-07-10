Config = {}

Config.Item = 'rugged_laptop'
Config.Debug = true

Config.Database = {
    profiles = 'crime_laptop_profiles',
    listings = 'crime_laptop_listings',
    crypto_history = 'crime_laptop_crypto_history'
}

Config.BlackMarket = {
    MaxListingsPerPlayer = 5,
    MinPrice = 1,
    MaxPrice = 1000000,
    ListingFee = 0,
    RefreshCooldown = 30
}

Config.DropoffAnimation = {
    dict = 'amb@medic@standing@kneel@idle_a',
    name = 'idle_a',
    duration = 5000
}

Config.DropoffLocations = {
    {
        name = 'Vinewood Tattoo Parlor',
        coords = vector3(309.7, 170.69, 102.92),
        heading = 159.92
    },
    {
        name = 'Davis Laundry',
        coords = vector3(149.63, -203.52, 54.14),
        heading = 340.0
    },
    {
        name = 'Rockford Hills Newsstand',
        coords = vector3(-584.22, -1622.57, 27.01),
        heading = 170.0
    },
    {
        name = 'Vespucci Beach Bench',
        coords = vector3(-1234.56, -1682.34, 4.17),
        heading = 310.0
    },
    {
        name = 'Grove Street Dumpster',
        coords = vector3(63.33, -1906.22, 21.07),
        heading = 225.0
    }
}

Config.SecureDropbox = {
    ShowBlips = true,
    BlipSprite = 134,
    BlipColor = 1,
    BlipScale = 0.8,
    InteractionDistance = 2.0,
    Locations = {
        {
            name = 'Downtown Newspaper Box',
            coords = vector3(235.03, -815.49, 30.72),
            heading = 70.0,
            model = 'prop_newsbox_01a'
        },
        {
            name = 'Vinewood News Stand',
            coords = vector3(291.18, 180.46, 104.47),
            heading = 340.0,
            model = 'prop_newsbox_01a'
        },
        {
            name = 'Paleto Bay Mailbox',
            coords = vector3(-282.07, 6120.86, 31.97),
            heading = 315.0,
            model = 'prop_postbox_01a'
        },
        {
            name = 'Sandy Shores Drop Point',
            coords = vector3(1701.31, 3773.55, 34.44),
            heading = 200.0,
            model = 'prop_postbox_01a'
        },
        {
            name = 'Mirror Park Utility Box',
            coords = vector3(1182.52, -333.37, 69.18),
            heading = 90.0,
            model = 'prop_elecbox_03a'
        }
    }
}

Config.UI = {
    Theme = {
        primary = '#8b2fc9',
        primaryDark = '#6a1f9e',
        accent = '#e74c3c',
        accentGlow = 'rgba(231, 76, 60, 0.3)',
        bg = '#0a0a0f',
        bgCard = '#12121a',
        bgCardHover = '#1a1a25',
        bgInput = '#1a1a25',
        border = '#2a2a3a',
        text = '#e0e0e0',
        textMuted = '#888',
        textAccent = '#e74c3c',
        success = '#27ae60',
        warning = '#f39c12',
        danger = '#e74c3c'
    }
}
