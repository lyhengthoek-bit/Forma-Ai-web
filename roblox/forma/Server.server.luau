-- Forma admin adapter. Keep this in ServerScriptService, never in PlayerGui.
-- In Studio, FORMA-TEST allows preview. Published games require an admin user ID
-- and a private AccessKey attribute on this server Script.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Debris=game:GetService("Debris")
local folder=ReplicatedStorage:FindFirstChild("FormaAdmin")
if folder then error("FormaAdmin already exists. Remove the older Forma server before installing another.")end
folder=Instance.new("Folder");folder.Name="FormaAdmin";folder.Parent=ReplicatedStorage
local remote=Instance.new("RemoteFunction");remote.Name="Request";remote.Parent=folder
local sessions,lastRequest,originals,hitboxSettings={},{},{},{}
local function result(ok,message,extra)
 local r=extra or {};r.ok=ok;r.message=message;return r
end
local function isAdmin(player)
 if RunService:IsStudio() then return true end
 if game.CreatorType==Enum.CreatorType.User and player.UserId==game.CreatorId then return true end
 for id in tostring(script:GetAttribute("AdminUserIds") or ""):gmatch("%d+")do if tonumber(id)==player.UserId then return true end end
 return false
end
local function finite(n,min,max)
 return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge and n>=min and n<=max
end
local function getPresets()
 local out={};local locations=workspace:FindFirstChild("FormaLocations")
 if locations then for _,obj in ipairs(locations:GetChildren())do if obj:IsA("BasePart") or obj:IsA("Model")then table.insert(out,obj.Name)end end end
 if workspace:FindFirstChildWhichIsA("SpawnLocation",true)then table.insert(out,"Spawn")end
 table.sort(out);return out
end
local function parts(player)
 local char=player.Character;if not char then return end
 return char,char:FindFirstChildOfClass("Humanoid"),char:FindFirstChild("HumanoidRootPart")
end
local function snapshot(player,hum)
 local old=originals[player]
 if not old or old.hum~=hum then old={hum=hum,speed=hum.WalkSpeed,jump=hum.JumpPower,useJumpPower=hum.UseJumpPower};originals[player]=old end
 return old
end
local function reset(player)
 local old=originals[player]
 if old and old.hum.Parent then old.hum.WalkSpeed=old.speed;old.hum.JumpPower=old.jump;old.hum.UseJumpPower=old.useJumpPower end
 originals[player]=nil;hitboxSettings[player]=nil;player:SetAttribute("FormaFlightAllowed",false)
end
-- Expanded boxes are calculated only for this admin test weapon.
-- No avatar parts are resized, and other weapons/collisions are unaffected.
local function rayBox(origin,direction,part,size,maxDistance)
 local o=part.CFrame:PointToObjectSpace(origin)
 local d=part.CFrame:VectorToObjectSpace(direction)
 local half=size/2;local near,far=0,maxDistance
 for _,axis in ipairs({"X","Y","Z"})do
  local ov,dv,h=o[axis],d[axis],half[axis]
  if math.abs(dv)<1e-7 then if ov < -h or ov > h then return nil end
  else
   local a,b=(-h-ov)/dv,(h-ov)/dv;if a>b then a,b=b,a end
   near=math.max(near,a);far=math.min(far,b)
   if near>far then return nil end
  end
 end
 return near
end
local function eligibleModels(shooter)
 local result,seen={},{}
 local function add(model,other)
  if not model or seen[model] or model==shooter.Character then return end
  local hum=model:FindFirstChildOfClass("Humanoid")
  if not hum or hum.Health<=0 then return end
  local friendly=other and other.Team~=nil and other.Team==shooter.Team
  if friendly and not script:GetAttribute("AllowFriendlyFire")then return end
  seen[model]=true;table.insert(result,model)
 end
 for _,other in ipairs(Players:GetPlayers())do if other~=shooter then add(other.Character,other)end end
 local dummies=workspace:FindFirstChild("TestDummies")
 if dummies then for _,model in ipairs(dummies:GetChildren())do if model:IsA("Model")then add(model)end end end
 for _,model in ipairs(CollectionService:GetTagged("FormaTarget"))do if model:IsA("Model")then add(model)end end
 return result
