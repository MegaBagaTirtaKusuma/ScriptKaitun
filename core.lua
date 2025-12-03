--========================================================--
-- ULTRA LIGHTWEIGHT AUTO FARM FISHING
--========================================================--

local P=game:GetService("Players").LocalPlayer
local C=P.Character or P.CharacterAdded:Wait()
local R=game:GetService("ReplicatedStorage")
local N=R.Packages._Index["sleitnick_net@0.2.0"].net
local D=require(R.Packages.Replion).Client:WaitReplion("Data")

-- Anti AFK
P.Idled:Connect(function()game:GetService("VirtualUser"):Button2Down(Vector2.zero,workspace.CurrentCamera.CFrame)end)

-- Rod Data: {name,price,id,uuid,throw,pull}
local RD={
{"Luck Rod",325,79,"4315aa13-5964-4e5d-bda1-84ba5b193695",.05,2.3},
{"Lucky Rod",15e3,4,"1aaba2cd-9ed5-42f0-87fd-380d7acdc600",.05,1.9},
{"Midnight Rod",5e4,80,"0c860299-a465-45ad-bcf4-46ae245a8bcd",.05,1.4},
{"Steampunk Rod",215e3,6,"56fceb1c-b6ba-4f76-8523-31e87aa40c59",.05,1.3},
{"Astral Rod",1e6,5,"28b54c20-7a83-413a-afb5-2df2853dd991",.05,1}
}

-- Timing Lookup
local T={}for _,r in ipairs(RD)do T[r[4]]={r[5],r[6]}end

-- Locations: {x,y,z}
local L={{129,3.5,2751},{-534,19,163},{-3734,-135,-886},{-3597,-276,-1641}}

local FC=0

-- Utils
local function W(t)task.wait(t+math.random(-5,5)/1e3)end
local function GM()return(pcall(function()return D:GetExpect("Coins")end)and D:GetExpect("Coins"))or D:Get("Coins")or 0 end
local function GO()local o={}for _,r in pairs(D:GetExpect({"Inventory","Fishing Rods"})or{})do o[r.Id]=r.UUID end return o end
local function GD()local e=(D:GetExpect("EquippedItems")or{})[1]if not e then return.05,2.8 end local t=T[e]return t and t[1]or.05,t and t[2]or 2.8 end

-- Teleport
local function TP(x,y,z)
local h=C:WaitForChild("HumanoidRootPart")
local f,t=h.Position,Vector3.new(x,y,z)
for i=1,8 do h.CFrame=CFrame.new(f:Lerp(t,i/8))task.wait(.04)end
W(.3)
end

-- Buy
local function B(r)
if GM()<r[2]then return end
return pcall(function()N:WaitForChild("RF/PurchaseFishingRod"):InvokeServer(r[3])end)
end

-- Equip
local function E(u)
if pcall(function()N:WaitForChild("RE/EquipItem"):FireServer(u,"Fishing Rods")end)then
W(.2)
pcall(function()N:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)end)
W(.1)
return true
end
end

-- Sell
local function S()pcall(function()N:WaitForChild("RF/SellAllItems"):InvokeServer()end)FC=0 end

-- Fish
local function F()
local ok=pcall(function()
local th,pl=GD()
W(.1)
N:WaitForChild("RF/ChargeFishingRod"):InvokeServer()
W(th)
N:WaitForChild("RF/RequestFishingMinigameStarted"):InvokeServer(-1.23+math.random(-3,3)*.01,.14+math.random(-3,3)*.01,tick())
W(pl)
N:WaitForChild("RE/FishingCompleted"):FireServer()
end)
if ok then FC=FC+1 if FC>=5 then S()end W(.4)else W(1.5)end
return ok
end

-- Buy Next
local function BN()
local o,m=GO(),GM()
for i,r in ipairs(RD)do
if not o[r[3]]and m>=r[2]then
if B(r)then
W(.7)
o=GO()
if o[r[3]]then E(o[r[3]])return true end
end
end
end
end

-- Get DeepSea
local function GDS()
local ds=D:Get({"DeepSea","Available"})
if ds and ds.Forever and ds.Forever.Quests then return ds.Forever.Quests end
ds=D:Get("DeepSea")
return ds and ds.Forever and ds.Forever.Quests
end

-- Check DeepSea
local function CDS(i,t)local q=GDS()return q and q[i]and(q[i].Progress or 0)>=t end

-- Farm Rod
local function FR(i)
while true do
local o=GO()
if o[RD[i][3]]then E(o[RD[i][3]])break end
if GM()>=RD[i][2]and BN()then break end
F()
W(.2)
end
end

-- Farm Location
local function FL(li,rs)
local l=L[li]
TP(l[1],l[2],l[3])
for _,ri in ipairs(rs)do FR(ri)end
end

-- Farm Sisyphus
local function FS()TP(L[3][1],L[3][2],L[3][3])while not CDS(3,1)do F()W(.2)end end

-- Farm Treasure
local function FT()TP(L[4][1],L[4][2],L[4][3])while not CDS(1,300)do F()W(.2)end end

--========================================================--
-- MAIN
--========================================================--

pcall(function()N:WaitForChild("RE/EquipToolFromHotbar"):FireServer(1)end)
W(.8)

FL(1,{1})
FL(1,{2})
FL(2,{3,4,5})
FS()
FT()
