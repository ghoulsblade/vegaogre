-- parse packetlogs from wireshark (follow tcp stream, c array), and output interpretation in vegastrike protocol
-- ./start.sh -packetlog packetlogs/buy.c

local kFromTxtClient = "client"
local kFromTxtServer = "server"

function PacketLogParse (path)
	print("-- "..path)
	local packetconvert_lua = {}
	for line in io.lines(gMainWorkingDir..path) do
		-- char peer0_0[] = { 0x00, 0x00, 0x00, 0x34, 0x01, 0x00, 0x00, 0x00 };
		local a,b,comment = string.find(line,"(//.*)")
		if (comment) then print("-- "..comment) end
		line = string.gsub(line,"//.*","") -- remove comment
		line = string.gsub(line,"^[ \t]+","") -- trim
		line = string.gsub(line,"[ \t]+$","") -- trum
		if (line ~= "") then 
			line = string.gsub(line,"char.*peer0_.+%{","MyClient({")
			line = string.gsub(line,"char.*peer1_.+%{","MyServer({")
			line = string.gsub(line,"};","})")
			table.insert(packetconvert_lua,line)
			--~ print(line)
		end
	end
	function MyClient (data) PacketLog_Arr(data,kFromTxtClient) end
	function MyServer (data) PacketLog_Arr(data,kFromTxtServer) end
	
	-- translate c syntax packetlog to lua and then run it
	packetconvert_lua = table.concat(packetconvert_lua,"\n")
	assert(loadstring(packetconvert_lua))() 
	
	os.exit(0)
end

local fifos = {}
fifos[kFromTxtClient] = CreateFIFO()
fifos[kFromTxtServer] = CreateFIFO()
function PacketLog_Arr (data,fromtxt) 
	local fifo = fifos[fromtxt]
	--~ fifo:Clear() 
	for k,v in ipairs(data) do fifo:PushNetUint8(v) end
	while (MyDecodePacket(fifo,fromtxt)) do end
end

local netbuf = cVegaNetBuf:New()
local fifo_payload = CreateFIFO()
function MyDecodePacket (fifo,fromtxt)
	-- check if packet is complete
	local fifolen_full = fifo:Size()
	if (fifolen_full <= 0) then return end 
	local bPrintIncomplete = false
	--~ local bPrintIncomplete = true
	local lmin = VNet.PreHeaderLen+VNet.HeaderLen												if (lmin > fifolen_full) then if (bPrintIncomplete) then print("-- from:"..fromtxt.." packet incomplete, headers",lmin,fifolen_full) end return false end
	local lmin = VNet.PreHeaderLen+VNet.PeekPreHeaderLen(fifo)									if (lmin > fifolen_full) then if (bPrintIncomplete) then print("-- from:"..fromtxt.." packet incomplete, datalen prehead",lmin,fifolen_full) end return false end
	local lmin = VNet.PreHeaderLen+VNet.HeaderLen+VNet.PeekHeaderLen(fifo,VNet.PreHeaderLen)	if (lmin > fifolen_full) then if (bPrintIncomplete) then print("-- from:"..fromtxt.." packet incomplete, datalen head",lmin,fifolen_full) end return false end
	
	-- pop  headers
	local ph = VNet.PopPreHeader(fifo)
	local h = VNet.PopHeader(fifo)
	local cmdname = VNet.GetCmdName(h.command)
	local datalen = h.data_length
	local fifolen_data = fifo:Size()
	
	-- pop data
	if (datalen >= 0 and datalen <= fifo:Size()) then
		fifo_payload:Clear()
		fifo_payload:PushFIFOPartRaw(fifo,0,min(datalen,fifo:Size()))
		if (datalen > 0) then fifo:PopRaw(datalen) end
		--~ print("removing payload data. removed,remaining=",datalen,fifo:Size())
	else
		print("failed to remove payload data, clearing fifo for recovery. payload request, actual size",datalen,fifo:Size())
		fifo:Clear()
	end
	
	-- print output
	local txt_prehead	= "{len="..ph._len..",pri="..ph._pri..",flags="..Hex(ph._flags).."}"
	local txt_head		= "{cmd="..h.command..",serial="..h.serial..",datalen="..h.data_length..",flags="..Hex(h.flags).."}"
	local txt_add = ""
	--~ txt_add = txt_add .. ",fifolen_full="..fifolen_full..",fifolen_data="..fifolen_data..",fifolen_left="..fifo:Size()
	local txt_subcmd = ""
	if (h.command == VNet.Cmd.CMD_DOWNLOAD) then 
		netbuf:ReInit(fifo_payload)
		local sc = netbuf:getChar() -- todo: this removes data, make copy if buffer is analyzed
		txt_subcmd = ",submd="..VNet.GetDownloadSubCmdName(sc)
	end
	
	print("Packet({from="..fromtxt..",cmd="..(cmdname or h.command)..txt_subcmd..",head={"..txt_prehead..","..txt_head.."}"..txt_add.."})")

	
	return true
end
