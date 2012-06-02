-- Copyright 2005 Hideyuki Tanaka & Takayuki Muranushi
--  this program is distributed under the terms of the GNU General Public License.

--   NOTE
-- this project meant to list up, not to solve, many possible problems that will appear
-- while writing a game in haskell.
-- only nushio is responsible to the unreadability of these codes.

module Main(    
  main  
)where 

import Graphics.UI.GLUT hiding (position)
import Graphics.Rendering.OpenGL.GLU
import Control.Exception
import Control.Monad
import System.Exit
import Prelude hiding (catch)

import Data.IORef
import Data.List 
import Data.Complex 
import Data.Maybe    
import System.Process  
import System.Directory
import System.IO
import System.Environment 
import Recorder
import Util         
import Game
import Demo
import Music
import Monadius   
   
data GlobalVariables = GlobalVariables{
  saveState::(Int,Int) ,isCheat::Bool, demoIndex::Int,
  recorderMode::RecorderMode,
  -- <recorderMode> means general gamemode that user wants,
  -- <mode> of a recorder means current gamemode.
  -- two are different when temporal demo replays.
  playbackKeys::[[Key]],playbackSaveState::(Int,Int),playBackName::Maybe String,
  recordSaveState::(Int,Int),saveHiScore::Integer
  }
 

replayFileExtension = ".replay"
presentationMode = True

loadReplay::String-> IO ReplayInfo
loadReplay filename = readFile filename >>= (return.read)

main = withMusic $ do 
  args <-getArgs
  putDebugStrLn $ show args 

  keystate <- newIORef []   

  (recMode,keys,rss,repName) <- if isJust $ getReplayFilename args then do 
      ReplayInfo (ss,keystr) <- (loadReplay.fromJust.getReplayFilename)args
      return (Playback,decode keystr,ss,Just $ (simplify.fromJust.getReplayFilename)args)
    else if "-r" `elem` args then do
        return (Play,[],(1,0),Nothing)
      else
        return (Record,[],(1,0),Nothing) 

  cp <- newIORef (openingProc 0 0 GlobalVariables{saveState = (1,0) ,isCheat = False,
    recorderMode=recMode,playbackKeys=keys,playbackSaveState = rss,recordSaveState=(1,0),demoIndex=0,
    playBackName=repName,saveHiScore=0} keystate)
  
  initialWindowSize $= Size 640 480  
--  initialWindowPosition  $= Position 160 120 
  initialDisplayMode $= [RGBAMode,DoubleBuffered{-,WithDepthBuffer,WithAlphaComponent-}]
  

  wnd <- createWindow "Monadius"
  
  curwnd <- if "-f" `elem` args then do
    gameModeCapabilities $= [ 
        Where' GameModeWidth IsLessThan 650,  
        Where' GameModeHeight IsLessThan 500
        --Where' GameModeBitsPerPlane IsEqualTo 32, 
        --Where' GameModeRefreshRate IsAtLeast 30,       
        --Where' GameModeNum IsAtLeast 2          
      ]
       
    displayCallback $= dispProc cp
    (wnd2,flg) <- enterGameMode 
    destroyWindow wnd
    return wnd2
   else do
    return wnd
  

    
        
  displayCallback $= dispProc cp
  keyboardMouseCallback $= Just (keyProc keystate)
  --closeCallback $= Just closeProc

  addTimerCallback 16 (timerProc (dispProc cp))


--  attachMenu LeftButton (Menu [
--    MenuEntry "&Exit" exitLoop])

  initMatrix
  --do
  --  runCommand "start.mp3"
  mainLoop
  destroyWindow curwnd  

  `catch` (\exc -> return ())  
  
  where
  getReplayFilename args = if length candidates == 0 then Nothing else Just (head candidates) where
    candidates = filter (replayFileExtension `isSuffixOf`) args
  simplify str = (removesuffix.removedir) str
  removedir str = if '\\' `elem` str || '/' `elem` str then (removedir.tail) str else str
  removesuffix str = if '.' `elem` str then (removesuffix.init) str else str

