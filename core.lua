-- ULTRA LIGHT AUTO FISH (AUTO FISHING + RAPID CLICK MINIGAME)
local P=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local C=P.Character or P.CharacterAdded:Wait()
local Repl=require(RS.Packages.Replion).Client:WaitReplion("Data")
local NET=RS.Packages._Index["sleitnick_net@0.2.0"].net
local VIM=game:GetService("VirtualInputManager")
local UIS=game:GetService("UserInputService")

-- ============================================
-- CONFIG: AUTO CLICK SETTINGS
-- ============================================
local USE_GAME_AUTO_FISH = true -- Pakai auto fishing bawaan game
local ENABLE_RAPID_CLICK = true -- Spam click saat minigame
local CLICK_SPEED = 0.01 -- Delay antar click (makin kecil makin cepat)
local CLICK_DURATION = 2.0 -- Durasi spam click (seconds)
local CLICK_DELAY_START = 1.2 -- Delay sebelum mulai click (tunggu minigame muncul)
local SHOW_NOTIFICATIONS = false -- Notifikasi OFF
-- ============================================

-- anti-afk (lightweight)
local lastInput=tick()
P.Idled:Connect(function()
 if tick()-lastInput>60 then
  local v=game:GetService("VirtualUser")
  v:CaptureController()
  v:ClickButton2(Vector2.zero)
  lastInput=tick()
 end
end)

-- rod table: {id,price,uuid}
local R={
 {79,325,"4315aa13-5964-4e5d-bda1-84ba5b193695"}, -- Luck
 {4,15000,"1aaba2cd-9ed5-42f0-87fd-380d7acdc600"}, -- Lucky
 {80,50000,"0c860299-a465-45ad-bcf4-46ae245a8bcd"}, -- Midnight
 {6,215000,"56fceb1c-b6ba-4f76-8523-31e87aa40c59"}, -- Steampunk
 {5,1000000,"28b54c20-7a83-413a-afb5-2df2853dd991"}   -- Astral
}

-- bait table: {id,price,name}
local BAITS={
 {15,1148484,"Corrupt Bait"},
 {16,3700000,"Aether Bait"}
}

-- delays by uuid (throw,pull) fallback starter
local T={
 ["4315aa13-5964-4e5d-bda1-84ba5b193695"]={.05,2.3},
 ["1aaba2cd-9ed5-42f0-87fd-380d7acdc600"]={.05,1.9},
 ["0c860299-a465-45ad-bcf4-46ae245a8bcd"]={.05,1.4},
 ["56fceb1c-b6ba-4f76-8523-31e87aa40c59"]={.05,1.3},
 ["28b54c20-7a83-413a-afb5-2df2853dd991"]={.05,1.0},
}
local DEF_THROW,DEF_PULL=0.05,2.8
local LOCS={{129.1,3.5,2750.8},{-534.4,19.1,162.8},{-3733.7,-135.1,-885.9},{-3597.1,-275.6,-1640.9}}

local FC=0
local BAIT_EQUIPPED={}
local AUTO_FISH_ENABLED=false
local CLICKING=false
local SCREEN_CENTER -- Cache screen center

-- Notification helper (minimal overhead)
local function NOTIFY(text, duration)
 if not SHOW_NOTIFICATIONS then return end
 local sg=game:GetService("StarterGui")
 sg:SetCore("SendNotification",{Title="🎣 Bot",Text=text,Duration=duration or 2})
end

-- Rapid click function (optimized)
local function RAPID_CLICK()
 if not ENABLE_RAPID_CLICK or CLICKING then return end
 CLICKING=true
 
 -- Cache screen center once
 if not SCREEN_CENTER then
  local vs=workspace.CurrentCamera.ViewportSize
  SCREEN_CENTER={vs.X/2,vs.Y/2}
 end
 
 task.spawn(function()
  local endTime=tick()+CLICK_DURATION
  local cx,cy=SCREEN_CENTER[1],SCREEN_CENTER[2]
  
  while tick()<endTime do
   VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
   VIM:SendMouseButtonEvent(cx,cy,0,false,game,0)
   task.wait(CLICK_SPEED)
  end
  
  CLICKING=false
 end)
