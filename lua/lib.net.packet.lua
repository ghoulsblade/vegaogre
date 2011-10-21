-- vegastrike network packets

VNet = {}

-- vega/vsnet_cmd.h enum Cmd
VNet.Cmd = {
    ---------- 0x0* Login commands ----------
    CMD_SERVERTIME=0x00,                --Client side : Request the most up-to-date server time.
    --Server side : Send the current game time (double).
    CMD_LOGIN=0x01,             --Client side : login request sent to server with name and passwd
    CMD_LOGOUT    =0x02,        --Client side : tells the server we are logging out
                                --Server side : remove the client from the game
    LOGIN_ERROR   =0x03,        --Packet sent from account server to client :
                                --a login error (mostly bad name/passwd)
    LOGIN_ACCEPT  =0x04,        --Packet sent from account server to client :
                                --login accepted
    LOGIN_DATA    =0x05,
    LOGIN_ALREADY =0x06,        --Packet sent from account server to client
                                --to tell account is already being used
    LOGIN_NEW    =0x07,
    --CMD_unused_0x08 = 0x08,
    LOGIN_UNAVAIL=0x09,                 --Packet sent from game server to client :
    --account server is unavailable -> no login

    --Character creation stuff (not used yet)
    CMD_CREATECHAR =0x0A,       --DELETEME?  Could come in handy from accountserver -> client...  but not so much from server...
    CMD_LOCATIONS  =0x0B,

    --Commands used to add/remove ships in systems
    CMD_ADDCLIENT  =0x0C,               --Client side :
    --request the server to be added in the game
    --Server side : adds the client to the game
    CMD_ENTERCLIENT=0x0D,               --(Server -> Client) Indicates that a new
    --client is entering the current zone
    --also send the new client's data
    --Subcommands: ZoneMgr::AddClient,AddUnit,AddMissile,AddNebula,AddAsteroid,End
    CMD_EXITCLIENT=0x0E,                --(Server -> Client) Indicates that a client
    --is leaving the current zone
    CMD_ADDEDYOU  =0x0F,                --Server -> Client

    ---------- 0x1* In-game updates ----------

    CMD_RESPAWN  =0x10,               --Client -> Server: Request a respawn after dying.

    --Ships movements data
    CMD_POSUPDATE=0x11,                 --On client side (send): containing a ship's
    --data sent to server for position update
    --On client side (recv) : receive minimal update
    --data for a ship
    --On server side : sending minimal info
    --(just position) in case the ship is far from
    --the one we send other ships' data to
    CMD_PING    =0x12,                  --A packet sending a ping-like command just to
    --tell to the server
    --that the client is still alive
    CMD_SNAPSHOT=0x13,                  --A packet with all the necessary ships' data
    --in order to update

    --Weapons commands
    CMD_FIREREQUEST  =0x14,                     --Fire Request
    CMD_UNFIREREQUEST=0x15,             --UnFire Request
    CMD_TARGET    =0x16,                        --Receive a target request (server side)
    CMD_CLOAK     =0x17,
    --or receive target info (client side)
    CMD_SCAN      =0x18,                        --Receive a scan request (server side)
    --or receive target info (client side)
    CMD_DAMAGE    =0x19,                        --Send damages to apply
    CMD_SNAPDAMAGE=0x1A,                        --A snapshot of damages

    CMD_KILL      =0x1B,                        --Send a kill to clients
    CMD_JUMP      =0x1C,                        --Send a jump request
    CMD_ASKFILE   =0x1D,                        --Ask the server for files (char=number of
    --files and string containing the file names)
    CMD_DOWNLOAD  =0x1E,                        --May be identical to CMD_ASKFILE in the end
    --CMD_unused_0x1F = 0x1F ,		-- This means a webcam-shot just arrived (from client to server and from server to concerned clients)

    --2* Misc. commands

    CMD_SOUNDSAMPLE =0x20,                      --This means a sound sample just arrived (from client to server and from server to concerned clients or from client to clients)
    CMD_TXTMESSAGE  =0x21,                      --This means a text message has arrived
    CMD_STARTNETCOMM=0x22,                      --A client tells the server he starts a netcomm session
    CMD_STOPNETCOMM =0x23,                      --A client tells the server he stops a netcomm session
    CMD_SECMESSAGE  =0x24,                      --This means a sound sample just arrived (from client to server and from server to concerned clients or from client to clients)
    CMD_SECSNDSAMPLE=0x25,                      --This means a sound sample just arrived (from client to server and from server to concerned clients or from client to clients)

    CMD_DOCK          =0x26,                    --Dock request or authorization from server
    CMD_UNDOCK        =0x27,                    --Undock request or authorization from server

    CMD_SNAPCARGO     =0x28,                            --S->C: A full update of the up-to-date cargo inventory in all ships.  Sent when logging in.
    CMD_CARGOUPGRADE  =0x29,                    --C->S and S->C (broadcast): buy/sell cargo or upgrade.
    CMD_CREDITS       =0x2A,                --S->C: updates the number of credits.  Required after a cargo/upgrade transaction.

    --Account management commands
    CMD_RESYNCACCOUNTS=0x2B,                    --When connection to account server was lost
    --and established again :
    --send the account server a list of active
    --client to sync and log out
    --client that may have quit the game during
    --loss of connection
    CMD_SAVEACCOUNTS=0x2C,                      --Send a client save to account server in order
    --to do a backup
    CMD_NEWSUBSCRIBE=0x2D,              --Account server : handle a new account creation
    --(login/passwd) on the web
    CMD_CONNECT=0x2E,                                   --C->S, response S->C: Upon opening connection
    CMD_CHOOSESHIP  =0x2F,                              --S->C, response C->S: Server needs client to choose a ship
    --before it can send LOGIN_ACCEPT.

    CMD_DISCONNECT  =0x30,              --UDP : after a problem (not clean exit) to make
    --the client exit if still alive

    CMD_SAVEDATA    =0x31,
    CMD_MISSION   =0x32,

    CMD_CUSTOM    =0x33,                --Used for python scripts to communicate between client and server.
    CMD_SHIPDEALER=0x34,                        --C->S: Request to purchase ship, S->C: Unimplemented
    CMD_COMM=0x35,                              --C->S: Send a Comm message to target, S->C: Say something to player
}

