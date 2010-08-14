#!/bin/bash
echo "envvar: $LD_LIBRARY_PATH"
pushd bin
LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

#../src/vegaogre
# start, and transmit all parameters
# note : http://tldp.org/LDP/abs/html/othertypesv.html  : above 9: ${10} all: $* and $@ 
./vegaogre $@
#~ ../vegaogre $@
popd
