module Recorder (
  Recorder(..),initialRecorder,RecorderMode(..),
  encode2,decode
)where 

-- a replay recording system.

import Graphics.UI.GLUT.Callbacks
import Graphics.UI.GLUT hiding (position)
import Graphics.Rendering.OpenGL.GLU
import Data.Maybe
import Monadius
import Game
import Util

data Recorder = Recorder{keybuf::[[Key]],preEncodedKeyBuf::[Int],mode::RecorderMode,gameBody::Monadius,age::Int,isQuitRequested::Bool}
data RecorderMode = Play | Playback | Record deriving (Eq,Show)

instance Game Recorder where
  update = updateRecorder
  render = renderRecorder
  isGameover = recorderIsGameover

encode::[[Key]]->String
encode keySets= (show.map encodeKeySet) keySets
encode2::[Int]->String
encode2 = show.reverse
encodeKeySet::[Key]->Int
encodeKeySet keys = sum $ map (\i->if (importantKeys!!i) `elem` keys then 2^i else 0) [0..(length importantKeys-1)]

decode::String->[[Key]]
decode str = map decodeKeySet (read str::[Int])
decodeKeySet::Int->[Key]
decodeKeySet num = extract num importantKeys where
  extract 0 _     = []
  extract _ []    = []
  extract i (c:cs) = (if i `mod` 2 == 1 then [c] else []) ++ extract (i `div` 2) cs

importantKeys = [shotButton,missileButton,powerUpButton,upButton,downButton,leftButton,rightButton,selfDestructButton]

initialRecorder::RecorderMode->[[Key]]->Monadius->Recorder
initialRecorder initialMode keyss initialGame = Recorder{
  keybuf = if initialMode == Playback then keyss ++ repeat [] else [],
  preEncodedKeyBuf = [],
  mode = initialMode,
  gameBody = initialGame,
  age=0,
  isQuitRequested = False
}

updateRecorder::[Key]->Recorder->Recorder
updateRecorder keys me = me{
  --keybuf = (if mode me == Record then (++ [keys]) else id) $ keybuf me,
  preEncodedKeyBuf = (if mode me == Record then (encodeKeySet keys:) else id) $ preEncodedKeyBuf me,
  gameBody = (if mode me /= Playback then update keys else update (keybuf me!!age me)) $ gameBody me,
  age = age me + 1,
  isQuitRequested = (mode me == Playback && (selfDestructButton `elem` keys || Char ' ' `elem` keys)) || isQuitRequested me
}

renderRecorder::Recorder->IO ()
renderRecorder me = do
  (putDebugStrLn.show.mode) me
  if age me==0 || mode me /= Record then return () else preservingMatrix $ do
    translate (Vector3 300 (-230) (0::Double))
    scale 0.1 0.1 (0.1::Double)
    color (Color3 0.4  0.4 (0.4::Double))
    renderString Roman $ show $ (head.preEncodedKeyBuf) me 
    
  render $ gameBody me

recorderIsGameover me = (isGameover.gameBody) me || isQuitRequested me





