module Util (
  filterJust,
  Shape(..),
  ComplexShape(..)  ,
  modifyArray,
  intToDouble,
  unitVector,
  regulate,
  angleAccuracy,
  innerProduct,
  isDebugMode,putDebugStrLn,
  padding
) where
 
import System.IO 
import Data.Maybe
import Data.Complex
import Data.Array

isDebugMode = False
-- switch this True to get debug outputs. be careful you get a crash in windows mode, because the conole is not present.

putDebugStrLn str = if isDebugMode then putStrLn str else return ()



filterJust::[Maybe a]->[a]
filterJust = map fromJust.filter isJust

modifyArray::Ix i=>i->(e->e)->Array i e->Array i e
modifyArray i f a = a // [(i,f $ a!i)]  -- modify array a at index i by function f

class ComplexShape s where
  (>?<)::s->s->Bool            -- collision check
  (+>)::(Complex Double)->s->s -- translation by a vector

instance ComplexShape Shape where
  a >?< b = case (a,b) of
    (Circular{},Circular{}) -> magnitude (center a - center b) < radius a + radius b 
    (Circular{},Rectangular{}) -> b >?< a
    (Rectangular{},Circular{}) -> a >?< Rectangular{bottomLeft = center b - vr,topRight = center b + vr} where
      vr = radius b :+ radius b
    (Rectangular{bottomLeft=aL:+aB,topRight=aR:+aT},Rectangular{bottomLeft=bL:+bB,topRight=bR:+bT}) -> 
      and [aL < bR, aB < bT, aR > bL, aT > bB]
    (Shapes{children = ss}, b) -> or $ map (>?< b)  ss
    (a, Shapes{children = ss}) -> or $ map (a >?<)  ss
  v +> a = case a of
    Circular{}    -> a{center = center a + v}
    Rectangular{} -> a{bottomLeft = bottomLeft a + v, topRight = topRight a + v}
    Shapes{}      -> a{children = map (v +>) $ children a}

data Shape = Circular {center::Complex Double, radius::Double} | 
             Rectangular {bottomLeft::Complex Double, topRight::Complex Double} | 
             Shapes {children::[Shape]}

regulate::Shape->Shape -- put a Rectangle coordinates into normal order so that collision will go properly.
regulate Rectangular{bottomLeft=(x1:+y1),topRight=(x2:+y2) }= Rectangular (min x1 x2:+min y1 y2) (max x1 x2:+max y1 y2)
regulate ss@Shapes{} = ss{children = map regulate $ children ss}
regulate x = x


intToDouble::Int->Double
intToDouble = fromInteger.toInteger 

integerToDouble::Integer->Double
integerToDouble = fromInteger.toInteger

unitVector::Complex Double->Complex Double
unitVector z | magnitude z <= 0.00000001 = 1:+0
            | otherwise                 = z / abs z
            
angleAccuracy::Int->Complex Double->Complex Double
angleAccuracy division z = mkPolar r theta where
  (r,t)=polar z
  theta = (intToDouble $ round (t / (2*pi) * d))/d*2*pi
  d = intToDouble division

innerProduct::Complex Double->Complex Double->Double
innerProduct a b = realPart $ a * (conjugate b)

padding::Char->Int->String->String
padding pad minLen str = replicate (minLen - length str) pad ++ str



