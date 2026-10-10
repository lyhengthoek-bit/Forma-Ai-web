local pending={}
local waitViews={}
local studio=true
local function signal()
 local callbacks={};return {Connect=function(self,fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;table.insert(callbacks,{c,fn});return c end,Fire=function(self,...)for _,pair in ipairs(callbacks)do if pair[1].Connected then pair[2](...)end end end}
end
local function vector(x,y,z)
 return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},{__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end,__add=function(a,b)return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end,__mul=function(a,b)return vector(a.X*b,a.Y*b,a.Z*b)end,__div=function(a,b)return vector(a.X/b,a.Y/b,a.Z/b)end,__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end;if k=="Unit"then local m=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z);return vector(a.X/m,a.Y/m,a.Z/m)end end})
end
local Vector2={new=vector};local Vector3={new=vector,zero=vector(0,0,0),yAxis=vector(0,1,0)}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={new=function(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end}
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end;UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
local Color3={fromRGB=function(r,g,b)return {R=r,G=g,B=b}end,fromHSV=function(h,s,v)return {H=h,S=s,V=v}end}
local Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(s,n)rawset(s,n,k.."."..n);return k.."."..n end});rawset(t,k,v);return v end})
local Instance={};local objects={}
local methods={}
function methods:FindFirstChild(name)for _,o in ipairs(objects)do if o.Parent==self and o.Name==name and not o.destroyed then return o end end end
function methods:WaitForChild(name)return assert(self:FindFirstChild(name),"missing child "..name)end
function methods:FindFirstChildOfClass(kind)for _,o in ipairs(objects)do if o.Parent==self and o.ClassName==kind and not o.destroyed then return o end end end
function methods:GetChildren()local r={};for _,o in ipairs(objects)do if o.Parent==self and not o.destroyed then table.insert(r,o)end end;return r end
function methods:IsA(k)return self.ClassName==k end
function methods:GetPropertyChangedSignal(k)self.propertySignals=self.propertySignals or {};self.propertySignals[k]=self.propertySignals[k] or signal();return self.propertySignals[k]end
function methods:Destroy()if self.destroyed then return end;self.destroyed=true;self.Destroying:Fire();for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil end
function methods:GetFullName()return self.Name end
function methods:CaptureFocus()self.focused=true end
function Instance.new(kind)
 local o=setmetatable({ClassName=kind,Name=kind,BackgroundTransparency=0,Text="",AbsolutePosition=vector(),AbsoluteSize=vector(100,30),Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(0,0),AnchorPoint=vector(),Visible=true,Activated=signal(),MouseEnter=signal(),MouseLeave=signal(),Focused=signal(),FocusLost=signal(),InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),Destroying=signal()}, {__index=methods})
 table.insert(objects,o);return o
