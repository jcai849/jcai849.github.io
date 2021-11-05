BL-PFLAGS = --template template.html
.SUFFIXES:
.SUFFIXES: .tex .html

.tex.html:
	pandoc ${BL-PFLAGS} ${PFLAGS} ${.IMPSRC} -o ${.TARGET}
