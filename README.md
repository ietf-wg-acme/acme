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

6. Remove the unnecessary template files.

```sh
$ git rm template.md template.xml
```

7. Move the README.md template into place.

```sh
$ git rm README.md
$ git mv README-template.md README.md
```

8. Edit the README.md and CONTRIBUTING.md files.

```sh
$ vi README.md CONTRIBUTING.md
# ...
$ git add README.md CONTRIBUTING.md
```

8. Commit and push

```sh
$ git commit -am "Initial commit"
$ git push
```


### Setting Up The Editor's Copy

This requires that you sign in with [Travis](https://travis-ci.org/).

While you are there, enable builds for the new repository.

You also need the travis command line tools, which is a Ruby script:

```sh
$ sudo gem install travis
```

Then, you need to get yourself a [new Github application token](https://github.com/settings/tokens/new).
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

