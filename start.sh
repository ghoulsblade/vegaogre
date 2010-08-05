#!/bin/bash
pushd bin
#../src/vegaogre
# start, and transmit all parameters
# note : http://tldp.org/LDP/abs/html/othertypesv.html  : above 9: ${10} all: $* and $@ 
./vegaogre $@
#~ ../vegaogre $@
popd
