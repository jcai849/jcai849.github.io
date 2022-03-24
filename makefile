# Need cabal, graphviz, java, jq, curl
PFLAGS = -st html5 -fmarkdown+hard_line_breaks
.SUFFIXES: .html .md
.md.html:
	pandoc ${PFLAGS} ${.IMPSRC} >${.TARGET}
.PHONY: all research docs cv clean pandoc pandoc-crossref

all: research cv docs
research docs: bin/plantuml.jar bin/makefile2graph/make2graph
	cd ${.TARGET} && $(MAKE)
cv: cv.html
clean:
	cd research && $(MAKE) clean
	cd docs && $(MAKE) clean

pandoc-crossref: pandoc
	cabal install pandoc-crossref
pandoc:
	cabal install pandoc
bin/plantuml.jar:
	curl -s https://api.github.com/repos/plantuml/plantuml/releases/latest |\
	jq -r .assets[].browser_download_url |\
	grep '[0-9].jar$'' |\
	sed 1q |\
	xargs curl -sLo bin/plantuml.jar
bin/makefile2graph/make2graph:
	cd bin/makefile2graph && gmake
