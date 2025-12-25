-- ULTRA LIGHT AUTO FISH (WITH ANIMATION MODE)
local P=game:GetService("Players").LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local C=P.Character or P.CharacterAdded:Wait()
local Repl=require(RS.Packages.Replion).Client:WaitReplion("Data")
local NET=RS.Packages._Index["sleitnick_net@0.2.0"].net

-- ============================================
-- CONFIG: ANIMATION MODE
-- ============================================
local SHOW_ANIMATION = true -- Set false untuk fast mode
local ANIMATION_DELAYS = {
 charge = 0.8,   -- Delay setelah charge rod (lihat animasi charge)
 throw = 2.0,    -- Delay setelah lempar (tunggu ikan gigit)
 catch = 0.8,    -- Delay setelah dapat ikan
 cooldown = 0.8  -- Cooldown sebelum mancing lagi
}
local SHOW_NOTIFICATIONS = true -- Set false untuk disable notif
-- ============================================

-- anti-afk
P.Idled:Connect(function()local v=game:GetService("VirtualUser")v:CaptureController()v:ClickButton2(Vector2.zero)end)

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

-- Notification helper
local function NOTIFY(text, duration)
 if not SHOW_NOTIFICATIONS then return end
 pcall(function()
  game:GetService("StarterGui"):SetCore("SendNotification", {
   Title = "🎣 Fishing Bot";
   Text = text;
   Duration = duration or 2;
  })
 end)
end

local function W(t) task.wait(t) end
local function GM() local ok,v=pcall(function()return Repl:GetExpect("Coins")end) if ok and typeof(v)=="number" then return v end v=Repl:Get("Coins") return (typeof(v)=="number" and v) or 0 end
local function GO() local out={} for _,it in pairs(Repl:GetExpect({"Inventory","Fishing Rods"}) or {}) do out[it.Id]=it.UUID end return out end
local function CUR_DELAYS() local eq=Repl:GetExpect("EquippedItems") or {} local uuid=eq[1] if type(uuid)~="string" or uuid=="" then return DEF_THROW,DEF_PULL end local c=T[uuid] if c then return c[1],c[2] end return DEF_THROW,DEF_PULL end
local function TP(i) local h=C:WaitForChild("HumanoidRootPart") local from=h.Position local to=Vector3.new(LOCS[i][1],LOCS[i][2],LOCS[i][3]) for k=1,6 do h.CFrame=CFrame.new(from:Lerp(to,k/6)) task.wait(0.03) end task.wait(0.25) end
local function BUY(rid) if GM()<rid[2] then return false end local ok,err=pcall(function() NET:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(rid[1]) end) return ok end
local function EQU(uuid) local ok=pcall(function() NET:WaitForChild("RE/EquipItem"):FireServer(uuid,"Fishing Rods") end) if ok then task.wait(0.18) pcall(function() NET:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1) end) task.wait(0.12) return true end return false end
local function SELL() pcall(function() NET:WaitForChild("RF/SellAllItems"):InvokeServer() end) FC=0 NOTIFY("💰 Sold all fish!",1.5) end

-- bait functions
local function GET_OWNED_BAITS()
 local inv=Repl:GetExpect({"Inventory","Baits"}) or {}
 local owned={}
 for _,b in pairs(inv) do owned[b.Id]=true end
 return owned
end

local function BUY_BAIT(bait)
 if GM()<bait[2] then return false end
 local ok=pcall(function() NET:WaitForChild("RF/PurchaseBait"):InvokeServer(bait[1]) end)
 if ok then
  print(">> Bought:",bait[3])
  NOTIFY("Bought: "..bait[3],2)
  task.wait(0.5)
  return true
 end
 return false
end

local function EQUIP_BAIT(baitId)
 local ok=pcall(function() NET:WaitForChild("RE/EquipBait"):FireServer(baitId) end)
 if ok then
  BAIT_EQUIPPED[baitId]=true
  print(">> Equipped Bait:",baitId)
  task.wait(0.3)
  return true
 end
 return false
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

local function CHK_SECRET()
 local ds=Repl:Get({"DeepSea","Available"}) 
 if ds and ds.Forever and ds.Forever.Quests and ds.Forever.Quests[3] then 
  return (ds.Forever.Quests[3].Progress or 0)>=1 
 end
 ds=Repl:Get("DeepSea") 
 if ds and ds.Forever and ds.Forever.Quests and ds.Forever.Quests[3] then 
  return (ds.Forever.Quests[3].Progress or 0)>=1 
 end
 return false
end

-- FORWARD DECLARATION
local FISH

