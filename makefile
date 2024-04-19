.SUFFIXES: .html .html.m4 .svg .svg.vcf
.PHONY: clean

all: index.html

index.html: contact.html work.html skills.html awards.html education.tab.html
contact.html: vcard.svg

.svg.vcf.svg:
	qrencode -tsvg -r"$<" >"$@"
.html.m4.html:
	m4 "$<" >"$@"

clean:
	rm -rf index.html
	rm -rf *.svg
