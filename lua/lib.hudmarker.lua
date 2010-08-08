
-- draws hud markers at obj.x/y/z with size obj.r
function stepHudMarker(obj)
	-- init
	if not obj.guiMarker then
		local marker = GetDesktopWidget():CreateContentChild("Image",
			{
				gfxparam_init = MakeSpritePanelParam_SingleSpriteSimple(
					GetPlainTextureGUIMat("hud_marker.png"), 256, 256)
			})
			
		obj.guiMarker = marker
	end
	
	-- update
	if obj.guiMarker then
		local bIsInFront,px,py,cx,cy = ProjectSizeAndPos(obj.x, obj.y, obj.z, obj.r)
		local marker = obj.guiMarker
		
		local w = (cx * gViewportW)
		local h = (cy * gViewportH)

		local minSize = 16
		local maxSize = 128
	
		w = max(minSize, min(w, maxSize))
		h = max(minSize, min(h, maxSize))

		local x = (gViewportW * ( px+1)/2) - (w / 2)
		local y = (gViewportH * (-py+1)/2) - (h / 2)
		
		marker:SetPos(x, y)
		marker:SetSize(w, h)
	end

end

function destroyHudMarker(obj)
	if obj.guiMarker then
		obj.guiMarker:Destroy()
		obj.guiMarker = nil
	end
end