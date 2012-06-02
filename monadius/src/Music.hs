module Music(
  Music(..),
  playMusic,
  withMusic
)where

import System.Process  
import Audio

data Music =
    Prelude | Stage0 | Stage1 | Stage2 | Boss | GameOver | Ending |
    PowerUpSE | GetCapsule | ShotSE | LaserSE | MissileHit |
    DestroyBig | DestroyMiddle | DestroySmall 
	      deriving(Eq,Show,Enum)

toAudioHandle::Music->AudioHandle
toAudioHandle = fromEnum 

bgms = [Prelude .. Ending]
effects = [PowerUpSE .. DestroySmall] 
allAudio = bgms ++ effects
bgmHandles = map toAudioHandle bgms




withMusic::IO a -> IO a
withMusic ioMonad = do
  mapM_ (\ m -> openAudio (show m ++ ".mp3") "mpegvideo" (toAudioHandle m) ) $
    bgms
  mapM_ (\ m -> openAudio (show m ++ ".wav") "waveaudio" (toAudioHandle m) ) $
    effects
  ret <- ioMonad
  mapM_ (stopAudio.toAudioHandle) bgms 
  mapM_ (closeAudio.toAudioHandle) bgms
  return ret

playMusic::Music->IO ()
playMusic m = do
  if (m `elem` bgms) then
     mapM_ (stopAudio.toAudioHandle) bgms 
    else return ()
  playAudio $ toAudioHandle m
  return ()



{-
  if needMusic then do
		    runCommand $ player ++ " " ++ show m ++ ".mp3 /c"
		    return ()
     else return () where
		    player = "f:\\winamp\\winamp.exe"

-}