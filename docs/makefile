.PHONY: all
TEX-ALL-SRC != find src -maxdepth 1 -name '*.tex' -exec basename {} \;
TEX-ALL-OUT = ${TEX-ALL-SRC:S/.tex/.html/g}
PFLAGS = -c style/style.css -t html -s
TL-PFLAGS = -f markdown --template src/template.html

all: ${TEX-ALL-OUT} index.html

index.html: ${TEX-ALL-OUT}
	./bin/make-index ${.ALLSRC} | pandoc ${PFLAGS} ${TL-PFLAGS} >${.TARGET}

.for TEX-SRC in ${TEX-ALL-SRC}
TEX-OUT = ${TEX-SRC:S/.tex/.html/g}
${TEX-OUT}: src/${TEX-SRC}
	cd src && ${MAKE} PFLAGS=${PFLAGS:Q} ${TEX-OUT} && mv ${TEX-OUT} ..
.endfor
