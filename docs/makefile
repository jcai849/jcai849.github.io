PFLAGS = -st html5 --template ../templates/template.html5 -c ../style/style.css
PFLAGSMD = -F pandoc-crossref -NC --metadata-file=../templates/metadata.yaml ${PFLAGS}
DOCS != find . -name '*.md' -exec basename {} \;
OUT   = ${DOCS:S/.md/.html/g}

.PHONY: all clean

all: ${OUT} index.html

index.html: ${OUT} ../templates/docs-index
	printf "%s\n\n%s" "`cat ../templates/docs-index`" "`../bin/make-index ${OUT}`" |\
	pandoc ${PFLAGS} -f markdown >${.TARGET}

.SUFFIXES: .html .md .svg .gv .puml .mk
.md.html:
	pandoc ${PFLAGSMD} ${.IMPSRC} >${.TARGET}
.puml.svg: ../bin/plantuml.jar
	java -jar ../bin/plantuml.jar ${.IMPSRC} -tsvg
.gv.svg:
	dot -Tsvg ${.IMPSRC} >${.TARGET}
clean:
	rm -f *.html
	rm -f *.svg
.mk.gv:
	gmake -Bnd -k -f ${.IMPSRC} 2>/dev/null | ../bin/makefile2graph/make2graph >${.TARGET}
