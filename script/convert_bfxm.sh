#!/bin/bash
# used by mass import in lib.import.xmesh.lua
pushd $1
#~ ./mesher file.bfxm file.xmesh bmc
/cavern/code/VegaStrike/vegastrike/mesher "$2" "${2}.xmesh" bxc
popd