end
local pgui=Instance.new("PlayerGui");pgui.Name="PlayerGui"
local p={Name="Tester",DisplayName="Tester",UserId=1,CharacterAdded=signal()}
function p:WaitForChild(n)return n=="PlayerGui"and pgui or nil end
local char=Instance.new("Model");char.Name="Tester";p.Character=char
local hum=Instance.new("Humanoid");hum.Parent=char;hum.WalkSpeed=16;hum.JumpPower=50;hum.UseJumpPower=true;hum.Health=100
local hrp=Instance.new("Part");hrp.Name="HumanoidRootPart";hrp.Position=vector();hrp.Parent=char
local services={}
services.Players={LocalPlayer=p,PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function()return {p}end}
services.RunService={IsStudio=function()return studio end,RenderStepped=signal()}
services.TweenService={Create=function(self,obj,info,props)return {Play=function()for k,v in pairs(props)do obj[k]=v end end}end}
services.UserInputService={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),GetFocusedTextBox=function()return nil end,IsMouseButtonPressed=function()return false end,IsKeyDown=function()return false end}
services.ReplicatedStorage=Instance.new("ReplicatedStorage")
services.CollectionService={GetTagged=function()return {}end}
local game={GetService=function(self,k)return assert(services[k],k)end}
local workspace={CurrentCamera={ViewportSize=vector(1440,900)},FindFirstChild=function()return nil end}
local TweenInfo={new=function(...)return {...}end}
local task={spawn=function(fn)table.insert(pending,fn)end,defer=function(fn)table.insert(pending,fn)end,wait=function()
 local view={}
 for _,o in ipairs(objects)do if not o.destroyed and (o.Name=="Access" or o.Name=="Loading" or o.Name=="Workspace")then view[o.Name]=o.Visible end end
 table.insert(waitViews,view)
end}
local function drain()while #pending>0 do table.remove(pending,1)()end end
local function find(name)for _,o in ipairs(objects)do if o.Name==name and not o.destroyed then return o end end;error("not found: "..name)end
local function byText(text,parent)for _,o in ipairs(objects)do if o.Text==text and (not parent or o.Parent==parent) and not o.destroyed then return o end end;error("missing text "..text)end
local function runClient()
-- CLIENT_SOURCE
end
local api=runClient()
assert(find("Access").Visible and not find("Workspace").Visible,"Initial key screen")
local key=find("KeyInput");key.Text="wrong";find("Continue").Activated:Fire();drain()
assert(find("Access").Visible and not find("Workspace").Visible,"Invalid key must not unlock")
key.Text="  FORMA-TEST  ";find("Continue").Activated:Fire();drain()
assert(not find("Access").Visible and find("Workspace").Visible and not find("Loading").Visible,"Valid key unlocks after loading")
assert(#waitViews==2,"Two loading stages")
for _,view in ipairs(waitViews)do assert(view.Loading and not view.Access and not view.Workspace,"Loading visible before main panel")end
for _,name in ipairs({"Player","Aim","Teleport","Players","ESP","Settings"})do
 find("Nav"..name).Activated:Fire();assert(find(name).Visible,"Page opens: "..name)
end
services.UserInputService.InputBegan:Fire({KeyCode=Enum.KeyCode.RightControl},false)
assert(not find("Workspace").Visible and find("Reopen").Visible,"Hotkey minimizes")
find("Reopen").Activated:Fire();assert(find("Workspace").Visible,"Reopen restores")
local aim=find("Aim");local aimbot
for _,o in ipairs(objects)do if o.ClassName=="TextLabel" and o.Text=="Enable aim assist" then aimbot=o.Parent end end
local toggle
for _,o in ipairs(aimbot:GetChildren())do if o.ClassName=="TextButton" and o.Size.X.Offset==34 then toggle=o end end
assert(toggle,"aim toggle");toggle.Activated:Fire();assert(api.GetState().aim,"Aim toggle stores value")
assert(api.GetAimTarget()==nil,"No target without dummy")
api.Destroy();assert(find==find and not pgui:FindFirstChild("Forma"),"Destroy removes GUI")
for _,o in ipairs(objects)do assert(o.Name~="FormaFlight"or o.destroyed,"Flight cleaned")end
drain()
studio=false;table.clear(waitViews)
api=runClient()
key=find("KeyInput");key.Text="bad";find("Continue").Activated:Fire();drain()
assert(find("Access").Visible and not find("Workspace").Visible,"Standalone invalid key stays locked")
key.Text="FORMA-TEST";find("Continue").Activated:Fire();drain()
assert(find("Workspace").Visible and not find("Access").Visible and not find("Loading").Visible,"Standalone demo key opens main")
assert(#waitViews==2,"Standalone loading has two stages")
for _,view in ipairs(waitViews)do assert(view.Loading and not view.Workspace,"Standalone shows loading before main")end
local movementCard=byText("Walk speed").Parent
local field
for _,o in ipairs(movementCard:GetChildren())do if o.ClassName=="TextBox" and o.Position.Y.Offset==50 then field=o end end
assert(field,"walk-speed field")
local original=hum.WalkSpeed;field.Text="120";field.FocusLost:Fire(false);drain()
assert(hum.WalkSpeed==original and api.GetState().speed==original,"Frontend preview does not grant published-game admin commands")
api.Destroy();drain()
print("PASS: Studio and standalone key -> loading -> main, invalid keys, six pages, minimize/reopen, aim state, cleanup, published-game command isolation")
