LIBDIR := lib
include $(LIBDIR)/main.mk

$(LIBDIR)/main.mk:
ifneq (,$(shell grep "path *= *$(LIBDIR)" .gitmodules 2>/dev/null))
	git submodule sync
	git submodule update $(CLONE_ARGS) --init
else
	git clone -q --depth 10 $(CLONE_ARGS) \
	    -b master https://github.com/martinthomson/i-d-template $(LIBDIR)
endif

.PHONY: rfced
rfced::
	kramdown-rfc2629 draft-ietf-acme-acme.md >rfced/draft-ietf-acme-acme.xml
	cd rfced && python clean-xml.py <draft-ietf-acme-acme.xml >draft-ietf-acme-acme.clean.xml
	-cd rfced && diff -u draft-ietf-acme-acme.clean.xml rfc8555.edited.xml >curr.diff
