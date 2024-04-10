.SUFFIXES: .csv .html.tab .html .html.m4
.PHONY: clean

all: index.html
index.html: education.html.tab

.csv.html.tab:
	(echo .import --csv "$<" tmp; echo 'select * from tmp;' ) | sqlite3 -header -html >"$@"

.html.m4.html:
	m4 "$<" >"$@"

clean:
	rm -rf *.html
