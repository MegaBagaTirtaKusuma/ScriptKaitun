-- =========================================================
-- 👑 KING BAGAS – ULTRA AUTO FISH FINAL
-- AUTO BEST ROD + TELEPORT PROGRESSION (NO FEATURE REMOVED)
-- =========================================================

local P = game:GetService("Players").LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local C = P.Character or P.CharacterAdded:Wait()
local Repl = require(RS.Packages.Replion).Client:WaitReplion("Data")
local NET = RS.Packages._Index["sleitnick_net@0.2.0"].net
local VIM = game:GetService("VirtualInputManager")

-- ================= CONFIG =================
local USE_GAME_AUTO_FISH = true
local ENABLE_RAPID_CLICK = true
local CLICK_SPEED = 0.01
local CLICK_DURATION = 2.5
-- =========================================

-- MODE FLAG (⚠️ JANGAN DIHAPUS)
local PROGRESS_MODE = true

-- Anti AFK
P.Idled:Connect(function()
 local v = game:GetService("VirtualUser")
 v:CaptureController()
 v:ClickButton2(Vector2.zero)
end)

-- ================= DATA =================
-- {id, price, uuid}
local RODS = {
 {79, 325, "4315aa13-5964-4e5d-bda1-84ba5b193695"},      -- Luck
 {4, 15000, "1aaba2cd-9ed5-42f0-87fd-380d7acdc600"},   -- Lucky
 {80, 50000, "0c860299-a465-45ad-bcf4-46ae245a8bcd"},  -- Midnight
 {6, 215000, "56fceb1c-b6ba-4f76-8523-31e87aa40c59"},  -- Steampunk
 {5, 1000000, "28b54c20-7a83-413a-afb5-2df2853dd991"}  -- Astral
}

local LOCS = {
 {129.1,3.5,2750.8},
 {-534.4,19.1,162.8},
 {-3733.7,-135.1,-885.9},
 {-3597.1,-275.6,-1640.9}
}

local AUTO_FISH_ENABLED = false
local CLICKING = false
local FC = 0

-- ================= HELPERS =================
local function GM()
 local ok,v = pcall(function()
  return Repl:GetExpect("Coins")
 end)
 return (ok and type(v)=="number") and v or 0
end

-- ✅ FIXED INVENTORY READ
local function GET_OWNED_RODS()
 local inv = Repl:GetExpect({"Inventory","Fishing Rods"}) or {}
 local out = {}
 for _,it in pairs(inv) do
  if it.Id then
   out[it.Id] = it.UUID or true
  end
 end
 return out
end

local function ENABLE_AUTO_FISHING()
 if AUTO_FISH_ENABLED then return end
 for i=1,3 do
  local ok = pcall(function()
   NET:WaitForChild("RF/UpdateAutoFishingState"):InvokeServer(true)
  end)
  if ok then
   AUTO_FISH_ENABLED = true
   return
  end
  task.wait(0.4)
 end
end

local function EQUIP_ROD(uuid)
 if type(uuid) ~= "string" then return end
 pcall(function()
  NET:WaitForChild("RE/EquipItem"):FireServer(uuid, "Fishing Rods")
 end)
 task.wait(0.15)
 pcall(function()
  NET:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
 end)
 task.wait(0.15)
 ENABLE_AUTO_FISHING()
end

-- ✅ AUTO BEST ROD (GLOBAL)
local function EQUIP_BEST_ROD()
 local owned = GET_OWNED_RODS()
 for i = #RODS, 1, -1 do
  local id = RODS[i][1]
  if owned[id] then
   if type(owned[id]) == "string" then
    EQUIP_ROD(owned[id])
   end
   return true
  end
 end
 return false
end

-- ================= RAPID CLICK =================
local function MINIGAME_ACTIVE()
 return P.PlayerGui:FindFirstChild("FishingMinigame", true) ~= nil
end

local function RAPID_CLICK()
 if CLICKING then return end
 CLICKING = true
 task.spawn(function()
  local start = tick()
  while tick() - start < CLICK_DURATION do
   local cam = workspace.CurrentCamera.ViewportSize
   local x,y = cam.X/2, cam.Y/2
   VIM:SendMouseButtonEvent(x,y,0,true,game,0)
   task.wait(0.001)
   VIM:SendMouseButtonEvent(x,y,0,false,game,0)
   task.wait(CLICK_SPEED)
  end
  CLICKING = false
 end)
end

-- ================= CORE =================
local function SELL()
 pcall(function()
  NET:WaitForChild("RF/SellAllItems"):InvokeServer()
 end)
 FC = 0
end

local function FISH()
 if not PROGRESS_MODE then
  EQUIP_BEST_ROD()
 end

 if ENABLE_RAPID_CLICK then
  task.wait(0.8)
  if MINIGAME_ACTIVE() then
   RAPID_CLICK()
  end
 end

 task.wait(3.2)
 FC += 1
 if FC >= 5 then SELL() end
 task.wait(0.25 + math.random()*0.15)
end

local function BUY_ROD(idx)
 if GM() < RODS[idx][2] then return false end
 return pcall(function()
  NET:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(RODS[idx][1])
 end)
end

local function FARM_ROD(idx)
 local id = RODS[idx][1]
 while true do
  local owned = GET_OWNED_RODS()
  if owned[id] then
   EQUIP_BEST_ROD()
   break
  end

  if GM() >= RODS[idx][2] then
   BUY_ROD(idx)
   task.wait(0.6)
  end

  FISH()
 end
end

-- ================= TELEPORT =================
local function TP(i)
 local hrp = C:WaitForChild("HumanoidRootPart")
 hrp.CFrame = CFrame.new(
  LOCS[i][1],
  LOCS[i][2],
  LOCS[i][3]
 )
 task.wait(0.4)
end

-- ================= MAIN FLOW =================
print("======================================")
print(" ULTRA AUTO FISH – FINAL PROGRESSION ")
print("======================================")

-- PHASE 1
TP(1)
FARM_ROD(1)
FARM_ROD(2)

-- PHASE 2
TP(2)
FARM_ROD(3)

-- PHASE 3
TP(4)
FARM_ROD(4)
FARM_ROD(5)

-- ENDGAME MODE
PROGRESS_MODE = false
TP(3)

while true do
 FISH()
end
