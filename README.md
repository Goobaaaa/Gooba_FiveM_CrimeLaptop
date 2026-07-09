# Gooba's FiveM Crime Laptop

A dark web style criminal operations laptop for FiveM servers. Players use a **Rugged Laptop** item to access a full-screen NUI interface with a criminal profile system, black market, and jobs hub.

---

## Features

- **Rugged Laptop Item** — Usable from inventory or hotbar
- **Login System** — Players create a criminal alias on first use
- **NUI Interface** — Full 75% screen laptop UI with red/purple dark theme
- **Homepage** — Stats dashboard (balance, jobs completed, items sold, total earned)
- **Black Market** — Create listings, buy items, search and filter
- **Jobs Hub** — Ready for expansion (barebones layout with 30/70 split)
- **About Page** — Profile stats and alias change
- **MySQL Database** — Profiles and listings stored in oxmysql
- **Server-Side Validation** — All transactions validated server-side
- **Framework Abstraction** — ox_inventory, Qbox, QB-Core, ESX

---

## Dependencies

| Resource | Required |
|----------|----------|
| [ox_inventory](https://github.com/overextended/ox_inventory) | **Yes** |
| [oxmysql](https://github.com/overextended/oxmysql) | **Yes** |
| [ox_lib](https://github.com/overextended/ox_lib) | Recommended |

---

## Installation

### Step 1: Place Resource

Copy the `crime_laptop` folder into your server's `resources` directory.

### Step 2: Run SQL

Run the SQL in `sql/schema.sql` against your database:

```sql
CREATE TABLE IF NOT EXISTS `crime_laptop_profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `license` VARCHAR(60) NOT NULL UNIQUE,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `balance` INT DEFAULT 0,
    `jobs_completed` INT DEFAULT 0,
    `items_sold` INT DEFAULT 0,
    `total_earned` INT DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> **Note:** Tables also auto-create on resource start if they don't exist.

### Step 3: Add Item to ox_inventory

Open `resources/[ox]/ox_inventory/data/items.lua` and add before the final `}`:

```lua
['rugged_laptop'] = {
    label = 'Rugged Laptop',
    weight = 2000,
    client = {
        image = 'rugged_laptop.png',
        export = 'crime_laptop.OpenLaptop',
    },
},
```

### Step 4: Add Item Image

Copy `laptop.png` from `ox_inventory/web/images/` and rename it to `rugged_laptop.png` in the same folder. Or use your own image.

### Step 5: Start Resource

Add to `server.cfg`:

```
ensure crime_laptop
```

**Restart the server** after adding the new item.

---

## Configuration

All settings in `config.lua`:

```lua
Config = {}

-- Item name for the laptop
Config.Item = 'rugged_laptop'

-- Debug mode (prints server logs)
Config.Debug = true

-- Database table names
Config.Database = {
    profiles = 'crime_laptop_profiles',
    listings = 'crime_laptop_listings'
}

-- Black Market settings
Config.BlackMarket = {
    MaxListingsPerPlayer = 5,
    MinPrice = 100,
    MaxPrice = 1000000,
    ListingFee = 0,
    RefreshCooldown = 30
}

-- UI Theme (red/purple dark web theme)
Config.UI = {
    Theme = {
        primary = '#8b2fc9',
        accent = '#e74c3c',
        bg = '#0a0a0f',
        ...
    }
}
```

---

## How It Works

### Player Flow

```
Player uses Rugged Laptop (inventory or hotbar)
         │
         ▼
   First time? ──Yes──► Show login screen
         │                    │
         No                   │ Player enters alias
         │                    │
         ▼                    ▼
   Open laptop UI ◄── Profile created in DB
         │
         ▼
   ┌─────────┬──────────────┬───────┬───────┐
   │  Home   │ Black Market │ Jobs  │ About │
   └─────────┴──────────────┴───────┴───────┘
```

### Black Market Flow

```
Player creates listing
   ├── Items taken from inventory
   ├── Listing stored in database
   └── Other players can see and buy

Player buys listing
   ├── Balance deducted from buyer
   ├── Balance added to seller
   ├── Items given to buyer
   └── Listing removed from database
```

### Database Tables

**crime_laptop_profiles:**
- `license` — Player's FiveM license (unique identifier)
- `username` — Criminal alias (unique)
- `balance` — In-game currency balance
- `jobs_completed`, `items_sold`, `total_earned` — Stats

**crime_laptop_listings:**
- `seller_license`, `seller_username` — Who listed it
- `item_name`, `item_label` — Item details
- `amount`, `price` — Quantity and cost

---

## Pages

### Home
- Welcome message with player's alias
- 4 stat cards: Balance, Jobs Done, Items Sold, Total Earned
- Operations feed with system messages

### Black Market
- Search bar and item filter dropdown
- Table with columns: Seller, Item, Qty, Price, Buy button
- "Create Listing" button opens modal
- "Refresh" button reloads listings

### Jobs
- 30/70 split layout (jobs list / detail panel)
- Ready for expansion — currently shows placeholder items

### About
- Profile card with avatar, alias, and stats
- "Change Alias" button to update criminal identity

---

## Server Commands

| Command | Description |
|---------|-------------|
| `/laptop` | Open the crime laptop |

---

## File Structure

```
crime_laptop/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # All configuration
├── client/
│   └── main.lua            # Client NUI handling, item use
├── server/
│   ├── main.lua            # Server events, item registration
│   ├── profiles.lua        # Database profile operations
│   └── blackmarket.lua     # Database listing operations
├── shared/
│   ├── framework.lua       # Framework abstraction
│   └── utils.lua           # Helpers (license, debug, formatting)
├── nui/
│   ├── index.html          # Main NUI page
│   ├── css/
│   │   └── style.css       # Red/purple dark theme styling
│   └── js/
│       ├── api.js          # NUI fetch calls to server
│       ├── pages.js        # Page rendering functions
│       └── app.js          # App initialization, state, events
└── sql/
    └── schema.sql          # Database schema
```

---

## Troubleshooting

### Laptop doesn't open
- Ensure ox_inventory item has `export = 'crime_laptop.OpenLaptop'`
- Check server console for errors
- Restart server after adding item

### Database errors
- Run the SQL schema manually
- Ensure oxmysql is running
- Tables auto-create on resource start

### NUI not loading
- Ensure `ui_page` is set in fxmanifest
- **Restart server** (not just ensure)

### Login not working
- Check license identifiers are available
- Verify MySQL connection is working

---

## Future Expansion

- **Jobs System** — Dynamic criminal jobs with rewards
- **Inventory Integration** — Items sold on black market deducted from seller
- **Balance System** — Earn from jobs, spend on black market
- **Admin Panel** — Manage listings, view stats
- **Chat Notifications** — Alerts for sales/purchases
