--========================================================--
-- AUTO FARM FISHING SCRIPT (STEALTH MODE / ANTI-BYFRON)
-- Dengan delay lempar & tarik per-rod
--========================================================--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ANTI AFK
task.spawn(function()
    local vu = game:GetService("VirtualUser")
    player.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
        print(">> ANTI AFK ACTIVATED (King Bagas)")
    end)
end)

-- Notifikasi
task.spawn(function()
    local StarterGui = game:GetService("StarterGui")

    for i = 1, 2 do
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "👑 King Bagas 👑",
                Text = "Script Started Successfully",
                Duration = 5
            })
        end)
        task.wait(0.5)
    end
end)

-- Services
local Replion = require(ReplicatedStorage.Packages.Replion)
local netIndex = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

-- Wait for Data
print(">> MENUNGGU DATA...")
local data = Replion.Client:WaitReplion("Data")
print(">> DATA SIAP!")

-- Rod Data (buat beli / track kepemilikan)
local RodData = {
    {name = "Luck Rod",      price = 325,      id = 79, uuid = "4315aa13-5964-4e5d-bda1-84ba5b193695"},
    {name = "Lucky Rod",     price = 15000,    id = 4,  uuid = "1aaba2cd-9ed5-42f0-87fd-380d7acdc600"},
    {name = "Midnight Rod",  price = 50000,    id = 80, uuid = "0c860299-a465-45ad-bcf4-46ae245a8bcd"},
    {name = "Steampunk Rod", price = 215000,   id = 6,  uuid = "56fceb1c-b6ba-4f76-8523-31e87aa40c59"},
    {name = "Astral Rod",    price = 1000000,  id = 5,  uuid = "28b54c20-7a83-413a-afb5-2df2853dd991"}
}

-- ⬇⬇⬇ TAMBAHAN: DELAY PER ROD (BERDASARKAN UUID) ⬇⬇⬇
-- Kalau UUID rod tidak ada di sini, dianggap Starter Rod.
local RodTimingByUUID = {
    -- Luck Rod
    ["4315aa13-5964-4e5d-bda1-84ba5b193695"] = {
        throwDelay = 0.05,
        pullDelay  = 2.3,
    },
    -- Lucky Rod
    ["1aaba2cd-9ed5-42f0-87fd-380d7acdc600"] = {
        throwDelay = 0.05,
        pullDelay  = 1.9,
    },
    -- Midnight Rod
    ["0c860299-a465-45ad-bcf4-46ae245a8bcd"] = {
        throwDelay = 0.05,
        pullDelay  = 1.4,
    },
    -- Steampunk Rod
    ["56fceb1c-b6ba-4f76-8523-31e87aa40c59"] = {
        throwDelay = 0.05,
        pullDelay  = 1.3,
    },
    -- Astral Rod
    ["28b54c20-7a83-413a-afb5-2df2853dd991"] = {
        throwDelay = 0.05,
        pullDelay  = 1.0,
    },
}

-- Default = Starter Rod (kalau equip-nya bukan salah satu UUID di atas)
local DEFAULT_THROW_DELAY = 0.05
local DEFAULT_PULL_DELAY  = 2.8

-- Teleport Locations
local Map = {
    {x = 129.1,   y = 3.5,    z = 2750.8,   name = "Fisherman Island"},
    {x = -534.4,  y = 19.1,   z = 162.8,    name = "Kohana Island"},
    {x = -3733.7, y = -135.1, z = -885.9,   name = "Sisyphus Statue"},
    {x = -3597.1, y = -275.6, z = -1640.9,  name = "Treasure Room"}
}

local fishCount = 0
local currentRodIndex = 0

--========================================================--
-- FUNCTIONS (STEALTH MODE)
--========================================================--

local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

-- Get Coins
local function GetMoney()
    local ok, val = pcall(function()
        return data:GetExpect("Coins")
    end)
    if ok and typeof(val) == "number" then return val end

    local fallback = data:Get("Coins")
    return typeof(fallback) == "number" and fallback or 0
end

