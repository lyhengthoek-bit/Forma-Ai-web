local function signal()return {Connect=function(self,fn)return {Disconnect=function()end}end}end
local objects={};local methods={}
function methods:GetAttribute(k)return (self.attrs or {})[k]end
function methods:SetAttribute(k,v)self.attrs=self.attrs or {};self.attrs[k]=v end
function methods:FindFirstChild(n)for _,o in ipairs(objects)do if o.Parent==self and o.Name==n then return o end end end
function methods:FindFirstChildOfClass(k)for _,o in ipairs(objects)do if o.Parent==self and o.ClassName==k then return o end end end
function methods:GetChildren()local r={};for _,o in ipairs(objects)do if o.Parent==self then table.insert(r,o)end end;return r end
function methods:FindFirstAncestorOfClass(k)local obj=self.Parent;while obj do if obj.ClassName==k then return obj end;obj=obj.Parent end end
function methods:IsA(k)return self.ClassName==k or (k=="BasePart" and self.ClassName=="Part")end
function methods:Destroy()self.Parent=nil end
function methods:PivotTo(cf)self.lastPivot=cf end
local Instance={new=function(k)local o=setmetatable({ClassName=k,Name=k,Destroying=signal()}, {__index=methods});table.insert(objects,o);return o end}
local Enum={CreatorType={User="User"}}
local clock=0;local os={clock=function()return clock end}
local function vector(x,y,z)
 return setmetatable({X=x,Y=y,Z=z,_v3=true},{__add=function(a,b)return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end,__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end,__mul=function(a,n)return vector(a.X*n,a.Y*n,a.Z*n)end,__div=function(a,n)return vector(a.X/n,a.Y/n,a.Z/n)end,__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end;if k=="Unit"then return a/a.Magnitude end end})
end
local Vector3={new=vector};Vector3.zero=vector(0,0,0)
local function typeof(v)if type(v)=="table" and v._v3 then return "Vector3" elseif type(v)=="table" and v.ClassName then return "Instance"end;return type(v)end
local CFrame={new=function(x,y,z)return {X=x,Y=y,Z=z}end,lookAt=function(a,b)return {origin=a,target=b}end}
local RaycastParams={new=function()return {}end}
Enum.RaycastFilterType={Exclude="Exclude"};Enum.Material={Neon="Neon"}
local Color3={fromRGB=function(...)return {...}end}
local replicated=Instance.new("ReplicatedStorage")
local script=Instance.new("Script");script:SetAttribute("AccessKey","private-test-key")
local admin=Instance.new("Player");admin.UserId=1;admin.CharacterAdded=signal()
local guest=Instance.new("Player");guest.UserId=2;guest.CharacterAdded=signal()
local function makeCharacter(p)
 local c=Instance.new("Model");p.Character=c
 local h=Instance.new("Humanoid");h.Parent=c;h.WalkSpeed=22;h.JumpPower=45;h.UseJumpPower=false;h.Health=100
 local r=Instance.new("Part");r.Name="HumanoidRootPart";r.Parent=c
 return h,r
