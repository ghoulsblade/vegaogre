
-- handles trade stuff, uses units.csv:Cargo_Import and master_part_list.csv

-- lists all tradegoods from master_part_list.csv for the t.Cargo_Import of input param t (planet/station type)
function GetTradeListForBaseType (t)
	assert(t)
	local tradelist = {}
	for entry in string.gmatch(t.Cargo_Import or "","{([^}]*)}") do
		local cat,mult_price,mult_pricestddev,quant,quantstddev = unpack(explode(";",entry)) -- {;1;.1;10000;.1}
		mult_price			= tonumber(mult_price) or 0
		mult_pricestddev	= tonumber(mult_pricestddev) or 0
		quant				= tonumber(quant) or 0
		quantstddev			= tonumber(quantstddev) or 0
		for k,o in pairs(gMasterPartList) do if (o.categoryname == cat) then -- file,categoryname,price,mass,volume,description
			-- "Jhurlon","Natural_Products/Food/Aera",140,1.05,1,"@cargo/jhurlon.image@A native of the Bzbr world, .... easier."
			-- note : upgrades/Armor has volume 0
			table.insert(tradelist,{
				file				=o.file,
				categoryname		=o.categoryname,
				path				=o.categoryname.."/"..o.file,
				base_price			=tonumber(o.price) or 0,
				mult_price			=mult_price,
				mult_pricestddev	=mult_pricestddev,
				quant				=quant,
				quantstddev			=quantstddev,
				mass				=tonumber(o.mass) or 0,
				volume				=tonumber(o.volume) or 0,
				description			=o.description,
				bIsUpgrade			=string.find(o.categoryname,"^upgrades/"),
				})
		end end
	end
	return tradelist
end


function Docked_InitTradeGoods (base) -- base= cStation or cPlanet	
	-- empty old tradegoods
	gTradeGoods = {}
	
	-- get unittype of base/station/planet
	local t = base and GetUnitTypeFromSectorXMLNode(base.xmlnode) assert(t)
	gTradeGoods = GetTradeListForBaseType(t)
	
	-- set price and amount random
	for k,o in ipairs(gTradeGoods) do 
		o.price		= floor(o.base_price * (o.mult_price + rand2f(-1,1) * o.mult_pricestddev))
		o.amount	= floor(o.quant + rand2f(-1,1) * o.quantstddev)
		if (o.amount > 0) then print(o.path,NiceNum(o.price),o.amount) end
	end
end

if (1==2) then 
	LoadUniverse()
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
]]--