VNet.CmdName = {} for k,v in pairs(VNet.Cmd) do VNet.CmdName[v] = k end

--[[
class Subcmd
{
public:
    enum SaveDataTypes
    {
        StringValue=1<<1,
        FloatValue =1<<2,
        Objective  =1<<3,
    };

    enum SaveDataActions
    {
        SetValue  =1<<8,
        EraseValue=1<<9,
    };

    enum MissionActions
    {
        TerminateMission=1,
        AcceptMission   =2,
    };

    enum ShipActions
    {
        BuyShip   =1,
        SellShip  =2,
        SwitchShip=3,
    };
};
]]--

function VNet.GetCmdName (cmd) return VNet.CmdName[cmd] end
VNet.PreHeaderLen = 4+1+1+1+1 -- 8
VNet.HeaderLen = 1+1+2+4+4+2+2 -- 16
assert(VNet.PreHeaderLen == 8)
assert(VNet.HeaderLen == 16)

--[[
	   FL  pad serial  ----time------  ----------len-  -flag-  --pad-
hex16: 2E, 00, 13, 83, 00, 00, 14, 03, 00, 00, 00, 00, 00, 00, 00, 00,
header: cmd=46=0x2e ser=4995=0x1383 time=5123=0x00001403 len=0=0x00000000 flags=0x0000

	   FL  pad serial  ----time------  ----------len-  -flag-  --pad-
hex16: 01, 00, 00, 00, 00, 00, 14, 04, 00, 00, 00, 0B, 00, 00, 00, 00,
header: cmd=1=0x01 ser=0=0x0000 time=5124=0x00001404 len=11=0x0000000b flags=0x0000

	   FL  pad serial  ----time------  ----------len-  -flag-  --pad-
hex16: 2E, 32, 00, 00, A4, 14, 62, 80, 00, 00, 00, 11, 00, 00, 00, 00,
header: cmd=46=0x2e ser=0=0x0000 time=-1542167936=0xa4146280 len=17=0x00000011 flags=0x0000

	   FL  pad serial  ----time------  ----------len-  -flag-  --pad-
hex16: 2F, 36, 00, 00, A4, 14, 62, A7, 00, 00, 05, DB, 00, 00, 00, 00,
header: cmd=47=0x2f ser=0=0x0000 time=-1542167897=0xa41462a7 len=1499=0x000005db flags=0x0000

	   FL  pad serial  ----time------  ----------len-  -flag-  --pad-
hex16: 13, 33, 00, 01, A4, 1B, D9, 6B, 00, 00, 01, 89, 01, 00, 00, 00,
header: cmd=19=0x13 ser=1=0x0001 time=-1541678741=0xa41bd96b len=393=0x00000189 flags=0x0100


preheader : 		
	   ----len-------  pr pad  fl pad  		(len,prio,flags)
hex16: 00  00  00  10  01  00  00  00
]]--

function VNet.PopPreHeader (fifo) -- vega: VsnetTCPSocket::Header, comes before a complete "Packet"
	local res = {}
	res._len		= fifo:PopNetUint32() 
	res._pri		= fifo:PopNetUint8()
	res.pad01		= fifo:PopNetUint8() -- padding, vega has 2 byte aligned header struct, doh
	res._flags		= fifo:PopNetUint8()
	res.pad02		= fifo:PopNetUint8() -- padding, vega has 2 byte aligned header struct, doh
	return res
end
function VNet.PopHeader (fifo) -- vega: Packet::Header, the first part of a "Packet", comes right before the data
	local res = {}
	res.command		= fifo:PopNetUint8()
	res.pad01		= fifo:PopNetUint8() -- padding, vega has 2 byte aligned header struct, doh
	res.serial		= fifo:PopNetUint16() -- typedef unsigned short ObjSerial;
	res.timestamp	= fifo:PopNetUint32()
	-- unsigned int  delay;
	res.data_length	= fifo:PopNetUint32()
	res.flags		= fifo:PopNetUint16()
	res.pad02		= fifo:PopNetUint16()	-- whole packet is 16byte, so 4byte aligned struct size + 2 byte aligned field size?
	return res
end