end

-- Enable game's auto fishing (cached)
local function ENABLE_AUTO_FISHING()
 if not USE_GAME_AUTO_FISH or AUTO_FISH_ENABLED then return end
 
 if NET_CACHE.AutoFish:InvokeServer(true) then
  AUTO_FISH_ENABLED=true
  print(">> Auto Fishing enabled")
 end
end

local function W(t) task.wait(t) end
local function GM() 
 local v=Repl:GetExpect("Coins")
 return (typeof(v)=="number" and v) or Repl:Get("Coins") or 0
end
local function GO() 
 local out={}
 local inv=Repl:GetExpect({"Inventory","Fishing Rods"}) or {}
 for _,it in pairs(inv) do out[it.Id]=it.UUID end
 return out
end
local function CUR_DELAYS() 
 local uuid=(Repl:GetExpect("EquippedItems") or {})[1]
 if uuid and T[uuid] then return T[uuid][1],T[uuid][2] end
 return DEF_THROW,DEF_PULL
end
local function TP(i) 
 local h=C:WaitForChild("HumanoidRootPart")
 local from,to=h.Position,Vector3.new(LOCS[i][1],LOCS[i][2],LOCS[i][3])
 for k=1,6 do 
  h.CFrame=CFrame.new(from:Lerp(to,k/6))
  task.wait(0.03)
 end
 task.wait(0.25)
end
local function BUY(rid) 
 return GM()>=rid[2] and NET_CACHE.PurchaseRod:InvokeServer(rid[1])
end
local function EQU(uuid)
 NET_CACHE.EquipItem:FireServer(uuid,"Fishing Rods")
 task.wait(0.18)
 NET_CACHE.EquipTool:FireServer(1)
 task.wait(0.12)
 return true
end
local function SELL() 
 NET_CACHE.SellAll:InvokeServer()
 FC=0
end

-- bait functions (optimized)
local function GET_OWNED_BAITS()
 local inv=Repl:GetExpect({"Inventory","Baits"}) or {}
 local owned={}
 for _,b in pairs(inv) do owned[b.Id]=true end
 return owned
end

local function BUY_BAIT(bait)
 if GM()<bait[2] then return false end
 if NET_CACHE.PurchaseBait:InvokeServer(bait[1]) then
  print(">> Bought:",bait[3])
  task.wait(0.5)
  return true
 end
 return false
end

local function EQUIP_BAIT(baitId)
 NET_CACHE.EquipBait:FireServer(baitId)
 BAIT_EQUIPPED[baitId]=true
 task.wait(0.3)
 return true
end

local function CHECK_BEST_BAIT()
 local owned=GET_OWNED_BAITS()
 for i=#BAITS,1,-1 do
  local bait=BAITS[i]
  if owned[bait[1]] then
   if not BAIT_EQUIPPED[bait[1]] then
    EQUIP_BAIT(bait[1])
   end
   return true
  end
 end
 return false
end

-- check secret quest (cached lookup)
local function CHK_SECRET()
 local ds=Repl:Get({"DeepSea","Available"}) or Repl:Get("DeepSea")
 return ds and ds.Forever and ds.Forever.Quests and ds.Forever.Quests[3] and (ds.Forever.Quests[3].Progress or 0)>=1
end

-- FORWARD DECLARATION
local FISH