-- Detect Owned Rods
local function GetOwnedRods()
    local rods = data:GetExpect({"Inventory", "Fishing Rods"}) or {}
    local owned = {}
    for _, rod in pairs(rods) do
        owned[rod.Id] = rod.UUID
    end
    return owned
end

-- ⬇⬇⬇ TAMBAHAN: AMBIL DELAY BERDASARKAN ROD YANG EQUIP ⬇⬇⬇
local function GetCurrentRodDelays()
    -- Di Replion Data, EquippedItems[1] adalah UUID item equip (Fishing Rods ketika EquippedType = "Fishing Rods")
    local equippedList = data:GetExpect("EquippedItems") or {}
    local currentUUID = equippedList[1]

    if typeof(currentUUID) ~= "string" or currentUUID == "" then
        -- Tidak ada data → anggap Starter Rod
        return DEFAULT_THROW_DELAY, DEFAULT_PULL_DELAY
    end

    local cfg = RodTimingByUUID[currentUUID]
    if cfg then
        return cfg.throwDelay, cfg.pullDelay
    end

    -- UUID tidak dikenali → juga anggap Starter Rod
    return DEFAULT_THROW_DELAY, DEFAULT_PULL_DELAY
end

-- SAFE TELEPORT (Lerp)
local function Teleport(x, y, z, name)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local from = hrp.Position
    local to = Vector3.new(x, y, z)

    print((">> TELEPORT KE: %s"):format(name))

    local steps = 8
    for i = 1, steps do
        hrp.CFrame = CFrame.new(from:Lerp(to, i/steps))
        task.wait(0.04 + math.random(1,4)/100)
    end

    task.wait(randomDelay(0.4, 1.1))
end

-- Buy Rod
local function BuyRod(rod)
    if GetMoney() < rod.price then return false end

    print(">> MEMBELI:", rod.name)
    local ok = pcall(function()
        netIndex:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(rod.id)
    end)

    if ok then
        print(">> PEMBELIAN BERHASIL!")
        task.wait(1)
        return true
    end

    return false
end

-- Equip Rod
local function EquipRod(uuid)
    print(">> EQUIP ROD:", uuid)

    local ok = pcall(function()
        netIndex:WaitForChild("RE/EquipItem"):FireServer(uuid, "Fishing Rods")
    end)

    if ok then
        task.wait(0.4)
        netIndex:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
        print(">> ROD EQUIPPED!")
        task.wait(0.4)
        return true
    end

    return false
end

-- Sell All
local function SellAll()
    print(">> SELLING ALL ITEMS...")
    local ok = pcall(function()
        netIndex:WaitForChild("RF/SellAllItems"):InvokeServer()
    end)

    if ok then
        print(">> SELL BERHASIL! Money:", GetMoney())
        fishCount = 0
    else
        warn(">> GAGAL SELL")
    end
end

--========================================================--
-- AUTO FISH (STEALTH + PER-ROD DELAY)
--========================================================--

local function DoFishing()
    local success, err = pcall(function()
        -- Ambil delay sesuai rod yang lagi ke-equip
        local throwDelay, pullDelay = GetCurrentRodDelays()

        -- Sedikit human delay sebelum mulai
        task.wait(randomDelay(0.15, 0.35))

        -- Charge rod
        netIndex:WaitForChild("RF/ChargeFishingRod"):InvokeServer()

        -- Delay lempar (trow delay) + jitter kecil
        task.wait(throwDelay + math.random(-5, 5) / 1000)

        -- Args lempar minigame (X,Y stabil + jitter kecil, waktu pakai tick())
        local args = {
            -1.233184814453125 + math.random(-3, 3) * 0.01,
            0.1392755888600895 + math.random(-3, 3) * 0.01,
            tick() + math.random(-5, 5) * 0.001
        }

        netIndex:WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(unpack(args))

        -- Delay tarik (pull delay) sesuai rod + jitter
        task.wait(pullDelay + math.random(-15, 15) / 1000)

        -- Selesaikan minigame
        netIndex:WaitForChild("RE/FishingCompleted"):FireServer()
    end)

    if success then
        fishCount += 1
        print((">> FISHING COMPLETE! Count: %d/5"):format(fishCount))

        if fishCount >= 5 then
            SellAll()
        end

        task.wait(randomDelay(0.35, 0.7))
        return true
    end

    warn(">> FISHING FAILED:", err)
    task.wait(randomDelay(1.6, 2.4))
    return false
