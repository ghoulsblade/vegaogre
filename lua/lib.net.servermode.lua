-- server mode

-- to run local server, grab cd into vegastrike-trunk (the dir containing data and vegastrike) and run vegaserver

gNetCmdFromClient = {} -- packet handler for packets received FROM client (e.g sent by server to client)
gNetCmdFromServer = {} -- packet handler for packets received FROM server (e.g sent by client to server)

-- ***** ***** ***** ***** ***** server mode

function StartServerMode (port) 
	print("StartServerMode not yet implemented")
	os.exit(0)
end

-- ***** ***** ***** ***** ***** server utils

function NetSendClientPacket (client,packet)
	if (gProxyMode) then return end
	-- client:SendPacket(packet), packet={cmd=CMD_CONNECT,serial=...,data=..}
end

-- ***** ***** ***** ***** ***** network connect sequence
--[[
from analyzing a network log:
C: CMD_CONNECT		(ser=CLIENT_NETVERSION,empty)
S: CMD_CONNECT		(ser=0,serial:netversion,str:clientip)
C: CMD_LOGIN		(ser=0,str:callsign,str:passwd)
S: CMD_CHOOSESHIP	(ser=0,short:#shipnames,str:shipnames[1],str:shipnames[2],...)
C: CMD_CHOOSESHIP	(ser=0,short:shipidx,str:shipname)
S: LOGIN_ACCEPT		(ser=X,str:stardate,str:savegame[0],str:savegame[1],str:systemname.system,short:crypto-hash-size,data:crypto-hash,short:zoneid,..) -- big data, 9k in sample
S: CMD_TXTMESSAGE	(ser=0,data:??"...Welcome, asd...")
C: CMD_DOWNLOAD		(ser=0,data:??..Crucible/Cephid_17.system)
S: CMD_DOWNLOAD		(ser=0,data:??..Crucible/Cephid_17.system)
C/S : several CMD_DOWNLOAD

CMD_DOWNLOAD		(ser=0,char:ResolveRequest,short:listlen,{char:filetype,str:filename}*)
CMD_DOWNLOAD		(ser=0,char:DownloadRequest,short:listlen,{char:filetype,str:filename}*)
CMD_DOWNLOAD		(ser=0,char:ResolveResponse,short:listlen,{str:file,char:ok_or_not}*)
CMD_DOWNLOAD		(ser=0,char:UnexpectedSubcommand,char:c)
CMD_DOWNLOAD		(ser=0,char:DownloadError,str:file)
CMD_DOWNLOAD		(ser=0,char:Download,str:file									,short:remainingSize,rawdata...)
CMD_DOWNLOAD		(ser=0,char:DownloadLastFragment								,short:remainingSize,rawdata...)
CMD_DOWNLOAD		(ser=0,char:DownloadFirstFragment,str:file,Int32:remainingSize	,short:L,rawdata...)
CMD_DOWNLOAD		(ser=0,char:DownloadFragment									,short:L,rawdata...)

C:CMD_SERVERTIME  several times... ping?

C:CMD_ADDCLIENT		-- undock or sth like that ?  or final ingame confirm
S:CMD_ADDEDYOU		
S:CMD_ENTERCLIENT			
S:CMD_SNAPCARGO			
S:CMD_CREDITS			
S:CMD_SNAPCARGO		huge data, planet contents atlantis ?? 37kb			
S:CMD_DOCK			
S:CMD_SAVEDATA		dozens of times..		total about 30kb...  mission texts etc ? 
S:CMD_CARGOUPGRADE	a few times, ships ?

C:CMD_CUSTOM		...campaign_readsave!
S:CMD_CARGOUPGRADE	a few times, ships ?
C:CMD_CUSTOM		...mission_lib!...CreateFixerMissions!.
S:CMD_CUSTOM		...mission_lib!...AddNewMission
S:CMD_CUSTOM		a few times, missions ?


]]--
-- ***** ***** ***** ***** ***** client send

ClientSend = {}
function ClientSend.CMD_CONNECT	()								NetSendPacket({cmd=CMD_CONNECT}) end
function ClientSend.CMD_LOGIN	(str_callsign,str_passwd)		NetSendPacket({cmd=CMD_LOGIN,data={{str=str_callsign},{str=str_passwd}}}) end


-- ***** ***** ***** ***** ***** gPacketFormat...

-- for packets with fixed structure this is used to decode packet data, so the results are passed as params to handler

local netcmd = VNet.Cmd

-- client -> server
gPacketFormatFromClient = {
	[netcmd.CMD_CONNECT]	= {}, 				-- h.ser=CLIENT_NETVERSION,empty
	[netcmd.CMD_LOGIN]		= {"str","str"},	-- h.ser=0,str:callsign,str:passwd
	[netcmd.CMD_CHOOSESHIP]	= {"short","str"},	-- h.ser=0,short:shipidx,str:shipname
	[netcmd.CMD_TXTMESSAGE]	= {"str"},			-- h.ser=0,str:chat
	[netcmd.CMD_SERVERTIME]	= {"short"},		-- h.ser=0,short:port -- (udp?)
	[netcmd.CMD_ADDCLIENT]	= {},				-- h.ser=ownserial?,empty
}

-- server -> client
gPacketFormatFromServer = {
	[netcmd.CMD_CONNECT]		= {"serial","str"},	-- h.ser=0,serial:netversion,str:clientip
	[netcmd.CMD_CHOOSESHIP]		= false,			-- h.ser=0,short:#shipnames,str:shipnames[1],str:shipnames[2],...
	[netcmd.LOGIN_ACCEPT]		= false,			-- h.ser=X,str:stardate,str:savegame[0],str:savegame[1],str:systemname.system,short:crypto-hash-size,data:crypto-hash,short:zoneid,..) -- big data, 9k in sample
	[netcmd.CMD_TXTMESSAGE]		= {"str","str"},	-- h.ser=0,str:from,str:text	(header : ser=XXX)  also weird crypto/broadcast frequency thing in vega/networkcomm.cpp, might be different
	[netcmd.CMD_ADDEDYOU]		= {"transform"},	-- h.ser=X,transform:pos
}