-- FISH function with animation mode
FISH = function()
 CHECK_BEST_BAIT()
 
 local ok,err=pcall(function()
   local th,pl=CUR_DELAYS()
   
   -- Step 1: Charge rod
   task.wait(0.08) 
   NET:WaitForChild("RF/ChargeFishingRod"):InvokeServer()
   
   if SHOW_ANIMATION then
    print(">> [1/3] ⚡ Charging rod...")
    NOTIFY("⚡ Charging rod...",ANIMATION_DELAYS.charge)
    task.wait(ANIMATION_DELAYS.charge)
   else
    task.wait(th + (math.random(-5,5)/1000))
   end
   
   -- Step 2: Throw rod
   NET:WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(
     -1.23+math.random(-3,3)*0.01,
     0.14+math.random(-3,3)*0.01,
     tick()
   )
   
   if SHOW_ANIMATION then
    print(">> [2/3] 🎣 Rod thrown! Waiting for bite...")
    NOTIFY("🎣 Waiting for bite...",ANIMATION_DELAYS.throw)
    task.wait(ANIMATION_DELAYS.throw)
   else
    task.wait(pl + (math.random(-10,10)/1000))
   end
   
   -- Step 3: Complete fishing
   NET:WaitForChild("RE/FishingCompleted"):FireServer()
   
   if SHOW_ANIMATION then
    print(">> [3/3] ✓ Fish caught!")
    NOTIFY("🐟 Fish caught!",ANIMATION_DELAYS.catch)
    task.wait(ANIMATION_DELAYS.catch)
   end
   
 end)
 
 if ok then 
   FC=FC+1 
   if FC>=5 then SELL() end 
   task.wait(SHOW_ANIMATION and ANIMATION_DELAYS.cooldown or 0.35) 
   return true 
 end 
 
 if SHOW_ANIMATION then
  print(">> ✗ Fishing failed, retrying...")
 end
 task.wait(1.2) 
 return false
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
   print(">> SECRET COMPLETE WHILE FARMING BAIT!")
   NOTIFY("✓ Secret Quest Complete!",3)
   return true
  end
  FISH()
 end
 return false
end

local function FARM_ROD(idx)
 local id=R[idx][1]
 while true do
   local owned=GO()
   if owned[id] then EQU(owned[id]) break end
   if GM()>=R[idx][2] then if BUY(R[idx]) then task.wait(0.6) owned=GO() if owned[id] then EQU(owned[id]) break end end end
   FISH()
 end
end

-- Show mode at start
print("===========================================")
print("   ULTRA LIGHT AUTO FISH - ANIMATION MODE")
print("===========================================")
print("Animation Mode:", SHOW_ANIMATION and "✓ ENABLED" or "✗ DISABLED")
print("Notifications:", SHOW_NOTIFICATIONS and "✓ ENABLED" or "✗ DISABLED")
if SHOW_ANIMATION then
 print("Delays: Charge="..ANIMATION_DELAYS.charge.."s | Throw="..ANIMATION_DELAYS.throw.."s | Catch="..ANIMATION_DELAYS.catch.."s")
end
print("===========================================")
NOTIFY("Bot started!",2)

-- progression:
-- 1) loc1 -> farm R[1],R[2]
print(">> Phase 1: Farming Luck & Lucky Rods...")
TP(1) FARM_ROD(1) FARM_ROD(2)

-- 2) loc2 -> farm R[3] (Midnight)
print(">> Phase 2: Farming Midnight Rod...")
TP(2) FARM_ROD(3)

-- once midnight owned -> go to loc4 and farm R[4],R[5]
local owned=GO()
if owned[R[3][1]] then
  print(">> Phase 3: Farming Steampunk & Astral Rods...")
  TP(4)
  FARM_ROD(4)
  FARM_ROD(5)
end

-- after astral owned -> go to sisyphus and farm baits + secret quest
owned=GO()
if owned[R[5][1]] then
  print(">> Astral Rod owned! Moving to Sisyphus...")
  NOTIFY("Astral Rod equipped!",2)
  TP(3)
  
  -- Farm Corrupt Bait
  print(">> Farming Corrupt Bait...")
  if FARM_BAIT(1)==true then
   print(">> COMPLETE! (Secret obtained during Corrupt Bait farm)")
   NOTIFY("✓ COMPLETE!",3)
   return
  end
  
  -- Farm Aether Bait
  print(">> Farming Aether Bait...")
  if FARM_BAIT(2)==true then
   print(">> COMPLETE! (Secret obtained during Aether Bait farm)")
   NOTIFY("✓ COMPLETE!",3)
   return
  end
  
  -- farm until secret quest done
  print(">> Farming for Secret Quest completion...")
  while not CHK_SECRET() do FISH() end
end

-- done
print(">> COMPLETE!")
NOTIFY("✓ Bot Complete!",5)
