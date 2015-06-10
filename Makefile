override CARGS+=-j2

#Installs
all:
	cabal install --ghcjs $(CARGS)
