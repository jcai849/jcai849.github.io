# Need cabal, graphviz, java, jq, curl
PFLAGS = -st html5 -fmarkdown+hard_line_breaks
.SUFFIXES: .html .md
.md.html:
	pandoc ${PFLAGS} ${.IMPSRC} >${.TARGET}
.PHONY: all research cv clean

all: research cv

research:
	cd research && $(MAKE)

cv: cv.html

clean:
	cd research && $(MAKE) clean
