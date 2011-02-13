
-- handles trade stuff, uses units.csv:Cargo_Import and master_part_list.csv

gPlayerCargo = {}
gPlayerCredits = 10*1000

-- lists all tradegoods from master_part_list.csv for the t.Cargo_Import of input param t (planet/station type)
function GetTradeInfosForBaseType (t)
	assert(t)
	local tradeinfos = {}
	for entry in string.gmatch(t.Cargo_Import or "","{([^}]*)}") do
		local cat,mult_price,mult_pricestddev,quant,quantstddev = unpack(explode(";",entry)) -- {;1;.1;10000;.1}
		mult_price			= tonumber(mult_price) or 0
		mult_pricestddev	= tonumber(mult_pricestddev) or 0
		quant				= tonumber(quant) or 0
		quantstddev			= tonumber(quantstddev) or 0
		for k,o in pairs(gMasterPartList) do if (o.categoryname == cat) then -- file,categoryname,price,mass,volume,description
			-- "Jhurlon","Natural_Products/Food/Aera",140,1.05,1,"@cargo/jhurlon.image@A native of the Bzbr world, .... easier."
			-- note : upgrades/Armor has volume 0
			local path = o.path
			local base_price = tonumber(o.price) or 0
			tradeinfos[path] = {
				file				=o.file,
				categoryname		=o.categoryname,
				path				=path,
				cur_price			=floor(base_price * (mult_price + rand2f(-1,1) * mult_pricestddev)), -- todo : gauss random using stddev
				base_price			=base_price,
				mult_price			=mult_price,
				mult_pricestddev	=mult_pricestddev,
				quant				=quant,
				quantstddev			=quantstddev,
				mass				=tonumber(o.mass) or 0,
				volume				=tonumber(o.volume) or 0,
				description			=o.description,
				bIsUpgrade			=string.find(o.categoryname,"^upgrades/"),
				}
		end end
	end
	return tradeinfos
end

-- set price and amount random
function GenerateRandomTradeGoodsFromPriceInfos (infos)
	local res = {}
	for k,o in pairs(infos) do 
		local amount	= floor(o.quant + rand2f(-1,1) * o.quantstddev) -- todo : gauss random using stddev
		if (amount > 0) then res[o.path] = {path=o.path,price=o.cur_price,amount=amount} end
	end
	return res
end

function Docked_InitTradeGoods (base) -- base= cStation or cPlanet	
	-- get unittype of base/station/planet
	local t = base and GetUnitTypeFromSectorXMLNode(base.xmlnode) assert(t)
	
	-- generate price infos and goods list
	gTradeGoodInfos = GetTradeInfosForBaseType(t)
	gTradeGoods = GenerateRandomTradeGoodsFromPriceInfos(gTradeGoodInfos)
end

function GetTradeGoodPrice (path)
	local o = gTradeGoodInfos[path]
	if (o) then return o.cur_price end
	o = gMasterPartList_ByPath[path] assert(path)
	return tonumber(o.price) -- base-price
end

function TradeGui_Stop ()
	if (gTradeWindow) then gTradeWindow:Destroy() gTradeWindow = nil end
end

function TradeGui_Start ()
	--~ StartDragDropTest()
	
	local wnd_w = 800
	local wnd_h = 600
	local b = 4
	
	--~ gTradeWindow = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=100 y=100 w=800 h=600> <Text x=10 y=0 text='Trade' /> </Window>]])
	gTradeWindow = GetDesktopWidget():CreateContentChild("Window",{x=100,y=100,w=wnd_w,h=wnd_h})
	gTradeWindow:CreateContentChild("Text",{x=b,y=10,text="Trade"})
	local b1 = gTradeWindow:CreateContentChild("Button",{label="Close",on_button_click=function () TradeGui_Stop() end})
	local b1w,b1h = b1:GetSize()
	b1:SetPos(wnd_w-b1w-5,8)
	
	local partw = wnd_w/2 - 2*b
	gTradeWindow.list_buy  = gTradeWindow:CreateContentChild("VegaItemList",{btntext="buy" ,x=wnd_w*0+b,y=40,w=partw,h=(wnd_h-50),on_select_item=function (o) TradeSelectItem(o,false) end,items=gTradeGoods})
	gTradeWindow.list_sell = gTradeWindow:CreateContentChild("VegaItemList",{btntext="sell",x=wnd_w/2+b,y=40,w=partw,h=(wnd_h-50),on_select_item=function (o) TradeSelectItem(o,true ) end,items=gPlayerCargo})