-- FISH function (optimized - cached calls)
FISH = function()
 CHECK_BEST_BAIT()
 
 if USE_GAME_AUTO_FISH then
  if ENABLE_RAPID_CLICK then
   task.wait(CLICK_DELAY_START)
   RAPID_CLICK()
   task.wait(CLICK_DURATION+0.3)
  else
   task.wait(3.5)
  end
  FC=FC+1
  if FC>=5 then SELL() end
  return true
 else
  -- Custom fishing (cached network calls)
  local th,pl=CUR_DELAYS()
  task.wait(0.08)
  NET_CACHE.ChargeFishingRod:InvokeServer()
  task.wait(th+(math.random(-5,5)/1000))
  NET_CACHE.RequestFishing:InvokeServer(-1.23+math.random(-3,3)*0.01,0.14+math.random(-3,3)*0.01,tick())
  if ENABLE_RAPID_CLICK then RAPID_CLICK() end
  task.wait(pl+(math.random(-10,10)/1000))
  NET_CACHE.FishingComplete:FireServer()
  FC=FC+1
  if FC>=5 then SELL() end
  task.wait(0.35)
  return true
 end
end

local function FARM_BAIT(idx)
 local bait=BAITS[idx]
 while true do
  local owned=GET_OWNED_BAITS()
  if owned[bait[1]] then
   EQUIP_BAIT(bait[1])
   break
  end
  if GM()>=bait[2] then
   if BUY_BAIT(bait) then
    task.wait(0.6)
    owned=GET_OWNED_BAITS()
    if owned[bait[1]] then
     EQUIP_BAIT(bait[1])
     break
    end
   end
  end
  if CHK_SECRET() then
   print(">> Secret Quest Complete!")
   return true
  end
  FISH()
 end
 return false
end

local function FARM_ROD(idx)
 local id=R[idx][1]
 local first=true
 while true do
  local owned=GO()
  if owned[id] then 
   EQU(owned[id])
   if first then ENABLE_AUTO_FISHING() first=false end
   break
  end
  if BUY(R[idx]) then 
   task.wait(0.6)
   owned=GO()
   if owned[id] then 
    EQU(owned[id])
    if first then ENABLE_AUTO_FISHING() first=false end
    break
   end
  end
  FISH()
 end
end

-- Show mode at start
print("===========================================")
print("   ULTRA AUTO FISH - BACKGROUND CLICK")
print("===========================================")
print("Game Auto Fish:", USE_GAME_AUTO_FISH and "✓ ENABLED" or "✗ DISABLED")
print("Background Click:", ENABLE_RAPID_CLICK and "✓ ENABLED" or "✗ DISABLED")
if ENABLE_RAPID_CLICK then
 print("Click Speed:", CLICK_SPEED.."s | Duration:", CLICK_DURATION.."s")
 print("Estimated clicks per catch:", math.floor(CLICK_DURATION/CLICK_SPEED))
end
print("Notifications: ✗ DISABLED")
print("Screen: ✓ FREE TO USE")
print("===========================================")
task.wait(2)

-- progression
print(">> Phase 1: Farming Luck & Lucky Rods...")
TP(1) FARM_ROD(1) FARM_ROD(2)

print(">> Phase 2: Farming Midnight Rod...")
TP(2) FARM_ROD(3)

local owned=GO()
if owned[R[3][1]] then
  print(">> Phase 3: Farming Steampunk & Astral Rods...")
  TP(4)
  FARM_ROD(4)
  FARM_ROD(5)
end

owned=GO()
if owned[R[5][1]] then
  print(">> Astral Rod owned! Moving to Sisyphus...")
  TP(3)
  
  print(">> Farming Corrupt Bait...")
  if FARM_BAIT(1)==true then
   print(">> COMPLETE! (Secret obtained during Corrupt Bait farm)")
   return
  end
  
  print(">> Farming Aether Bait...")
  if FARM_BAIT(2)==true then
   print(">> COMPLETE! (Secret obtained during Aether Bait farm)")
   return
  end
  
  print(">> Farming for Secret Quest completion...")
  while not CHK_SECRET() do FISH() end
end

print(">> COMPLETE!")
