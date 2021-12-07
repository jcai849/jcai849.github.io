# Need cabal, graphviz, java, jq, curl
PFLAGS = -st html5 --template template.html5 -c style/style.css
PFLAGSMD = -F pandoc-crossref -NC --metadata-file=metadata.yaml ${PFLAGS}
DOCS != find . -name '*.md' -exec basename {} \;
OUT   = ${DOCS:S/.md/.html/g}

.PHONY: all

all: ${OUT} index.html

index.html: ${OUT} research-index
	printf "%s\n\n%s" "`cat research-index`" "`./bin/make-index ${OUT}`" |\
	pandoc ${PFLAGS} -f markdown >${.TARGET}

pandoc-crossref: pandoc
	cabal install pandoc-crossref
pandoc:
	cabal install pandoc
bin/plantuml.jar:
	curl -s https://api.github.com/repos/plantuml/plantuml/releases/latest |\
	jq -r .assets[].browser_download_url |\
	tail -n1 |\
	xargs curl -sLo bin/plantuml.jar

.SUFFIXES: .html .md .svg .gv .puml
.md.html:
	pandoc ${PFLAGSMD} ${.IMPSRC} >${.TARGET}
.puml.svg: bin/plantuml.jar
	java -jar bin/plantuml.jar ${.IMPSRC} -tsvg
.gv.svg:
	dot -Tsvg ${.IMPSRC} >${.TARGET}
