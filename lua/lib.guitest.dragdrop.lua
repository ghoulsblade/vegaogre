
function InitGuiThemes ()
	gVegaWidgetFont = CreateFont_Ogre("TrebuchetMSBold",14)
	
	local bordermatrix_32_widemid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
	local bordermatrix_32_tinymid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 14,4,14, 14,4,14, 32,32, 1,1, false,false)
	local bordermatrix_16			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	
	GuiThemeSetDefaultParam("Window",{	gfxparam_init 		= bordermatrix_32_tinymid, })
	
	
	
	local matrix_button_small	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("button_small.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 32,32, 1,1, false,false)
	GuiThemeSetDefaultParam("Text",{	font=gVegaWidgetFont,fontsize=14, textparam={r=0,g=0,b=0} })
	GuiThemeSetDefaultParam("Button",{	gfxparam_init 		= matrix_button_small,
										gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
										gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
										gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										margin_left= 3,
										margin_top= 3,
										margin_right= 3,
										margin_bottom= 1,
										font=gVegaWidgetFont,
										textcol={r=0,g=0,b=0},
									})
end

function GuiTest_DragDrop ()
	InitGuiThemes()
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Window x=100 y=100 w=300 h=200> <Button x=10 y=10 label='testbutton' /> </Window>")	
	--~ GetDesktopWidget():CreateContentChild("Button",{x=10, y=10, label='testbutton'})
	
	local w1 = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=100 y=100 w=320 h=300> <Text x=10 y=0 text='Inventory' /> </Window>]])
	local w2 = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=600 y=100 w=320 h=300> <Text x=10 y=0 text='Ship' /> </Window>]])
	
	for k,v in ipairs({
		"am_magcells.image.png",
		"atmospheric_scrubbers.image.png",
		"automated_factories.image.png",
		"baakgah.image.png",
		"biogenerators.image.png",
		"bio_remodeler.image.png",
		"cargo-hud.image.png",
		"cloaking_device_aeramilspec.image.png",
		"explosives.image.png",
		"krystal.image.png",
		"laser_drills.image.png",
		"pai_wetware.image.png",
		"repair_droid01.image.png",
		"repulsor_beam.image.png",
		"tractor_beam.image.png",
		"waste_recyclers.image.png",}) do 
		local i = k-1
		local tooltip = string.gsub(v,"%.png$","").."\n5 SomeValue\n7 SomeOtherValue\nMedPowerSlot"
		w1:CreateContentChild("ItemIcon",{x=5+(i%6)*50, y=40+math.floor(i/6)*50, image=v, tooltip=tooltip })
	end
	
	for i=0,8 do 
		w2:CreateContentChild("EquipSlot",{x=5+(i%6)*50, y=40+math.floor(i/6)*50, col={} })
	end
	
	
	
end
