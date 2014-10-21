# In case your system doesn't have any of these tools:
# https://pypi.python.org/pypi/xml2rfc
# https://github.com/cabo/kramdown-rfc2629
# https://github.com/Juniper/libslax/tree/master/doc/oxtradoc
# https://tools.ietf.org/tools/idnits/

xml2rfc ?= xml2rfc
kramdown-rfc2629 ?= kramdown-rfc2629
oxtradoc ?= oxtradoc.in
idnits ?= idnits
rfcdiff ?= rfcdiff --browse

draft := $(basename $(lastword $(sort $(wildcard draft-*.xml)) $(sort $(wildcard draft-*.org)) $(sort $(wildcard draft-*.md))))

ifeq (,$(draft))
$(warning No file named draft-*.md or draft-*.xml or draft-*.org)
$(error Read README.md for setup instructions)
endif

draft_type := $(suffix $(firstword $(wildcard $(draft).md $(draft).org $(draft).xml)))

current_ver := $(shell git tag | grep '$(draft)-[0-9][0-9]' | tail -1 | sed -e"s/.*-//")
ifeq (,$(current_ver))
next_ver ?= 00
else
next_ver ?= $(shell printf "%.2d" $$((1$(current_ver)-99)))
endif
next := $(draft)-$(next_ver)
diff_ver := $(draft)-$(current_ver)

.PHONY: latest submit diff clean update

latest: $(draft).txt $(draft).html

submit: $(next).txt

idnits: $(next).txt
	$(idnits) $<

clean:
	-rm -f $(draft).txt $(draft).html index.html
	-rm -f $(addprefix $(draft)-[0-9][0-9].,xml md org html txt)
	-rm -f *.diff.html
ifneq (xml,$(draft_type))
	-rm -f $(draft).xml
endif

$(next).xml: $(draft).xml
	sed -e"s/$(basename $<)-latest/$(basename $@)/" $< > $@

ifneq (,$(current_ver))
.INTERMEDIATE: $(addprefix $(draft)-$(current_ver),.txt $(draft_type))
diff: $(draft).txt $(draft)-$(current_ver).txt
	-$(rfcdiff) $^

$(draft)-$(current_ver)$(draft_type):
	git show $(draft)-$(current_ver):$(draft)$(draft_type) > $@
endif

.INTERMEDIATE: $(draft).xml
%.xml: %.md
	$(kramdown-rfc2629) $< > $@

%.xml: %.org
	$(oxtradoc) -m outline-to-xml -n "$@" $< > $@

%.txt: %.xml
	$(xml2rfc) $< -o $@ --text

ifeq (Darwin, $(shell uname -s 2>/dev/null))
sed_i := sed -i ''
else
sed_i := sed -i
endif

%.html: %.xml
	$(xml2rfc) $< -o $@ --html
	$(sed_i) -f lib/addstyle.sed $@

### Update this Makefile

# The prerequisites here are what is updated
update: Makefile lib .gitignore
	git diff --quiet $^ || \
	  (echo "You have uncommitted changes to:" $^ 1>&2; exit 1)
	git remote | grep i-d-template > /dev/null || \
	  git remote add i-d-template https://github.com/martinthomson/i-d-template.git
	git fetch i-d-template
	git checkout i-d-template/master $^
	git diff --quiet $^ || \
	  git commit -m "Update of $^ from i-d-template/$$(git rev-parse i-d-template/master)" $^

### Below this deals with updating gh-pages

GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
.TRANSIENT: $(GHPAGES_TMP)
ifeq (,$(TRAVIS_COMMIT))
GIT_ORIG := $(shell git branch | grep '*' | cut -c 3-)
else
GIT_ORIG := $(TRAVIS_COMMIT)
endif

# Only run upload if we are local or on the master branch
IS_LOCAL := $(if $(TRAVIS),,true)
ifeq (master,$(TRAVIS_BRANCH))
IS_MASTER := $(findstring false,$(TRAVIS_PULL_REQUEST))
else
IS_MASTER :=
endif

index.html: $(draft).html
	cp $< $@

ghpages: index.html $(draft).txt
ifneq (,$(or $(IS_LOCAL),$(IS_MASTER)))
	mkdir $(GHPAGES_TMP)
	cp -f $^ $(GHPAGES_TMP)
	git clean -qfdX
ifeq (true,$(TRAVIS))
	git config user.email "ci-bot@example.com"
	git config user.name "Travis CI Bot"
	git checkout -q --orphan gh-pages
	git rm -qr --cached .
	git clean -qfd
	git pull -qf origin gh-pages --depth=5
else
	git checkout gh-pages
	git pull
endif
	mv -f $(GHPAGES_TMP)/* $(CURDIR)
	git add $^
	if test `git status -s | wc -l` -gt 0; then git commit -m "Script updating gh-pages."; fi
ifneq (,$(GH_TOKEN))
	@echo git push https://github.com/$(TRAVIS_REPO_SLUG).git gh-pages
	@git push https://$(GH_TOKEN)@github.com/$(TRAVIS_REPO_SLUG).git gh-pages
endif
	-git checkout -qf "$(GIT_ORIG)"
	-rm -rf $(GHPAGES_TMP)
endif
