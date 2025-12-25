local SHOW_NOTIFICATIONS = false -- Notifikasi OFF
-- ============================================

-- anti-afk
P.Idled:Connect(function()local v=game:GetService("VirtualUser")v:CaptureController()v:ClickButton2(Vector2.zero)end)
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
@@ -51,70 +59,91 @@ local FC=0
local BAIT_EQUIPPED={}
local AUTO_FISH_ENABLED=false
local CLICKING=false
local SCREEN_CENTER -- Cache screen center

-- Notification helper
-- Notification helper (minimal overhead)
local function NOTIFY(text, duration)
if not SHOW_NOTIFICATIONS then return end
 pcall(function()
  game:GetService("StarterGui"):SetCore("SendNotification", {
   Title = "🎣 Fishing Bot";
   Text = text;
   Duration = duration or 2;
  })
 end)
 local sg=game:GetService("StarterGui")
 sg:SetCore("SendNotification",{Title="🎣 Bot",Text=text,Duration=duration or 2})
end

-- Rapid click function (simple & effective)
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
  local start_time = tick()
  local clicks = 0
  local screenSize = workspace.CurrentCamera.ViewportSize
  local centerX, centerY = screenSize.X/2, screenSize.Y/2
  local endTime=tick()+CLICK_DURATION
  local cx,cy=SCREEN_CENTER[1],SCREEN_CENTER[2]

  while tick() - start_time < CLICK_DURATION do
   -- Simple VIM click (most reliable method)
   local success = pcall(function()
    VIM:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
    task.wait(0.001)
    VIM:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
   end)
   
   if success then clicks = clicks + 1 end
  while tick()<endTime do
   VIM:SendMouseButtonEvent(cx,cy,0,true,game,0)
   VIM:SendMouseButtonEvent(cx,cy,0,false,game,0)
task.wait(CLICK_SPEED)
end

CLICKING=false
end)
end

-- Enable game's auto fishing
-- Enable game's auto fishing (cached)
local function ENABLE_AUTO_FISHING()
if not USE_GAME_AUTO_FISH or AUTO_FISH_ENABLED then return end

 local ok = pcall(function()
  NET:WaitForChild("RF/UpdateAutoFishingState"):InvokeServer(true)
 end)
 
 if ok then
 if NET_CACHE.AutoFish:InvokeServer(true) then
AUTO_FISH_ENABLED=true
print(">> Auto Fishing enabled")
end
end

local function W(t) task.wait(t) end
local function GM() local ok,v=pcall(function()return Repl:GetExpect("Coins")end) if ok and typeof(v)=="number" then return v end v=Repl:Get("Coins") return (typeof(v)=="number" and v) or 0 end
local function GO() local out={} for _,it in pairs(Repl:GetExpect({"Inventory","Fishing Rods"}) or {}) do out[it.Id]=it.UUID end return out end
local function CUR_DELAYS() local eq=Repl:GetExpect("EquippedItems") or {} local uuid=eq[1] if type(uuid)~="string" or uuid=="" then return DEF_THROW,DEF_PULL end local c=T[uuid] if c then return c[1],c[2] end return DEF_THROW,DEF_PULL end
local function TP(i) local h=C:WaitForChild("HumanoidRootPart") local from=h.Position local to=Vector3.new(LOCS[i][1],LOCS[i][2],LOCS[i][3]) for k=1,6 do h.CFrame=CFrame.new(from:Lerp(to,k/6)) task.wait(0.03) end task.wait(0.25) end
local function BUY(rid) if GM()<rid[2] then return false end local ok,err=pcall(function() NET:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(rid[1]) end) return ok end
local function EQU(uuid) local ok=pcall(function() NET:WaitForChild("RE/EquipItem"):FireServer(uuid,"Fishing Rods") end) if ok then task.wait(0.18) pcall(function() NET:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1) end) task.wait(0.12) return true end return false end
local function SELL() pcall(function() NET:WaitForChild("RF/SellAllItems"):InvokeServer() end) FC=0 end
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

