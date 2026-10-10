-- Optional adapter for your own client weapon. Does not modify other weapons.
-- Put this ModuleScript beside your weapon LocalScript and require it.
local Players=game:GetService("Players")
local WeaponAim={}
function WeaponAim.GetHit(mouse)
 local gui=Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("Forma")
 local getter=gui and gui:FindFirstChild("GetMouseHit")
 if getter then
  local ok,hit,target=pcall(function()return getter:Invoke(mouse.Hit)end)
  if ok then return hit,target end
 end
 return mouse.Hit,nil
end
function WeaponAim.GetDirection(origin,mouse)
 local hit,target=WeaponAim.GetHit(mouse)
 local offset=hit.Position-origin
 return offset.Magnitude>0 and offset.Unit or Vector3.zero,target
end
return WeaponAim
