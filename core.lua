-- =========================================================
-- 👑 KING BAGAS – HYBRID AUTO FISH FINAL (PASTI MANCING)
-- LV 1–2  : OLD AUTO FISH (NO MINIGAME)
-- LV 3+   : FAST BITE CLICK + AUTO BEST ROD
-- =========================================================

local P=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local C=P.Character or P.CharacterAdded:Wait()
local Repl=require(RS.Packages.Replion).Client:WaitReplion("Data")
local NET=RS.Packages._Index["sleitnick_net@0.2.0"].net
local VIM=game:GetService("VirtualInputManager")

-- anti-afk
P.Idled:Connect(function()
 local v=game:GetService("VirtualUser")
 v:CaptureController()
 v:ClickButton2(Vector2.zero)
end)

-- ================= DATA =================
local R={
 {79,325,"4315aa13-5964-4e5d-bda1-84ba5b193695"}, -- Luck
 {4,15000,"1aaba2cd-9ed5-42f0-87fd-380d7acdc600"}, -- Lucky
 {80,50000,"0c860299-a465-45ad-bcf4-46ae245a8bcd"}, -- Midnight
 {6,215000,"56fceb1c-b6ba-4f76-8523-31e87aa40c59"}, -- Steampunk
 {5,1000000,"28b54c20-7a83-413a-afb5-2df2853dd991"} -- Astral
}

local LOCS={
 {129.1,3.5,2750.8},
 {-534.4,19.1,162.8},
 {-3733.7,-135.1,-885.9},
 {-3597.1,-275.6,-1640.9}
}

local T={
 ["4315aa13-5964-4e5d-bda1-84ba5b193695"]={.05,2.3},
 ["1aaba2cd-9ed5-42f0-87fd-380d7acdc600"]={.05,1.9},
 ["0c860299-a465-45ad-bcf4-46ae245a8bcd"]={.05,1.4},
 ["56fceb1c-b6ba-4f76-8523-31e87aa40c59"]={.05,1.3},
 ["28b54c20-7a83-413a-afb5-2df2853dd991"]={.05,1.0},
}
local DEF_THROW,DEF_PULL=0.05,2.8

local FC=0
local CLICKING=false

-- ================= HELPERS =================
local function GM()
 local ok,v=pcall(function()return Repl:GetExpect("Coins")end)
 return (ok and type(v)=="number") and v or 0
end

local function GET_LEVEL()
 local s=Repl:Get("Stats")
 return (s and s.Level) or 1
end

local function GO()
 local out={}
 for _,it in pairs(Repl:GetExpect({"Inventory","Fishing Rods"}) or {}) do
  out[it.Id]=it.UUID or true
 end
 return out
end

local function CUR_DELAYS()
 local eq=Repl:GetExpect("EquippedItems") or {}
 local uuid=eq[1]
 if type(uuid)~="string" then return DEF_THROW,DEF_PULL end
 local c=T[uuid]
 return c and c[1],c and c[2] or DEF_PULL
end

local function EQU(uuid)
 if type(uuid)~="string" then return end
 pcall(function()
  NET:WaitForChild("RE/EquipItem"):FireServer(uuid,"Fishing Rods")
 end)
 task.wait(0.2)
 pcall(function()
  NET:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)
 end)
end

-- ================= FAST CLICK (LV 3+) =================
local function MINIGAME_ACTIVE()
 return P.PlayerGui:FindFirstChild("FishingMinigame",true)~=nil
end

local function RAPID_CLICK()
 if CLICKING then return end
 CLICKING=true
 task.spawn(function()
  local cam=workspace.CurrentCamera.ViewportSize
  local x,y=cam.X/2,cam.Y/2
  local t=tick()
  while tick()-t<2.5 do
   VIM:SendMouseButtonEvent(x,y,0,true,game,0)
   task.wait(0.002)
   VIM:SendMouseButtonEvent(x,y,0,false,game,0)
   task.wait(0.008)
  end
  CLICKING=false
 end)
end

-- ================= CORE FISH =================
local function SELL()
 pcall(function()
  NET:WaitForChild("RF/SellAllItems"):InvokeServer()
 end)
 FC=0
end

-- 🔥 AUTO FISH LAMA (PASTI WORK LV 1–2)
local function FISH_OLD()
 local ok=pcall(function()
  local th,pl=CUR_DELAYS()
  task.wait(0.08)
  NET:WaitForChild("RF/ChargeFishingRod"):InvokeServer()
  task.wait(th)
  NET:WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(-1.23,0.14,tick())
  task.wait(pl)
  NET:WaitForChild("RE/FishingCompleted"):FireServer()
 end)
 if ok then FC+=1 if FC>=5 then SELL() end end
 task.wait(0.35)
end

-- ⚡ AUTO FISH BARU (LV 3+)
local function FISH_NEW()
 if MINIGAME_ACTIVE() then
  RAPID_CLICK()
 end
 task.wait(3.2)
 FC+=1
 if FC>=5 then SELL() end
 task.wait(0.3)
end

local function FISH()
 if GET_LEVEL()<3 then
  FISH_OLD()
 else
  FISH_NEW()
 end
end

-- ================= PROGRESSION =================
local function TP(i)
 local h=C:WaitForChild("HumanoidRootPart")
 h.CFrame=CFrame.new(LOCS[i][1],LOCS[i][2],LOCS[i][3])
 task.wait(0.4)
end

local function BUY(r)
 if GM()<r[2] then return false end
 return pcall(function()
  NET:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(r[1])
 end)
end

local function FARM_ROD(idx)
 local id=R[idx][1]
 while true do
  local owned=GO()
  if owned[id] then
   if type(owned[id])=="string" then EQU(owned[id]) end
   break
  end
  if GM()>=R[idx][2] then BUY(R[idx]) task.wait(0.6) end
  FISH()
 end
end

-- ================= MAIN =================
print(">> HYBRID AUTO FISH STARTED")

TP(1)
FARM_ROD(1)
FARM_ROD(2)

TP(2)
FARM_ROD(3)

TP(4)
FARM_ROD(4)
FARM_ROD(5)

TP(3)
while true do
 FISH()
end
