.SUFFIXES: .html .svg .svg.vcf .html.xq
.PHONY: clean

all: index.html

index.html: contact.html positions.html skills.html awards.html qualifications.html
contact.html: vcard.svg

.svg.vcf.svg:
	qrencode -tsvg -r"$<" >"$@"
.html.xq.html:
	basex -w -s method=html "$<" >"$@"

clean:
	rm -rf index.html
	rm -rf awards.html
	rm -rf positions.html
	rm -rf *.svg