end
local function testShot(player,data,root)
 local origin=root.Position+Vector3.new(0,1.5,0)
 local models=eligibleModels(player);local allowed={};for _,model in ipairs(models)do allowed[model]=true end
 local aimPosition=data.aimPosition
 if data.target~=nil then
  if typeof(data.target)~="Instance" or not data.target:IsA("BasePart") or not allowed[data.target.Parent]then return result(false,"Target is not an eligible player or test dummy.")end
  aimPosition=data.target.Position
 end
 if typeof(aimPosition)~="Vector3" or not finite(aimPosition.X,-1e7,1e7) or not finite(aimPosition.Y,-1e7,1e7) or not finite(aimPosition.Z,-1e7,1e7)then return result(false,"Invalid shot direction.")end
 local delta=aimPosition-origin;if delta.Magnitude<0.01 then return result(false,"Invalid shot direction.")end
 local direction=delta.Unit;local range=1000
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character}
 local worldHit=workspace:Raycast(origin,direction*range,params)
 local obstacleDistance=worldHit and worldHit.Distance or range
 local cfg=hitboxSettings[player] or {enabled=false,headScale=1,torsoScale=1}
 local bestModel,bestDistance=nil,obstacleDistance
 for _,model in ipairs(models)do
  for _,name in ipairs({"Head","UpperTorso","LowerTorso","Torso"})do
   local part=model:FindFirstChild(name)
   if part and part:IsA("BasePart")then
    local multiplier=cfg.enabled and (name=="Head" and cfg.headScale or cfg.torsoScale) or 1
    local distance=rayBox(origin,direction,part,part.Size*multiplier,range)
    if distance and distance<=bestDistance+0.001 then bestModel=model;bestDistance=distance end
   end
  end
 end
 if not bestModel and worldHit then
  local model=worldHit.Instance:FindFirstAncestorOfClass("Model")
  if allowed[model]then bestModel=model;bestDistance=worldHit.Distance end
 end
 if bestModel then
  local hum=bestModel:FindFirstChildOfClass("Humanoid")
  local damage=script:GetAttribute("TestDamage");damage=type(damage)=="number" and math.clamp(damage,0,100) or 10
  hum:TakeDamage(damage)
 end
 local endPosition=origin+direction*bestDistance
 local tracer=Instance.new("Part");tracer.Name="FormaTestTracer";tracer.Anchored=true;tracer.CanCollide=false;tracer.CanTouch=false;tracer.CanQuery=false;tracer.Material=Enum.Material.Neon;tracer.Color=Color3.fromRGB(175,130,255);tracer.Size=Vector3.new(0.05,0.05,math.max(0.01,bestDistance));tracer.CFrame=CFrame.lookAt((origin+endPosition)/2,endPosition);tracer.Parent=workspace;Debris:AddItem(tracer,0.12)
 return result(true,bestModel and "Hit" or "Shot fired",{hit=bestModel and bestModel.Name or nil})
end
remote.OnServerInvoke=function(player,action,data)
 if type(action)~="string" or type(data)~="table"then return result(false,"Invalid request.")end
 local now=os.clock();local last=lastRequest[player]
 if last and now-last<0.08 then return result(false,"Please wait a moment.")end
 lastRequest[player]=now
 if not isAdmin(player)then sessions[player]=nil;return result(false,"This account is not an admin.")end
 if action=="verify"then
  local key=data.key
  if type(key)~="string" or #key>256 then return result(false,"Invalid access key.")end
  local studio=RunService:IsStudio();local configured=script:GetAttribute("AccessKey")
  local valid=(studio and key=="FORMA-TEST") or (type(configured)=="string" and #configured>=8 and key==configured)
  if not valid then sessions[player]=nil;return result(false,studio and "Use FORMA-TEST for Studio preview." or "Invalid access key.")end
  sessions[player]=true
  return result(true,"Verified",{presets=getPresets(),mode=studio and "test mode" or "admin session"})
 end
 if not sessions[player]then return result(false,"Verify your key first.")end
 local char,hum,root=parts(player)
 if action=="reset"then reset(player);return result(true,"Defaults restored")end
 if action=="hitbox"then
  if type(data.enabled)~="boolean" or not finite(data.headScale,1,4) or not finite(data.torsoScale,1,4)then return result(false,"Hitbox scales must be between 1 and 4.")end
  hitboxSettings[player]={enabled=data.enabled,headScale=data.headScale,torsoScale=data.torsoScale}
  return result(true,"Test hitboxes updated")
 end
 if action=="flight"then
  if type(data.enabled)~="boolean"then return result(false,"Invalid flight value.")end
  player:SetAttribute("FormaFlightAllowed",data.enabled)
  return result(true,"Flight updated")
 end
 if not char or not hum or not root or hum.Health<=0 then return result(false,"Character not ready.")end
 if action=="shot"then return testShot(player,data,root)end
 if action=="movement"then
  if not finite(data.speed,0,200) or not finite(data.jump,0,200)then return result(false,"Movement values must be between 0 and 200.")end
  snapshot(player,hum);hum.WalkSpeed=data.speed;hum.UseJumpPower=true;hum.JumpPower=data.jump
  return result(true,"Movement updated")
 elseif action=="teleport"then
  local destination
  if type(data.preset)=="string" and #data.preset<=128 then
   if data.preset=="Spawn"then local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation",true);destination=spawn and spawn.CFrame+Vector3.new(0,4,0)
   else
    local locations=workspace:FindFirstChild("FormaLocations");local obj=locations and locations:FindFirstChild(data.preset)
    if obj and obj:IsA("BasePart")then destination=obj.CFrame+Vector3.new(0,4,0)
    elseif obj and obj:IsA("Model")then destination=obj:GetPivot()+Vector3.new(0,4,0)end
   end
  elseif finite(data.playerId,1,1e16)then
   local other=Players:GetPlayerByUserId(data.playerId);local r=other and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
   if r then destination=r.CFrame+Vector3.new(3,0,0)end
  elseif finite(data.x,-100000,100000) and finite(data.y,-100000,100000) and finite(data.z,-100000,100000)then destination=CFrame.new(data.x,data.y,data.z)
  end
  if not destination then return result(false,"Destination unavailable.")end
  char:PivotTo(destination);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  return result(true,"Teleported")
 end
 return result(false,"Unknown action.")
end
Players.PlayerRemoving:Connect(function(player) sessions[player]=nil;lastRequest[player]=nil;originals[player]=nil;hitboxSettings[player]=nil end)
local characterConnections={}
local function watch(player)
 characterConnections[player]=player.CharacterAdded:Connect(function()originals[player]=nil;player:SetAttribute("FormaFlightAllowed",false)end)
end
for _,player in ipairs(Players:GetPlayers())do watch(player)end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(player)if characterConnections[player]then characterConnections[player]:Disconnect();characterConnections[player]=nil end end)
script.Destroying:Connect(function()for player in pairs(sessions)do reset(player)end;for _,c in pairs(characterConnections)do c:Disconnect()end;folder:Destroy()end)
