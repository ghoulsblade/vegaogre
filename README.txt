VegaStrike port/rewrite using ogre

VegaStrike Main Website : http://vegastrike.sourceforge.net

to run on win : doubleclick the .exe
to run on linux : run ./start.sh

discussion thread (2010.08.03) http://vegastrike.sourceforge.net/forums/viewtopic.php?f=27&t=15545

contact : ghoulsblade@schattenkind.net

tech : light c++ framework + heavy lua scripting, using lugre (lua+ogre) framework : http://lugre.schattenkind.net/

code repos : gitosis@zwischenwelt.org:vegaogre.git		(will be made public readonly as soon as i find out how *g*, please use contact email in the meantime)

license : code : some GPL version, not sure yet if v2,v3 or "v3 or later"

uses artwork (models,images,sounds,musik...) from VegaStrike,
	see		https://vegastrike.svn.sourceforge.net/svnroot/vegastrike/trunk/masters
	and		https://vegastrike.svn.sourceforge.net/svnroot/vegastrike/trunk/data
	for originals and license details. (most are GPL2 i think)

to compile on linux :  run ./installdeps.ubuntu.sh (follow some manual instructions) ./makeclean.sh ./premakelinux.sh

to compile on win :  no guide available at the moment, please use contact email if there is interest

== compile troubleshooting ==

* linux : fmod problem ? try ./makeclean.sh && ./premake.linux --nosound
	
== controls ==

tab : guimode
w-a-s-d : ship move
r-f : up/down
q-e : roll
shift : slow
ctrl : afterburner

left-mouse : fire
