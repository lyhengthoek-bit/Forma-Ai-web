-- Forma admin adapter. Keep this in ServerScriptService, never in PlayerGui.
-- In Studio, FORMA-TEST allows preview. Published games require an admin user ID
-- and a private AccessKey attribute on this server Script.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local folder=ReplicatedStorage:FindFirstChild("FormaAdmin")
if folder then error("FormaAdmin already exists. Remove the older Forma server before installing another.")end
folder=Instance.new("Folder");folder.Name="FormaAdmin";folder.Parent=ReplicatedStorage
local remote=Instance.new("RemoteFunction");remote.Name="Request";remote.Parent=folder
local sessions,lastRequest,originals={},{},{}
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
 originals[player]=nil;player:SetAttribute("FormaFlightAllowed",false)
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
 if action=="flight"then
  if type(data.enabled)~="boolean"then return result(false,"Invalid flight value.")end
  player:SetAttribute("FormaFlightAllowed",data.enabled)
  return result(true,"Flight updated")
 end
 if not char or not hum or not root or hum.Health<=0 then return result(false,"Character not ready.")end
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
Players.PlayerRemoving:Connect(function(player) sessions[player]=nil;lastRequest[player]=nil;originals[player]=nil end)
local characterConnections={}
local function watch(player)
 characterConnections[player]=player.CharacterAdded:Connect(function()originals[player]=nil;player:SetAttribute("FormaFlightAllowed",false)end)
end
for _,player in ipairs(Players:GetPlayers())do watch(player)end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(player)if characterConnections[player]then characterConnections[player]:Disconnect();characterConnections[player]=nil end end)
script.Destroying:Connect(function()for player in pairs(sessions)do reset(player)end;for _,c in pairs(characterConnections)do c:Disconnect()end;folder:Destroy()end)