exitLoop = do
  throwIO $ ExitException ExitSuccess

initMatrix = do
  viewport $= (Position 0 0,Size 640 480)
  matrixMode $= Projection
--  loadIdentity
--  ortho (-320) 320 (-240) 240 (-1000) 1000        
  loadIdentity 
  perspective 30.0 (4/3) 600 1400
  lookAt (Vertex3 0 0 (927::Double)) (Vertex3 0 0 (0::Double)) (Vector3 0 1 (0::Double))

dispProc cp = do
  m <- readIORef cp
  Scene next <- m 
  writeIORef cp next    
 
data Scene = Scene (IO Scene)
-- Scene is something that does some IO, 
-- then returns the Scene that are to be executed in next frame.

openingProc :: Int -> Int -> GlobalVariables -> IORef [Key] -> IO Scene 
openingProc clock menuCursor vars ks = do
  if recorderMode vars == Playback then gameStart (fst $playbackSaveState vars) (snd $playbackSaveState vars) (isCheat vars) Playback vars else do
  if clock > demoStartTime then do demoStart vars else do

  if clock==1 then playMusic Prelude else return()

  keystate <- readIORef ks
  clear [ColorBuffer,DepthBuffer]
  matrixMode $= Modelview 0
  loadIdentity

  if clock < drawCompleteTime then color $ Color3 (0::Double) 0.2 0.8
    else color $ Color3 (0+shine clock::Double) (0.2+shine clock) (0.8+shine clock)
  preservingMatrix $ do
    translate (Vector3 0 (120::Double) 0)
    scale 1.05 1 (1::Double)
    mapM_ (renderPrimitive LineStrip . renderVertices2D.delayVertices clock) [lambdaLfoot,lambdaRfoot]
  color $ Color3 (1.0::Double) 1.0 1.0
  preservingMatrix $ do
    translate $ Vector3 (-195::Double) (130) 0
    scale (0.73::Double) 0.56 0.56
    renderStringGrad Roman 0 "Monadius" 
  preservingMatrix $ do
    if menuCursor==0 then color $ Color3 (1.0::Double) 1.0 0 else color $ Color3 (1.0::Double) 1.0 1.0
    translate $ Vector3 (-230::Double) (-200) 0
    scale (0.2::Double) 0.2 0.3
    renderStringGrad Roman 60 $ (if menuCursor==0 then ">" else " ") ++ "New Game"
  preservingMatrix $ do
    if menuCursor==1 then color $ Color3 (1.0::Double) 1.0 0 else color $ Color3 (1.0::Double) 1.0 1.0
    translate $ Vector3 (70::Double) (-200) 0
    scale (0.2::Double) 0.2 0.3
    renderStringGrad Roman 60 $ (if menuCursor==1 then ">" else " ") ++ "Continue " ++ (show.fst.saveState) vars++ "-" ++ (show.(+1).snd.saveState) vars
  color $ Color3 (1.0::Double) 1.0 1.0
     
  preservingMatrix $ do
    translate $ Vector3 (-250::Double) (75) 0
    scale (0.15::Double) 0.10 0.15  
    renderStringGrad Roman 10 "Dedicated to the makers, the players, the history," 
  preservingMatrix $ do
    translate $ Vector3 (-250::Double) (55) 0
    scale (0.15::Double) 0.10 0.15      
    renderStringGrad Roman  20 "  and the 20th anniversary of GRADIUS series." 
  mapM_ (\ (y,(strA,strB),i) -> preservingMatrix $ do
    preservingMatrix $ do
      translate $ Vector3 (-180::Double) y 0 
      scale (0.18::Double) 0.18 0.2 
      renderStringGrad Roman (20 + i*5) strA 
    preservingMatrix $ do  
      translate $ Vector3 (60::Double) y 0
      scale (0.18::Double) 0.18 0.2
      renderStringGrad Roman (25 + i*5) strB 
    ) $ zip3 [0,(-35)..] instructions [1..] 
       
  swapBuffers   

  if Char ' ' `elem` keystate && clock >= timeLimit then 
     if menuCursor == 0 then 
       gameStart 1 0 False (recorderMode vars) vars
     else 
       gameStart savedLevel savedArea (isCheat vars) (recorderMode vars) vars
   else if isJust $ getNumberKey keystate then
      gameStart (fromJust $ getNumberKey keystate) 0 True (recorderMode vars) vars
    else return $ Scene $ openingProc (clock+1) (nextCursor keystate) vars ks 
  where 
    
     instructions = [("Move","Arrow Keys"),("Shot","Z Key"),("Missile","X Key"),("Power Up","C Key"),("Start","Space Bar")] 
     timeLimit = 30
     renderStringGrad font delay str = renderString font (take (((clock-delay) * length str) `div` timeLimit) str) 
     getNumberKey keystate = foldl mplus Nothing $ map keyToNumber keystate
     keyToNumber::Key->Maybe Int
     keyToNumber k = case k of
       Char c -> if c>='0' && c<='9' then Just $ fromEnum c - fromEnum '0' else Nothing
       _      -> Nothing
     gameStart level area ischeat recordermode vars= do
       -- it is possible to temporary set (recordermode /= recorderMode vars)
       gs <- newIORef $ initialRecorder recordermode (playbackKeys vars) (initialMonadius GameVariables{
       totalScore=0, flagGameover=False,  hiScore=saveHiScore vars,
       nextTag=0, gameClock = savePoints!!area ,baseGameLevel = level,
       playTitle = if recordermode /= Playback then Nothing else playBackName vars}) 
       --runCommand "stage1.mp3"         
       return $ Scene $ mainProc vars{isCheat=ischeat,recordSaveState=(level,area)} gs ks
     (savedLevel,savedArea) = saveState vars
     demoStart vars = do
       let i = demoIndex vars       
       let ReplayInfo ((lv,area),dat) = demoData!!i
       gameStart lv area (isCheat vars) Playback vars{
         playBackName = Just "Press Space",
         playbackKeys = decode dat,
         demoIndex = demoIndex vars+1
       }
     nextCursor keys = 
       if SpecialKey KeyLeft `elem` keys then 0 else 
       if SpecialKey KeyRight `elem` keys then 1 else 
       menuCursor
     delayVertices clock vs = (reverse.take clock.reverse) vs
     lambdaLfoot = moreVertices $ [10:+55,(-15):+0] ++ map (\(x:+y)->((-x):+y)) wing
     lambdaRfoot = moreVertices $ [(-15):+70,(-12):+77,(-5):+80,(2:+77),(5:+70)] ++ wing
     shine t = monoshine (drawCompleteTime + t) + monoshine (drawCompleteTime + t+6)
     monoshine t = exp(-0.2*intToDouble(t`mod` 240))
     drawCompleteTime = length lambdaRfoot

     moreVertices (a:b:cs) = if magnitude (a-b) > d then moreVertices (a:((a+b)/(2:+0)):b:cs) else a:moreVertices(b:cs) 
       where d=6
     moreVertices x = x
       
     wing = [(30:+0),(200:+0),(216:+16),(208:+24),(224:+24),(240:+40),(232:+48),(248:+48),(272:+72),(168:+72)]
     renderVertices2D::[Complex Double]->IO ()
     renderVertices2D xys = mapM_ (\(x:+y)->vertex $ Vertex3 x y 0) xys

     demoStartTime = if presentationMode then 480 else 1800


           