-- bait functions
-- bait functions (optimized)
local function GET_OWNED_BAITS()
local inv=Repl:GetExpect({"Inventory","Baits"}) or {}
local owned={}
@@ -124,8 +153,7 @@ end

local function BUY_BAIT(bait)
if GM()<bait[2] then return false end
 local ok=pcall(function() NET:WaitForChild("RF/PurchaseBait"):InvokeServer(bait[1]) end)
 if ok then
 if NET_CACHE.PurchaseBait:InvokeServer(bait[1]) then
print(">> Bought:",bait[3])
task.wait(0.5)
return true
@@ -134,13 +162,10 @@ local function BUY_BAIT(bait)
end

local function EQUIP_BAIT(baitId)
 local ok=pcall(function() NET:WaitForChild("RE/EquipBait"):FireServer(baitId) end)
 if ok then
  BAIT_EQUIPPED[baitId]=true
  task.wait(0.3)
  return true
 end
 return false
 NET_CACHE.EquipBait:FireServer(baitId)
 BAIT_EQUIPPED[baitId]=true
 task.wait(0.3)
 return true
end

local function CHECK_BEST_BAIT()
@@ -157,75 +182,44 @@ local function CHECK_BEST_BAIT()
return false
end

-- check secret quest (cached lookup)
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
 local ds=Repl:Get({"DeepSea","Available"}) or Repl:Get("DeepSea")
 return ds and ds.Forever and ds.Forever.Quests and ds.Forever.Quests[3] and (ds.Forever.Quests[3].Progress or 0)>=1
end

-- FORWARD DECLARATION
local FISH

-- FISH function (hybrid mode with rapid click)
-- FISH function (optimized - cached calls)
FISH = function()
CHECK_BEST_BAIT()

if USE_GAME_AUTO_FISH then
  -- Let game auto fish, but add rapid click for minigame
if ENABLE_RAPID_CLICK then
   -- Wait untuk minigame muncul
task.wait(CLICK_DELAY_START)
   -- Spam click untuk speed up minigame
RAPID_CLICK()
   -- Wait sisa waktu
   task.wait(CLICK_DURATION + 0.3)
   task.wait(CLICK_DURATION+0.3)
else
task.wait(3.5)
end
  
  FC = FC + 1
  if FC >= 5 then SELL() end
  FC=FC+1
  if FC>=5 then SELL() end
return true
  
else
  -- Custom fishing logic (original)
  local ok,err=pcall(function()
   local th,pl=CUR_DELAYS()
   
   task.wait(0.08) 
   NET:WaitForChild("RF/ChargeFishingRod"):InvokeServer()
   task.wait(th + (math.random(-5,5)/1000))
   
   NET:WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(
     -1.23+math.random(-3,3)*0.01,
     0.14+math.random(-3,3)*0.01,
     tick()
   )
   
   -- Rapid click during minigame
   if ENABLE_RAPID_CLICK then
    RAPID_CLICK()
   end
   
   task.wait(pl + (math.random(-10,10)/1000))
   NET:WaitForChild("RE/FishingCompleted"):FireServer()
  end)
  
  if ok then 
   FC=FC+1 
   if FC>=5 then SELL() end 
   task.wait(0.35) 
   return true 
  end
  
  task.wait(1.2) 
  return false
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

@@ -258,32 +252,24 @@ end

local function FARM_ROD(idx)
local id=R[idx][1]
 local first_equip=true
 local first=true
while true do
   local owned=GO()
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
     if first_equip then
      ENABLE_AUTO_FISHING()
      first_equip=false
     end
     break 
   end
   if GM()>=R[idx][2] then 
     if BUY(R[idx]) then 
       task.wait(0.6) 
       owned=GO() 
       if owned[id] then 
         EQU(owned[id])
         if first_equip then
          ENABLE_AUTO_FISHING()
          first_equip=false
         end
         break 
       end 
     end 
    EQU(owned[id])
    if first then ENABLE_AUTO_FISHING() first=false end
    break
end
   FISH()
  end
  FISH()
end
end
