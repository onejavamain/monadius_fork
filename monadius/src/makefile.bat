windres -O coff monadius.rc monadius.res
ghc -c stub.c
ghc --make Main monadius.res stub.o -o monadius -O -optl-mwindows -lwinmm