end

--========================================================--
-- ROD PROGRESSION LOGIC
--========================================================--

local function CheckAndBuyNextRod()
    local owned = GetOwnedRods()
    local money = GetMoney()

    for i, rod in ipairs(RodData) do
        if not owned[rod.id] and money >= rod.price then
            if BuyRod(rod) then
                task.wait(1)
                owned = GetOwnedRods()
                if owned[rod.id] then
                    EquipRod(owned[rod.id])
                    currentRodIndex = i
                    return true
                end
            end
        end
    end
    return false
end

-- DeepSea Tracking
local function GetDeepSeaProgress()
    local ds = data:Get({"DeepSea", "Available"})
    if ds and ds.Forever and ds.Forever.Quests then return ds.Forever.Quests end

    ds = data:Get("DeepSea")
    if ds and ds.Forever and ds.Forever.Quests then return ds.Forever.Quests end

    return nil
end

local function CheckDeepSeaQuest(index, target)
    local quests = GetDeepSeaProgress()
    if quests and quests[index] then
        return (quests[index].Progress or 0) >= target
    end
    return false
end

-- FARM ROD
local function FarmUntilRod(idx)
    print(">> FARMING UNTUK ROD:", RodData[idx].name)

    while true do
        local owned = GetOwnedRods()
        local money = GetMoney()

        if owned[RodData[idx].id] then
            print(">> SUDAH MEMILIKI:", RodData[idx].name)
            EquipRod(owned[RodData[idx].id])
            currentRodIndex = idx
            break
        end

        if money >= RodData[idx].price then
            if CheckAndBuyNextRod() then break end
        end

        DoFishing()
        task.wait(0.4)
    end
end

-- FARM LOCATION
local function FarmAtLocation(locIndex, rodTargets)
    local loc = Map[locIndex]
    Teleport(loc.x, loc.y, loc.z, loc.name)

    for _, rIndex in ipairs(rodTargets) do
        FarmUntilRod(rIndex)
    end
end

-- SISYPHUS SECRET
local function FarmSisyphusSecret()
    print(">> FARMING SISYPHUS SECRET QUEST...")
    local loc = Map[3]
    Teleport(loc.x, loc.y, loc.z, loc.name)

    while not CheckDeepSeaQuest(3, 1) do
        DoFishing()
        task.wait(0.4)
    end

    print(">> SISYPHUS SECRET QUEST COMPLETE!")
end

-- TREASURE ROOM
local function FarmTreasureRoomQuest()
    print(">> FARMING TREASURE ROOM QUEST (300 Rare/Epic)...")
    local loc = Map[4]
    Teleport(loc.x, loc.y, loc.z, loc.name)

    while not CheckDeepSeaQuest(1, 300) do
        DoFishing()
        task.wait(0.4)
    end

    print(">> TREASURE ROOM QUEST COMPLETE!")
end

--========================================================--
-- MAIN EXECUTION
--========================================================--

print("==================================================")
print(">> AUTO FARM FISHING STARTED!")
print("==================================================")

pcall(function()
    netIndex:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
end)
task.wait(1)

print("\n>> STEP 1: FISHERMAN ISLAND")
FarmAtLocation(1, {1})

print("\n>> STEP 2: LOKASI 1 UPGRADE ROD")
FarmAtLocation(1, {2})

print("\n>> STEP 3: KOHANA ISLAND")
FarmAtLocation(2, {3, 4, 5})

print("\n>> STEP 4: SISYPHUS SECRET QUEST")
FarmSisyphusSecret()

print("\n>> STEP 5: TREASURE ROOM (300 RARE/EPIC)")
FarmTreasureRoomQuest()

print("\n==================================================")
print(">> AUTO FARM COMPLETE!")
print("==================================================")
