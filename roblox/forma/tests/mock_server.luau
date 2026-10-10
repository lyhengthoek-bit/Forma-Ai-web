local function signal()return {Connect=function(self,fn)return {Disconnect=function()end}end}end
local objects={};local methods={}
function methods:GetAttribute(k)return (self.attrs or {})[k]end
function methods:SetAttribute(k,v)self.attrs=self.attrs or {};self.attrs[k]=v end
function methods:FindFirstChild(n)for _,o in ipairs(objects)do if o.Parent==self and o.Name==n then return o end end end
function methods:FindFirstChildOfClass(k)for _,o in ipairs(objects)do if o.Parent==self and o.ClassName==k then return o end end end
function methods:GetChildren()local r={};for _,o in ipairs(objects)do if o.Parent==self then table.insert(r,o)end end;return r end
function methods:IsA(k)return self.ClassName==k end
function methods:Destroy()self.Parent=nil end
function methods:PivotTo(cf)self.lastPivot=cf end
local Instance={new=function(k)local o=setmetatable({ClassName=k,Name=k,Destroying=signal()}, {__index=methods});table.insert(objects,o);return o end}
local Enum={CreatorType={User="User"}}
local clock=0;local os={clock=function()return clock end}
local Vector3={new=function(x,y,z)return {X=x,Y=y,Z=z}end};Vector3.zero=Vector3.new(0,0,0)
local CFrame={new=function(x,y,z)return {X=x,Y=y,Z=z}end}
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
local hum,hrp=makeCharacter(admin);makeCharacter(guest)
local studio=false
local services={Players={GetPlayers=function()return {admin,guest}end,PlayerRemoving=signal(),PlayerAdded=signal()},ReplicatedStorage=replicated,RunService={IsStudio=function()return studio end}}
local game={CreatorType="User",CreatorId=1,GetService=function(self,n)return assert(services[n])end}
local workspace={FindFirstChild=function()return nil end,FindFirstChildWhichIsA=function()return nil end}
local function runServer()
-- SERVER_SOURCE
end
runServer()
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
local throttled=remote.OnServerInvoke(admin,"reset",{});assert(not throttled.ok,"Request rate limit")
studio=true;assert(call(guest,"verify",{key="FORMA-TEST"}).ok,"Studio preview explicitly allowed")
studio=false;assert(not call(guest,"movement",{speed=100,jump=100}).ok,"Admin authorization rechecked on every command")
print("PASS: server admin checks, session gate, invalid key, NaN/infinity/range validation, teleport, flight grant, reset, throttling, Studio-only preview")
