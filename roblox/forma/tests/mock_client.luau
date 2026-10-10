local pending={}
local waitViews={}
local studio=true
local function signal()
 local callbacks={};return {Connect=function(self,fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;table.insert(callbacks,{c,fn});return c end,Fire=function(self,...)for _,pair in ipairs(callbacks)do if pair[1].Connected then pair[2](...)end end end}
end
local function vector(x,y,z)
 return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},{__sub=function(a,b)return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end,__add=function(a,b)return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end,__mul=function(a,b)return vector(a.X*b,a.Y*b,a.Z*b)end,__div=function(a,b)return vector(a.X/b,a.Y/b,a.Z/b)end,__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end;if k=="Unit"then local m=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z);return vector(a.X/m,a.Y/m,a.Z/m)end end})
end
local ColorSequence={new=function(v)return v end};local NumberSequence={new=function(v)return v end}
local RaycastParams={new=function()return {}end}
local CFrame={new=function(v)return {Position=v}end}
local Vector2={new=vector};local Vector3={new=vector,zero=vector(0,0,0),yAxis=vector(0,1,0)}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={new=function(xs,xo,ys,yo)return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)}end}
UDim2.fromOffset=function(x,y)return UDim2.new(0,x,0,y)end;UDim2.fromScale=function(x,y)return UDim2.new(x,0,y,0)end
local Color3={fromRGB=function(r,g,b)return {R=r,G=g,B=b}end,fromHSV=function(h,s,v)return {H=h,S=s,V=v}end}
local Enum=setmetatable({},{__index=function(t,k)local v=setmetatable({},{__index=function(s,n)rawset(s,n,k.."."..n);return k.."."..n end});rawset(t,k,v);return v end})
Enum.RenderPriority={Camera={Value=200}}
local Instance={};local objects={}
local methods={}
function methods:FindFirstChild(name)for _,o in ipairs(objects)do if o.Parent==self and o.Name==name and not o.destroyed then return o end end end
function methods:WaitForChild(name)return assert(self:FindFirstChild(name),"missing child "..name)end
function methods:FindFirstChildOfClass(kind)for _,o in ipairs(objects)do if o.Parent==self and o.ClassName==kind and not o.destroyed then return o end end end
function methods:GetChildren()local r={};for _,o in ipairs(objects)do if o.Parent==self and not o.destroyed then table.insert(r,o)end end;return r end
function methods:IsA(k)return self.ClassName==k or(k=="BasePart" and self.ClassName=="Part")end
function methods:GetPropertyChangedSignal(k)self.propertySignals=self.propertySignals or {};self.propertySignals[k]=self.propertySignals[k] or signal();return self.propertySignals[k]end
function methods:Destroy()if self.destroyed then return end;self.destroyed=true;self.Destroying:Fire();for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil end
function methods:GetFullName()return self.Name end
function methods:CaptureFocus()self.focused=true end
function Instance.new(kind)
 local o=setmetatable({ClassName=kind,Name=kind,BackgroundTransparency=0,Text="",AbsolutePosition=vector(),AbsoluteSize=vector(100,30),Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(0,0),AnchorPoint=vector(),Visible=true,Activated=signal(),MouseEnter=signal(),MouseLeave=signal(),Focused=signal(),FocusLost=signal(),InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),Destroying=signal()}, {__index=function(o,k)if k=="NavLabel"then return methods.FindFirstChild(o,k)end;return methods[k]end})
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
function services.RunService:BindToRenderStep(name,priority,fn)assert(priority==201,"Aim runs after default camera");self.bound=self.RenderStepped:Connect(fn)end
function services.RunService:UnbindFromRenderStep(name)if self.bound then self.bound:Disconnect();self.bound=nil end end
services.TweenService={Create=function(self,obj,info,props)return {Play=function()for k,v in pairs(props)do obj[k]=v end end}end}
services.UserInputService={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),GetFocusedTextBox=function()return nil end,IsMouseButtonPressed=function()return false end,IsKeyDown=function()return false end}
services.ReplicatedStorage=Instance.new("ReplicatedStorage")
services.CollectionService={GetTagged=function()return {}end}
local game={GetService=function(self,k)return assert(services[k],k)end}
local workspace={CurrentCamera={ViewportSize=vector(1440,900)},FindFirstChild=function()return nil end,Raycast=function()return nil end}
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
assert(api.GetState().targetMode=="Players","Aim defaults to players")
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
for _,name in ipairs({"Player","Aim","Teleport","Players","ESP","Settings"})do
 local nav=find("Nav"..name);assert(nav.Text=="" and nav:FindFirstChild("NavLabel"),"Navigation uses a separate caption")
 assert(not nav:FindFirstChildOfClass("UIPadding"),"Padding must not shift navigation icons")
end
assert(find("GetMouseHit"):IsA("BindableFunction"),"Own-weapon mouse adapter")
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
local enemy={Name="Enemy",DisplayName="Enemy",UserId=2}
local model=Instance.new("Model");model.Name="Enemy";enemy.Character=model
local enemyHum=Instance.new("Humanoid");enemyHum.Health=100;enemyHum.Parent=model
local enemyRoot=Instance.new("Part");enemyRoot.Name="HumanoidRootPart";enemyRoot.Position=vector(0,0,25);enemyRoot.Size=vector(2,2,1);enemyRoot.Parent=model
local enemyHead=Instance.new("Part");enemyHead.Name="Head";enemyHead.Position=vector(0,2,25);enemyHead.Size=vector(2,1,1);enemyHead.Parent=model
services.Players.GetPlayers=function()return {p,enemy}end
workspace.CurrentCamera.CFrame={Position=vector(0,0,0)}
workspace.CurrentCamera.WorldToViewportPoint=function(self,pos)return vector(9999,9999,25),false end
local function activateToggle(text)
 local parent=byText(text).Parent
 local caption=byText(text)
 for _,o in ipairs(parent:GetChildren())do if o.ClassName=="TextButton" and o.Size.X.Offset==34 and o.Position.Y.Offset==caption.Position.Y.Offset+3 then o.Activated:Fire();return end end
 error("missing toggle "..text)
end
activateToggle("Enable silent aim")
assert(api.GetAimTarget()==enemyRoot,"Silent targeting works even when target is outside camera view")
activateToggle("Enable ESP")
byText("Solid").Activated:Fire();byText("Void").Activated:Fire()
services.RunService.RenderStepped:Fire(0.1)
local highlight=find("FormaHighlight")
assert(highlight.FillColor.R==0 and highlight.FillColor.G==0 and highlight.FillColor.B==0 and highlight.FillTransparency==0,"Void covers character in black")
assert(find("FormaVoidLightning").ClassName=="Beam","Void creates lightning beams")
studio=true;activateToggle("Enable enlarged hitboxes");drain();services.RunService.RenderStepped:Fire(0.1)
assert(find("FormaHitboxPreview").Size.X==4,"Head box preview scales without resizing real part")
assert(enemyHead.Size.X==2,"Actual head size remains unchanged")
api.Destroy();drain()
for _,o in ipairs(objects)do if o.Name=="FormaVoidLightning" or o.Name=="FormaVoidNode" or o.Name=="FormaHitboxPreview"then assert(o.destroyed,"Effects and hitbox previews cleaned on close")end end
print("PASS: key/loading/main, six pages, navigation icon layout, offscreen silent target, black void/lightning, hitbox preview, cleanup, command isolation")