endingProc :: GlobalVariables->IORef [Key] -> IORef Double -> IO Scene
endingProc vars ks ctr= do
  keystate <- readIORef ks 
  counter <- readIORef ctr
  modifyIORef ctr (min 2420.(+2.0))
  clear [ColorBuffer,DepthBuffer]
  matrixMode $= Modelview 0
  loadIdentity

  if counter < 2 then playMusic Ending else return ()

  color $ Color3 (1.0::Double) 1.0 1.0
  zipWithM_ (\str pos -> preservingMatrix $ do
    translate $ Vector3 (-180::Double) (-240+counter-pos) 0
    scale (0.3::Double) 0.3 0.3
    renderString Roman str) 
    stuffRoll [0,60..]

  swapBuffers     

  if Char ' ' `elem` keystate then do
      --gs <- newIORef (initialState::Monadius)
      return $ Scene $ openingProc 0 1 vars ks
   else return $ Scene $ endingProc vars ks ctr

  where
    stuffRoll = [
     "", 
     "",
     "Game Designer",  
     "    nushio",
     "", 
     "Frame Programmer",
     "    tanakh", 
     "",  
     "Graphics Designer",
     "    Just nushio",  
     "",         
     "Sound Designer",
     "    Match Makers",  
     "",         
     "Lazy Evaluator",
     "    GHC 6.4",      
     "", 
     "Inspired"   ,  
     "    Ugo-Tool",
     "    gradius2.com",
     "    Gradius series",
     "",
     "Special thanks to",
     "    John Peterson",
     "    Simon Marlow",
     "    Haskell B. Curry",
     "    U.Glasgow",
     "",     
     "Presented by",
     "    team combat",   
     "",  
     "",
     "", 
     "",
     "",
     if (fst.saveState) vars <= 2 then "Congratulations!" else "WE LOVE GAMES!!" ,
     "", 
     "    press space key"]
