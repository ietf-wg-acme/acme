include lib/main.mk

lib/main.mk:
ifneq (,$(shell git submodule status lib 2>/dev/null))
	git submodule sync
	git submodule update --init
else
	git clone --depth 10 -b master https://github.com/martinthomson/i-d-template.git lib
endif

.PHONY: rfced
rfced::
	kramdown-rfc2629 draft-ietf-acme-acme.md >rfced/draft-ietf-acme-acme.xml
	cd rfced && python clean-xml.py <draft-ietf-acme-acme.xml >draft-ietf-acme-acme.clean.xml
	cd rfced && diff draft-ietf-acme-acme.clean.xml rfc8555.xml >curr.diff
