# Internet Draft Template Repository

The contents of this repository can be used to get started with a new
internet draft.

## Getting Started

This all assumes that you have an [account](https://github.com/join) with Github.

### Working Group Setup

Make a [new organization](https://github.com/organizations/new) for your working group.  
This guide will use the name `unicorn-wg` for your working group.

### New Draft Setup

1. [Make a new repository](https://github.com/new).  This guide will use the name
   name `unicorn-protocol` here.

2. Clone that repository:

```sh
$ git clone https://github.com/unicorn-wg/unicorn-protocol.git
```

3. Copy the contents of this respository in:

```sh
$ git pull https://github.com/martinthomson/i-d-template.git master
```

4. Choose whether you want to use markdown or xml as your input form. 
   If you already have a draft, then that decision is already made for you.

5. Move the template file into place.

```sh
$ git mv template.md draft-ietf-unicorn-protocol.md
```

   Or add an existing file.

```sh
$ git add draft-ietf-unicorn-protocol.xml
````

6. Edit the draft so that it has the right name.  This template uses
   the `-latest` suffix in place of the usual number ('-00', or '-08').
   
```xml
   <rfc docName="draft-ietf-unicorn-protocol-latest" category="std">
```

   Or in markdown:

```yaml
docname: draft-ietf-unicorn-protocol-latest
```

7. Remove the unnecessary template files.

```sh
$ git rm template.md template.xml
```

8. Move the README.md template into place.

```sh
$ git rm README.md
$ git mv README-template.md README.md
```

9. Edit the README.md and CONTRIBUTING.md files.

```sh
$ vi README.md CONTRIBUTING.md
# ...
$ git add README.md CONTRIBUTING.md
```

10. Commit and push

```sh
$ git commit -am "Initial commit"
$ git push
```


### Setting Up The Editor's Copy

Github uses the `gh-pages` branch as source for a project web page.
This branch needs to be initialized first.

```sh
$ git checkout --orphan gh-pages
$ git rm -rf .
$ touch index.html
$ git add index.html
$ git commit
$ git push
```

You can maintain `gh-pages` manually by running the following
command occasionally.

```sh
$ make ghpages
```

### Automatic Update for Editor's Copy

This requires that you sign in with [Travis](https://travis-ci.org/).

While you are there, enable builds for the new repository.

You also need the travis command line tools, which is a Ruby script:

```sh
$ sudo gem install travis
```

Then, you need to get yourself a
[new Github application token](https://github.com/settings/tokens/new).
You might want to use a dummy account for this purpose.

The application token only needs the `public_repo` privilege.
This will let it push updates to your `gh-pages` branch.

Then, you update the Travis configuration file with an encrypted
copy of that token, as follows:

```sh
$ travis encrypt GH_TOKEN=<YOUR TOKEN HERE> -a -p
$ git add .travis.yml
$ git commit -m "Updating Travis configuration" .travis.yml
$ git push
```

As a side benefit, Travis will now also check pull requests for
compilation errors, letting you know if things didn't work out.

## Submitting Drafts

Occasionally, you will want to submit versions of your draft to the
official IETF repository.  The following process makes this easy.

1. Make a submission version of your draft.  The makefile uses git
   tags to work out what version to create.

```sh
$ make submit
```

2. [Submit the .txt and .xml files](https://datatracker.ietf.org/submit/)
   that this produces.

3. Tag your repository and upload the tags.  The tag you should use
   is your draft name with the usual number in place of `-latest`.

```sh
$ git tag draft-ietf-unicorn-protocol-03
$ git push --tags
```

You can setup Travis to produce a release in Github based on tags.
See `.travis.yml` for a details.