mainProc::GlobalVariables -> IORef Recorder -> IORef [Key] -> IO Scene
mainProc vars gs ks = do
  keystate <- readIORef ks
  modifyIORef gs (update keystate)
  gamestate <- readIORef gs
  
  clear [ColorBuffer,DepthBuffer]
  matrixMode $= Modelview 0 
  loadIdentity
  render gamestate    
  swapBuffers
  let (savedLevel,savedArea) = saveState vars
  let currentLevel = baseGameLevel$getVariables$gameBody gamestate
  let currentArea = maximum $ filter (\i -> (savePoints!!i) < (gameClock$getVariables$gameBody gamestate)) [0..(length savePoints-1)]
  let currentSave = if mode gamestate == Playback then saveState vars else (currentLevel,currentArea)
  let currentHi = max (saveHiScore vars) (hiScore$getVariables$gameBody gamestate)
  if (isGameover gamestate) then do 
      counter <- newIORef (0.0::Double) 
      if mode gamestate /= Record then return () else do
        writeReplay vars gamestate $ show (ReplayInfo (recordSaveState vars,(encode2.preEncodedKeyBuf) gamestate))
        
      
      if currentLevel>1 && (not.isCheat) vars && (mode gamestate /= Playback) then 
        return $ Scene $ endingProc vars{saveState=currentSave,saveHiScore = currentHi} ks counter
       else return $ Scene $ openingProc 0 1 vars{saveState=currentSave,saveHiScore = currentHi} ks
    else return $ Scene $ mainProc vars{saveState=currentSave,saveHiScore = currentHi} gs ks  

  where
    writeReplay vars gamestate str = do
      createDirectoryIfMissing True "replay"
      filename <- serachForNewFile (
          "replay\\" ++ (showsave.recordSaveState) vars ++ "-" ++ (showsave.saveState) vars ++ "." ++
          ((padding '0' 8).show.totalScore.getVariables.gameBody) gamestate ++ "pts" 
        ) 0
      writeFile filename str
    showsave (a,b) = show (a,b+1)
    serachForNewFile prefix i = do
      let fn = prefix ++ (uniqStrs!!i) ++ replayFileExtension
      b <- doesFileExist fn
      if not b then return fn else do
        serachForNewFile prefix $  i+1
    uniqStrs = (""):(map (("."++).show) [1..])
      
      

timerProc m = addTimerCallback 16 (timerProc m) >> m

keyProc keystate key ks mod pos =
  case (key,ks) of
    (Char 'q',_) -> exitLoop
    (Char '\ESC',_) -> exitLoop
    (_,Down) -> modifyIORef keystate (nub.(++[key]))
    (_,Up) -> modifyIORef keystate (filter (/=key))


closeProc = do
  putDebugStrLn "closed"
  throwIO $ ExitException ExitSuccess
  

savePoints = [0,1280,3000,6080]

 