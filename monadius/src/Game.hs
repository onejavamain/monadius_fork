module Game(
  Game(..)
)where
  
import Graphics.UI.GLUT.Callbacks.Window 
 
-- an abstracted game as a state machine.

class Game g where
  update::[Key]->g->g
  render::g->IO ()
  isGameover::g->Bool

