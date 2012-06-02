#include <windows.h>
#include <mmsystem.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "HsFFI.h"

void open_audio(char *filename,char *filetype, int id)
{
  char cmd[256];
  sprintf(cmd,"open \"%s\" type %s alias %d",filename,filetype,id);
  mciSendString(cmd,NULL,0,0);
}

void play_audio(int aid)
{
  char cmd[256];
  sprintf(cmd,"play %d from 0",aid);
  mciSendString(cmd,NULL,0,0);
}

void stop_audio(int aid)
{
  char cmd[256];
  sprintf(cmd,"stop %d",aid);
  mciSendString(cmd,NULL,0,0);
}

void unload_audio(int aid)
{
  char cmd[256];
  sprintf(cmd,"close %d",aid);
  mciSendString(cmd,NULL,0,0);
}

void open_audio_w(HsPtr s,HsPtr t,HsInt id){ open_audio((char*)s,(char*)t,id); }
void play_audio_w(HsInt s){ play_audio(s); }
void stop_audio_w(HsInt s){ stop_audio(s); }
void close_audio_w(HsInt s){ unload_audio(s); }

/*
int main()
{
  //int aid=open_audio("stage0.mp3");
  //play_audio(aid);
  //for (;;);

  char cmd[256];
  for (;;){
    gets(cmd);
    if (strncmp(cmd,"load",4)==0){
      int aid=open_audio(cmd+5);
      printf("%d\n",aid);
    }
    else if (strncmp(cmd,"play",4)==0){
      int aid=atoi(cmd+5);
      play_audio(aid);
    }
    else if (strncmp(cmd,"stop",4)==0){
      int aid=atoi(cmd+5);
      stop_audio(aid);
    }
  }
  
  return 0;
}
*/