end


function TradeSelectItem (item,bIsPlayerItem) 
	local path = item.path
	local a = gTradeGoods[path]
	local b = gPlayerCargo[path]
	print("TradeSelectItem",bIsPlayerItem,item.path,a,b)
	
	local function MyListChangeAmount (list,path,widget,amount_delta) 
		assert(amount_delta ~= 0)
		local o = list[path]
		if (amount_delta < 0) then
			assert(o)
			assert(o.amount + amount_delta >= 0)
			o.amount = o.amount + amount_delta
			if (o.amount == 0) then
				list[path] = nil
			end
		else 
			if (o) then
				o.amount = o.amount + amount_delta
			else 
				o = {path=path,price=GetTradeGoodPrice(path),amount=amount_delta}
				list[path] = o
			end
		end
		widget:UpdateItem(path,list[path])
	end
	
	if (bIsPlayerItem) then 
		-- sell
		if (b and b.amount >= 1) then 
			MyListChangeAmount(gTradeGoods ,path,gTradeWindow.list_buy , 1)
			MyListChangeAmount(gPlayerCargo,path,gTradeWindow.list_sell,-1)
		end
	else 
		-- buy
		if (a and a.amount >= 1) then 
			MyListChangeAmount(gTradeGoods ,path,gTradeWindow.list_buy ,-1)
			MyListChangeAmount(gPlayerCargo,path,gTradeWindow.list_sell, 1)
		end
	end
end

if (1==2) then 
	LoadUniverse()
	--~ for id,t in pairs(gUnitTypes) do if (string.find(id,"asteroid0")) then print("==================",id) for k,v in pairs(t) do if (v ~= "") then print(k,v) end end end end
	Docked_InitTradeGoods({xmlnode={file="planets/oceanBase.texture|planets/ocean.texture",faction="klkk"}})
	os.exit(0)
end

--[[ 
notes:
./master_part_list.csv:229:"Filtered_Water","Natural_Products/Food/Aera",40,3,3,"@cargo/fresh_water.image@The main building block of life....."
./master_part_list.csv:230:"Aera_Ration","Natural_Products/Food/Aera",40,1.4,1,"@cargo/aera_ration.image@Containing utilitarian ....."
./master_part_list.csv:231:"Jhurlon","Natural_Products/Food/Aera",140,1.05,1,"@cargo/jhurlon.image@A native of the Bzbr world,...."
./master_part_list.csv:232:"Salted_Thok","Natural_Products/Food/Aera",130,1.2,1,"@cargo/salted_thok.image@Though the Aera ...."

./textures/cargo/carbonium.image
./units/units_description.csv:247:armor05__upgrades,"@cargo/carbonium.png@Armor takes up no upgrade volume,..."
./units/units_description.csv:696:Carbonium,"@cargo/carbonium.png@A mix of tungsten and tantalum...."
./master_part_list.csv:304:"Carbonium","Refined_Materials/Alloys/Rlaan",40,6,1,"@cargo/carbonium.image@This alloy is generated f...."
./master_part_list.csv:558:"armor05","upgrades/Armor",64000,20,0,"@cargo/carbonium.image@Armor takes up no ..."

id          			ocean__planets
Directory   			./factions/planets/ocean
Name        			ocean
Hud_image   			planet-ocean-hud.sprite
Cargo_Import			..{Natural_Products/Food/Aera;1;.1;10000;.1}......{upgrades/Weapons/Mounted_Guns_Medium;1;.1;;3}
Cargo_Import-format:  	{Cat(string);price(percentage);pricestddev(percentage);quant(percentage);quantstddev(percentage)}
Upgrade_Storage_Volume	100000000

cloaking_device01__upgrades,,Cloaking Device,,Upgrade_Replacement,,,,,,,,,,,,,,,,4,4,,,,,,,,,,,,,,,,,,,,0.05,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,1,0.1,0.4,1,0,,,,,,,,,,,,,,,,,,,,,,,,

]]--