-- recursively extract format  (lua multiple return and recursive variable argument count handling)
function PacketFormatExtract (netbuf,curf,...)
	if (curf == nil) then return -- recursion end or empty packet
	elseif (curf == "str"		) then return netbuf:getString()			,PacketFormatExtract(netbuf,...) 
	elseif (curf == "serial"	) then return netbuf:getSerial()			,PacketFormatExtract(netbuf,...) 
	elseif (curf == "short"		) then return netbuf:getShort()				,PacketFormatExtract(netbuf,...) 
	elseif (curf == "transform"	) then return {netbuf:getTransformation()}	,PacketFormatExtract(netbuf,...) 
	else print("PacketFormatExtract:unknown format:",curf) return end
end


-- ***** ***** ***** ***** ***** gNetCmdFromClient

function gNetCmdFromClient.CMD_CONNECT (netbuf,h,ph,client)
	local netversion = h.serial
	print("C:CMD_CONNECT netversion=",netversion)
	assert(VNet.NetVersion == netversion)
	client.netversion = netversion
	-- reply with client ip
	client:SendPacket({cmd=CMD_CONNECT,data={{serial=VNet.NetVersion},{str=client.ip}}}) -- see vega class NetBuffer
end

function gNetCmdFromClient.CMD_LOGIN		(netbuf,h,ph,client,callsign,password) print("C:CMD_LOGIN callsign,password=",callsign,password) end
function gNetCmdFromClient.CMD_CHOOSESHIP	(netbuf,h,ph,client,shipidx,shipname) print("C:CMD_CHOOSESHIP shipidx,shipname=",shipidx,shipname) end
function gNetCmdFromClient.CMD_TXTMESSAGE	(netbuf,h,ph,client,txt) print("C:CMD_TXTMESSAGE txt=",txt) end
function gNetCmdFromClient.CMD_SERVERTIME	(netbuf,h,ph,client,port) print("C:CMD_SERVERTIME port=",port) end
function gNetCmdFromClient.CMD_ADDCLIENT	(netbuf,h,ph,client) print("C:CMD_ADDCLIENT ser=",h.serial) end

function gNetCmdFromClient.CMD_DOWNLOAD	(netbuf,h,ph,client) 
	local sc = netbuf:getChar()
	print("C:CMD_DOWNLOAD ",sc,VNet.GetDownloadSubCmdName(sc))
	local sc_enum = VNet.Download_Subcommand
	
	-- switch sc
		if (sc == sc_enum.ResolveRequest) then 
		-- TODO
	elseif (sc == sc_enum.DownloadRequest) then 
		-- TODO
	else -- default
		
	end
	
	-- TODO: send packets for fragments
end

-- ***** ***** ***** ***** ***** gNetCmdFromServer

