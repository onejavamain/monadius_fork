--{-# OPTIONS -fffi #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module Audio(
  openAudio,
  closeAudio,
  playAudio,
  stopAudio,

  AudioHandle,
) where

import Foreign
import Foreign.C

type AudioHandle = Int


openAudio :: String -> String -> Int -> IO ()
openAudio s t id = do
  withCString s $ \cs ->
   withCString t $ \ct ->
    openAudio_w cs ct id


playAudio  = playAudio_w
stopAudio  = stopAudio_w
closeAudio = closeAudio_w

foreign import ccall "open_audio_w" openAudio_w :: CString -> CString -> AudioHandle -> IO ()
foreign import ccall "play_audio_w" playAudio_w :: AudioHandle -> IO ()
foreign import ccall "stop_audio_w" stopAudio_w :: AudioHandle -> IO ()
foreign import ccall "close_audio_w" closeAudio_w :: AudioHandle -> IO ()
