--[[
    AUTO FARM FISHING SCRIPT
    Cara kerja:
    1. Beli rod bertahap dari termurah ke termahal
    2. Auto fishing + sell di 4 lokasi berbeda
    3. Complete DeepSea quests
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Services
local Replion = require(ReplicatedStorage.Packages.Replion)
local netIndex = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

-- Wait for data
print(">> MENUNGGU DATA...")
local data = Replion.Client:WaitReplion("Data")
print(">> DATA SIAP!")

-- Rod Data
local RodData = {
    {name = "Luck Rod", price = 325, id = 79, uuid = "4315aa13-5964-4e5d-bda1-84ba5b193695", tier = 1},
    {name = "Lucky Rod", price = 15000, id = 4, uuid = "1aaba2cd-9ed5-42f0-87fd-380d7acdc600", tier = 3},
    {name = "Midnight Rod", price = 50000, id = 80, uuid = "0c860299-a465-45ad-bcf4-46ae245a8bcd", tier = 3},
    {name = "Steampunk Rod", price = 215000, id = 6, uuid = "56fceb1c-b6ba-4f76-8523-31e87aa40c59", tier = 4},
    {name = "Astral Rod", price = 1000000, id = 5, uuid = "28b54c20-7a83-413a-afb5-2df2853dd991", tier = 5}
}

-- Location Map
local Map = {
    {x = 129.1, y = 3.5, z = 2750.8, name = "Fisherman Island"},
    {x = -534.4, y = 19.1, z = 162.8, name = "Kohana Island"},
    {x = -3733.7, y = -135.1, z = -885.9, name = "Sisyphus Statue"},
    {x = -3597.1, y = -275.6, z = -1640.9, name = "Treasure Room"}
}

-- Variables
local fishCount = 0
local currentRodIndex = 0

-- Helper Functions
local function GetMoney()
    local ok, value = pcall(function()
        return data:GetExpect("Coins")
    end)
    if ok and typeof(value) == "number" then
        return value
    end
    local v = data:Get("Coins")
    if typeof(v) == "number" then
        return v
    end
    return 0
end

local function GetOwnedRods()
    local rods = data:GetExpect({"Inventory", "Fishing Rods"}) or {}
    local ownedIds = {}
    for _, rod in pairs(rods) do
        ownedIds[rod.Id] = rod.UUID
    end
    return ownedIds
end

local function Teleport(x, y, z, locationName)
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(x, y, z)
    print(string.format(">> TELEPORT KE: %s (%.1f, %.1f, %.1f)", locationName, x, y, z))
    wait(1)
end

local function BuyRod(rodData)
    local money = GetMoney()
    if money >= rodData.price then
        print(string.format(">> MEMBELI: %s (Price: %d, Current Money: %d)", rodData.name, rodData.price, money))
        local success, err = pcall(function()
            netIndex:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(rodData.id)
        end)
        if success then
            print(">> PEMBELIAN BERHASIL!")
            wait(1)
            return true
        else
            warn(">> GAGAL MEMBELI ROD:", err)
        end
    end
    return false
end

local function EquipRod(uuid)
    print(">> EQUIP ROD:", uuid)
    local success, err = pcall(function()
        netIndex:WaitForChild("RE/EquipItem"):FireServer(uuid, "Fishing Rods")
    end)
    if success then
        wait(0.5)
        netIndex:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
        print(">> ROD EQUIPPED!")
        wait(0.5)
        return true
    else
        warn(">> GAGAL EQUIP ROD:", err)
    end
    return false
end

local function SellAll()
    print(">> SELLING ALL ITEMS...")
    local success, err = pcall(function()
        netIndex:WaitForChild("RF/SellAllItems"):InvokeServer()
    end)
    if success then
        print(">> SELL BERHASIL! Money:", GetMoney())
        fishCount = 0
    else
        warn(">> GAGAL SELL:", err)
    end
end

local function DoFishing()
    local success, err = pcall(function()
        -- 1. Charge / tarik rod
        netIndex:WaitForChild("RF/ChargeFishingRod"):InvokeServer()
        task.wait(0.1)

        -- 2. Mulai minigame mancing (lempar)
        --    Dua angka pertama pakai hasil sniff kamu,
        --    argumen ketiga pakai tick() biar natural.
        local args = {
            -1.233184814453125,
            0.1392755888600895,
            tick()
        }
        netIndex:WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(unpack(args))

        -- 3. Tunggu sebentar lalu paksa selesai
        task.wait(2.7)
        netIndex:WaitForChild("RE/FishingCompleted"):FireServer()
    end)

    if success then
        fishCount = fishCount + 1
        print(string.format(">> FISHING COMPLETE! Count: %d/5", fishCount))

        -- Auto sell setiap 5 ikan
        if fishCount >= 5 then
            SellAll()
        end

        task.wait(0.5)
        return true
    else
        warn(">> FISHING FAILED:", err)
        task.wait(2)
        return false
    end
end


local function CheckAndBuyNextRod()
    local ownedRods = GetOwnedRods()
    local money = GetMoney()
    
    for i, rodData in ipairs(RodData) do
        if not ownedRods[rodData.id] and money >= rodData.price then
            if BuyRod(rodData) then
                wait(1)
                ownedRods = GetOwnedRods()
                if ownedRods[rodData.id] then
                    EquipRod(ownedRods[rodData.id])
                    currentRodIndex = i
                    return true
                end
            end
        end
    end
    return false
end

local function GetDeepSeaProgress()
    local deepSeaData = data:Get({"DeepSea", "Available"})
    if not deepSeaData or not deepSeaData.Forever or not deepSeaData.Forever.Quests then
        deepSeaData = data:Get({"DeepSea"})
    end
    
    if deepSeaData and deepSeaData.Forever and deepSeaData.Forever.Quests then
        return deepSeaData.Forever.Quests
    end
    return nil
end

local function CheckDeepSeaQuest(questIndex, targetProgress)
    local quests = GetDeepSeaProgress()
    if quests and quests[questIndex] then
        local progress = quests[questIndex].Progress or 0
        return progress >= targetProgress
    end
    return false
end

local function FarmUntilRod(targetRodIndex)
    print(string.format(">> FARMING UNTUK ROD: %s", RodData[targetRodIndex].name))
    
    while true do
        local money = GetMoney()
        local ownedRods = GetOwnedRods()
        
        -- Check if we already own this rod
        if ownedRods[RodData[targetRodIndex].id] then
            print(string.format(">> SUDAH MEMILIKI: %s", RodData[targetRodIndex].name))
            if not ownedRods[RodData[targetRodIndex].id] then
                ownedRods = GetOwnedRods()
            end
            EquipRod(ownedRods[RodData[targetRodIndex].id])
            currentRodIndex = targetRodIndex
            break
        end
        
        -- Check if we have enough money to buy
        if money >= RodData[targetRodIndex].price then
            if CheckAndBuyNextRod() then
                break
            end
        end
        
        -- Keep fishing
        DoFishing()
        wait(0.5)
    end
end

local function FarmAtLocation(locationIndex, rodTargets)
    local location = Map[locationIndex]
    Teleport(location.x, location.y, location.z, location.name)
    
    for _, rodIndex in ipairs(rodTargets) do
        FarmUntilRod(rodIndex)
    end
end

local function FarmSisyphusSecret()
    print(">> FARMING SISYPHUS SECRET QUEST...")
    local location = Map[3]
    Teleport(location.x, location.y, location.z, location.name)
    
    -- Quest index 3: Catch 1 SECRET fish at Sisyphus Statue
    while not CheckDeepSeaQuest(3, 1) do
        DoFishing()
        wait(0.5)
        
        if CheckDeepSeaQuest(3, 1) then
            print(">> SISYPHUS SECRET QUEST COMPLETE!")
            break
        end
    end
end

local function FarmTreasureRoomQuest()
    print(">> FARMING TREASURE ROOM QUEST (300 Rare/Epic)...")
    local location = Map[4]
    Teleport(location.x, location.y, location.z, location.name)
    
    -- Quest index 1: Catch 300 Rare/Epic fish in the Treasure Room
    while not CheckDeepSeaQuest(1, 300) do
        DoFishing()
        wait(0.5)
        
        local quests = GetDeepSeaProgress()
        if quests and quests[1] then
            local progress = quests[1].Progress or 0
            if progress % 10 == 0 then
                print(string.format(">> TREASURE ROOM PROGRESS: %.0f/300", progress))
            end
        end
        
        if CheckDeepSeaQuest(1, 300) then
            print(">> TREASURE ROOM QUEST COMPLETE!")
            break
        end
    end
end

-- Main Execution
print("=" .. string.rep("=", 50))
print(">> AUTO FARM FISHING STARTED!")
print("=" .. string.rep("=", 50))

-- Initial equip from hotbar
pcall(function()
    netIndex:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
end)
wait(1)

-- Step 1-2: Location 1 (Fisherman Island) - Rod 1
print("\n>> STEP 1: LOKASI 1 - FISHERMAN ISLAND")
FarmAtLocation(1, {1})

-- Step 3: Continue at Location 1 - Rod 2
print("\n>> STEP 2: LANJUT LOKASI 1 - UPGRADE ROD")
FarmAtLocation(1, {2})

-- Step 4: Location 2 (Kohana Island) - Rod 3, 4, 5
print("\n>> STEP 3: LOKASI 2 - KOHANA ISLAND")
FarmAtLocation(2, {3, 4, 5})

-- Step 5: Location 3 (Sisyphus Statue) - Farm Secret Quest
print("\n>> STEP 4: LOKASI 3 - SISYPHUS STATUE (SECRET QUEST)")
FarmSisyphusSecret()

-- Step 6: Location 4 (Treasure Room) - Farm 300 Rare/Epic
print("\n>> STEP 5: LOKASI 4 - TREASURE ROOM (300 RARE/EPIC)")
FarmTreasureRoomQuest()

print("\n" .. string.rep("=", 50))
print(">> AUTO FARM COMPLETE!")
print("=" .. string.rep("=", 50))
