#ifndef _ALU_H_
#define _ALU_H_

#include "AL/al.h"
#include "AL/alc.h"

#ifdef __cplusplus
extern "C" {
#endif

enum {
    FRONT_LEFT = 0,
    FRONT_RIGHT,
    SIDE_LEFT,
    SIDE_RIGHT,
    BACK_LEFT,
    BACK_RIGHT,
    CENTER,
    LFE,

    OUTPUTCHANNELS
};

extern ALboolean DuplicateStereo;

__inline ALuint aluBytesFromFormat(ALenum format);
__inline ALuint aluChannelsFromFormat(ALenum format);
ALvoid aluMixData(ALCcontext *context,ALvoid *buffer,ALsizei size,ALenum format);

#ifdef __cplusplus
}
#endif

#endif

