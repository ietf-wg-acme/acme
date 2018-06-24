# Automatic Certificate Management Environment (ACME)

This is the working area for the Working Group internet-draft, "Automatic Certificate Management Environment (ACME)".

* [Editor's copy](https://ietf-wg-acme.github.io/acme/)
* [Build history](https://circleci.com/gh/ietf-wg-acme/acme)
* [Working Group Draft](https://tools.ietf.org/html/draft-ietf-acme-acme)


## Contributing

Before submitting feedback, please familiarize yourself with our current issues
list and review the [working group
documents](https://datatracker.ietf.org/wg/acme/documents/) and [mailing
list discussion](https://mailarchive.ietf.org/arch/browse/acme/). If you're
new to this, you may also want to read the [Tao of the
IETF](https://www.ietf.org/tao.html).

Be aware that all contributions to the specification fall under the "NOTE WELL"
terms outlined below.

1. The best way to provide feedback (editorial or design) and ask questions is
sending an e-mail to our mailing list
([info](https://www.ietf.org/mailman/listinfo/acme)). This will ensure that
the entire Working Group sees your input in a timely fashion.

2. If you have **editorial** suggestions (i.e., those that do not change the
meaning of the specification), you can either:

  a) Fork this repository and submit a pull request; this is the lowest
  friction way to get editorial changes in.

  b) Submit a new issue to GitHub, and mention that you believe it is editorial
  in the issue body. It is not necessary to notify the mailing list for
  editorial issues.

  c) Make comments on individual commits in GitHub. Note that this feedback is
  processed only with best effort by the editors, so it should only be used for
  quick editorial suggestions or questions.

3. For non-editorial (i.e., **design**) issues, you can also create an issue on
GitHub. However, you **must notify the mailing list** when creating such issues,
providing a link to the issue in the message body.

  Note that **GitHub issues are not for substantial discussions**; the only
  appropriate place to discuss design issues is on the mailing list itself.


## Building the Draft

Formatted text and HTML versions of the draft can be built using `make`.

```sh
$ make
```

This requires that you have the necessary software installed.  There are several
other tools that are enabled by make, check the Makefile for details, including
links to the software those tools might require.


## Installation and Setup

Mac users will need to install
[Xcode](https://itunes.apple.com/us/app/xcode/id497799835) to get `make`, see
[this answer](http://stackoverflow.com/a/11494872/1375574) for instructions.

Windows users will need to use [Cygwin](http://cygwin.org/) to get `make`.

All systems require [xml2rfc](http://xml2rfc.ietf.org/).  This
requires [Python](https://www.python.org/).  The easiest way to get
`xml2rfc` is with `pip`.

Using a `virtualenv`:

```sh
$ virtualenv --no-site-packages venv
# remember also to activate the virtualenv before any 'make' run
$ source venv/bin/activate
$ pip install xml2rfc
```

To your local user account:

```sh
$ pip install --user xml2rfc
```

Or globally:

```sh
$ sudo pip install xml2rfc
```

xml2rfc depends on development versions of [libxml2](http://xmlsoft.org/) and
[libxslt1](http://xmlsoft.org/XSLT).  These packages are named `libxml2-dev` and
`libxslt1-dev` (Debian, Ubuntu) or `libxml2-devel` and `libxslt1-devel` (RedHat,
Fedora).

If you use markdown, you will also need to install `kramdown-rfc2629`,
which requires Ruby and can be installed using the Ruby package
manager, `gem`:

```sh
$ gem install kramdown-rfc2629
```

Some other helpful tools are listed in `config.mk`.


## NOTE WELL

Any submission to the [IETF](https://www.ietf.org/) intended by the Contributor
for publication as all or part of an IETF Internet-Draft or RFC and any
statement made within the context of an IETF activity is considered an "IETF
Contribution". Such statements include oral statements in IETF sessions, as
well as written and electronic communications made at any time or place, which
are addressed to:

 * The IETF plenary session
 * The IESG, or any member thereof on behalf of the IESG
 * Any IETF mailing list, including the IETF list itself, any working group
   or design team list, or any other list functioning under IETF auspices
 * Any IETF working group or portion thereof
 * Any Birds of a Feather (BOF) session
 * The IAB or any member thereof on behalf of the IAB
 * The RFC Editor or the Internet-Drafts function

All IETF Contributions are subject to the rules of
   [RFC 5378](https://tools.ietf.org/html/rfc5378) and
   [RFC 3979](https://tools.ietf.org/html/rfc3979)
   (updated by [RFC 4879](https://tools.ietf.org/html/rfc4879)).

Statements made outside of an IETF session, mailing list or other function,
that are clearly not intended to be input to an IETF activity, group or
function, are not IETF Contributions in the context of this notice.

Please consult [RFC 5378](https://tools.ietf.org/html/rfc5378) and [RFC
3979](https://tools.ietf.org/html/rfc3979) for details.

A participant in any IETF activity is deemed to accept all IETF rules of
process, as documented in Best Current Practices RFCs and IESG Statements.

A participant in any IETF activity acknowledges that written, audio and video
records of meetings may be made and may be available to the public.