end
local hum,hrp=makeCharacter(admin);local otherHum=makeCharacter(guest)
hrp.Position=vector(0,0,0)
local head=Instance.new("Part");head.Name="Head";head.Parent=guest.Character;head.Position=vector(0,1.5,10);head.Size=vector(2,2,2)
head.CFrame={PointToObjectSpace=function(self,v)return v-head.Position end,VectorToObjectSpace=function(self,v)return v end}
function otherHum:TakeDamage(n)self.Health-=n end
local studio=false
local services={Players={GetPlayers=function()return {admin,guest}end,PlayerRemoving=signal(),PlayerAdded=signal()},ReplicatedStorage=replicated,RunService={IsStudio=function()return studio end},CollectionService={GetTagged=function()return {}end},Debris={AddItem=function(self,obj,t)obj:Destroy()end}}
local game={CreatorType="User",CreatorId=1,GetService=function(self,n)return assert(services[n])end}
local workspace={FindFirstChild=function()return nil end,FindFirstChildWhichIsA=function()return nil end,Raycast=function()return nil end}
local function runServer()
-- SERVER_SOURCE
return rayBox
end
local rayBox=runServer()
local remote=replicated:FindFirstChild("FormaAdmin"):FindFirstChild("Request")
local function call(p,action,data)clock+=1;return remote.OnServerInvoke(p,action,data)end
assert(not call(guest,"verify",{key="private-test-key"}).ok,"Non-admin cannot verify even with key")
assert(not call(admin,"movement",{speed=100,jump=100}).ok,"Commands require verified session")
assert(not call(admin,"verify",{key="bad"}).ok,"Bad key rejected")
assert(call(admin,"verify",{key="private-test-key"}).ok,"Admin with key verified")
assert(not call(admin,"movement",{speed=0/0,jump=50}).ok,"NaN rejected")
assert(not call(admin,"movement",{speed=math.huge,jump=50}).ok,"Infinity rejected")
assert(not call(admin,"movement",{speed=201,jump=50}).ok,"Out-of-range movement rejected")
assert(call(admin,"movement",{speed=80,jump=75}).ok and hum.WalkSpeed==80 and hum.JumpPower==75,"Bounded movement applies")
assert(not call(admin,"teleport",{x=100001,y=0,z=0}).ok,"Out-of-range teleport rejected")
assert(call(admin,"teleport",{x=100,y=10,z=-50}).ok and admin.Character.lastPivot.X==100,"Coordinates applied")
assert(call(admin,"flight",{enabled=true}).ok and admin:GetAttribute("FormaFlightAllowed"),"Flight grant")
assert(call(admin,"reset",{}).ok and hum.WalkSpeed==22 and hum.JumpPower==45 and hum.UseJumpPower==false and not admin:GetAttribute("FormaFlightAllowed"),"Reset restores original game movement")
assert(not call(admin,"hitbox",{enabled=true,headScale=9,torsoScale=2}).ok,"Oversized hitboxes rejected")
assert(call(admin,"hitbox",{enabled=true,headScale=2,torsoScale=2}).ok,"Bounded hitboxes accepted")
local missOrigin=vector(1.5,1.5,0);local dir=vector(0,0,1)
assert(rayBox(missOrigin,dir,head,head.Size,1000)==nil,"Normal head ray misses outside original box")
assert(rayBox(missOrigin,dir,head,head.Size*2,1000)~=nil,"Expanded head box catches near-miss")
assert(rayBox(vector(0,1.5,20),dir,head,head.Size*2,1000)==nil,"Box behind ray rejected")
local shot=call(admin,"shot",{target=head,aimPosition=vector(0,999,0)})
assert(shot.ok and shot.hit==guest.Character.Name and otherHum.Health==90,"Own test weapon redirects sky aim to validated target")
local wall=Instance.new("Part")
workspace.Raycast=function()return {Distance=5,Instance=wall}end
local blocked=call(admin,"shot",{target=head,aimPosition=vector(0,999,0)})
assert(blocked.ok and not blocked.hit and otherHum.Health==90,"Server line-of-sight prevents shots through walls")
workspace.Raycast=function()return nil end
local unrelated=Instance.new("Part");assert(not call(admin,"shot",{target=unrelated,aimPosition=vector(0,999,0)}).ok,"Unrecognized target rejected")
assert(not call(guest,"shot",{target=head,aimPosition=vector(0,999,0)}).ok,"Non-admin cannot shoot test weapon")
call(admin,"reset",{})
local throttled=remote.OnServerInvoke(admin,"reset",{});assert(not throttled.ok,"Request rate limit")
studio=true;assert(call(guest,"verify",{key="FORMA-TEST"}).ok,"Studio preview explicitly allowed")
studio=false;assert(not call(guest,"movement",{speed=100,jump=100}).ok,"Admin authorization rechecked on every command")
print("PASS: admin/session gates, finite bounds, movement/reset, Studio preview, enlarged ray boxes, sky-aim shot redirect, wall occlusion, target validation")
