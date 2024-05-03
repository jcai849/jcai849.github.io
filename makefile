.SUFFIXES: .html .html.m4 .svg .svg.vcf .html.xq
.PHONY: clean

all: index.html

index.html: contact.html positions.html skills.html awards.html qualifications.html
contact.html: vcard.svg

.svg.vcf.svg:
	qrencode -tsvg -r"$<" >"$@"
.html.m4.html:
	m4 "$<" >"$@"
.html.xq.html:
	basex "$<" >"$@"

clean:
	rm -rf index.html
	rm -rf awards.html
	rm -rf positions.html
	rm -rf *.svg