function gNetCmdFromServer.CMD_CONNECT		(netbuf,h,ph,netversion,clientip)	print("S:CMD_CONNECT netversion,clientip=",netversion,clientip) end
function gNetCmdFromServer.CMD_TXTMESSAGE	(netbuf,h,ph,from,text)				print("S:CMD_TXTMESSAGE from,text=",from,text) end
function gNetCmdFromServer.CMD_ADDEDYOU		(netbuf,h,ph,t)						print("S:CMD_ADDEDYOU ser,transform=",h.serial,unpack(t)) end

function gNetCmdFromServer.CMD_CHOOSESHIP	(netbuf,h,ph)
	print("S:CMD_CHOOSESHIP")
	-- h.ser=0,short:#shipnames,str:shipnames[1],str:shipnames[2],...
	local num = netbuf:getShort()
	print("num ships:",num)
	for i=0,num-1 do 
		local name = netbuf:getString()
		print("+",i,name)
	end
end

function gNetCmdFromServer.LOGIN_ACCEPT		(netbuf,h,ph)
	print("S:LOGIN_ACCEPT (complex)")
	local		stardate 	= netbuf:getString()	print("+ stardate=",stardate)
	local		savegame1	= netbuf:getString()	print("+ savegame1=",savegame1)
	local		savegame2	= netbuf:getString()	print("+ savegame2=",savegame2)
	local		systemname	= netbuf:getString()	print("+ systemname=",systemname)
	local		hashsize	= netbuf:getShort()		print("+ hashsize=",hashsize)
	if (hashsize > 0) then 
		local fifo = CreateFifo()
		netbuf:getBuffer(fifo,hashsize)
		-- TODO: use data
		fifo:Destroy()
	end
	local		zoneid	= netbuf:getShort()	print("+ zoneid=",zoneid)
	
	-- h.ser=X,str:stardate,str:savegame[0],str:savegame[1],str:systemname.system,short:crypto-hash-size,data:crypto-hash,short:zoneid,..) -- big data, 9k in sample
end

function gNetCmdFromServer.CMD_DOWNLOAD	(netbuf,h,ph) 
	local sc = netbuf:getChar()
	print("S:CMD_DOWNLOAD ",sc,VNet.GetDownloadSubCmdName(sc))
	local sc_enum = VNet.Download_Subcommand
	
	-- switch sc
	if (sc == sc_enum.ResolveResponse		) then 
		print("+ private_eval_resolve_response")
		local num = netbuf:getShort()
		print("+ num=",num)
		for i=0,num-1 do 
			local file	= netbuf:getString()
			local ok	= netbuf:getChar()
			print("+ entry=",i,ok,file)
		end
    elseif (sc == sc_enum.DownloadError			) then 
		print("+ private_eval_download_error")
		local file	= netbuf:getString()
		print("+ file=",file)
	elseif (sc == sc_enum.Download
		 or sc == sc_enum.DownloadFirstFragment
		 or sc == sc_enum.DownloadFragment
		 or sc == sc_enum.DownloadLastFragment	) then 
		 print("+ private_eval_download")
		 
		 local filename,len,sz
		 local buf = CreateFIFO()
		 
		 if (sc == sc_enum.Download				) then filename = netbuf:getString()							sz = netbuf:getShort() netbuf:getBuffer(buf,sz) end
		 if (sc == sc_enum.DownloadFirstFragment) then filename = netbuf:getString() len = netbuf:getInt32()	sz = netbuf:getShort() netbuf:getBuffer(buf,sz) end
		 if (sc == sc_enum.DownloadFragment		) then 															sz = netbuf:getShort() netbuf:getBuffer(buf,sz) end
		 if (sc == sc_enum.DownloadLastFragment	) then 															sz = netbuf:getShort() netbuf:getBuffer(buf,sz) end
		 
		 print("+ filename,len,sz",tostring(filename),tostring(len),tostring(sz))
		 buf:Destroy()
	elseif (sc == sc_enum.DownloadRequest
		 or sc == sc_enum.UnexpectedSubcommand
		 or sc == sc_enum.ResolveRequest
		 or true								) then
		 print("+ unexpected subcommand "..sc..", ignoring") -- or true:default from switch case
	end
	
	-- TODO: store fragments and assemble file
end


function gNetCmdFromServer.CMD_ENTERCLIENT	(netbuf,h,ph)
	print("S:CMD_ENTERCLIENT ser",h.serial,"TODO : big data chunk from ZoneMgr::getZoneBuffer : unitlists etc")
	-- TODO: parse unit list
end
function gNetCmdFromServer.CMD_SNAPCARGO	(netbuf,h,ph)
	print("S:CMD_SNAPCARGO ser",h.serial,"TODO : big cargo data : addUnitCargoSnapshot")
	-- TODO: parse unit list
end

-- ***** ***** ***** ***** ***** end
