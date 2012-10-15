# Proto

[Proto](https://github.com/droptype/proto) is a front-end web prototyping tool, combining markup ([Jade](http://jade-lang.com/)), script ([CoffeeScript](http://coffeescript.org)), and style ([Stylus](http://learnboost.github.com/stylus/)) into a single page. It creates a set of files each representing one of those three facets of the page, plus files for notes and settings, and serves up their rendered form. Every time the page is loaded, those files are compiled on-the-fly. It's helpful for creating prototypes using CoffeeScript, Jade, and Stylus, without having to set up a build process and environment.

See [this Marquee post](http://marquee.by/alecperkins/proto/) for an explanation of the motivation, as well as a walkthrough.

## Installation

Proto is a command-line tool built in [Node](http://nodejs.org/), specifically [CoffeeScript](http://coffeescript.org), and is available through [npm](https://npmjs.org/).

    npm install -g proto-cli

or from source

    git clone git://github.com/droptype/proto.git
    cd proto
    cake build
    npm install -g .

`cake build` will compile `src/proto.coffee` into `lib/proto.js` (ignored by git).

Proto needs to be installed globally using `-g` so it can create the necessary command in `/usr/local/bin`.


## Usage

### Init

    proto -i <project_name>

Initializes the project by creating a folder with the specified name and adding five files: `markup.jade`, `script.coffee`, `style.styl`, `settings.json`, and `notes.md`.

e.g. `proto -i my_project` creates a folder called `my_project` in the current working directory

    my_project/
        markup.jade       - the source for the markup code
        script.coffee     - the source for the script code
        style.styl        - the source for the style code
        settings.json     - settings for the project, specifically extra libraries to include into the page
        notes.md          - a place for extra notes


### Work on a project

To serve the project at [localhost:5000](http://localhost:5000):

    proto <project_name>

Or specify a port:

    proto <project_name> -p 8080

This starts a server that serves the compiled markup, script, and style on the specified port (default 5000). The source files are compiled every time the page is requested.

The source files are compiled and inserted into a full `html` template. Libraries specified in `settings.json`, and the CSS compiled from `style.styl`, are added to the `<head>` of the page. `markup.jade` gets compiled to HTML and inserted into the `<body>`, and `script.coffee` gets compiled to JavaScript and added to the end of the `<body>`. (Take a peak at the Proto source for the [full template](https://github.com/droptype/proto/blob/master/src/proto.coffee#L287) it uses.)

To have additional libraries loaded, add them to the `script_libraries` or `style_libraries`. They must be served from somewhere else, like a [CDN](http://cdnjs.com/).


### Gist a project

To create a GitHub [Gist](https://gist.github.com) with the project's contents:

    proto -g <project_name>
    proto -g <project_name> --public

This will upload the five files in the specified project folder to an anonymous Gist. By default, the Gist is private. Adding the `--public` flag will make it a public Gist. But, anonymous Gists aren't terribly useful besides one-off sharing, so *Authenticated* Gists are recommended.

#### Authenticated

To create the Gist under your username, first authenticate with GitHub using:

    proto --github <username> <password>
    proto --github <username> "<password with spaces>"

This will use the GitHub API to [generate an access token](http://developer.github.com/v3/oauth/#create-a-new-authorization) that is stored in `~/.proto-cli`. Your username and password are *never* stored.

Now, all Gists you create will be associated with your account. This has several benefits, including making the Proto project a git repo with the remote set to the Gist, so you can keep updating the Proto's Gist. Using `proto -g <project_name>` on a project that has already been Gisted with authentication will commit and push your changes to the same Gist, instead of creating a new one.


## FAQ

### Why not LiveReload?

[LiveReload](http://livereload.com/) is awesome and works great — in fact it works really well alongside Proto — but doesn't serve the files (and nor should it). Certain JavaScript features require the file to be served instead of loaded using `file://` for security reasons. Proto is simpler to use and provides an easy way to initialize the project. It is also intended to be opinionated about the languages and structure it supports, creating simplicity through useful defaults.

### Why can't I have (more/fewer/other) files?

Convention. Proto restricts the sources to one file for each type to limit the kinds of things that can be built with it. It's a tool for prototyping relatively small interactions, kind of like a command-line version of [Pad Hacker](http://padhacker.net) or [JSFiddle](http://jsfiddle.net). Keeping the projects simple also makes it easy for others to understand quickly.


## License

Unlicensed aka Public Domain. See [/UNLICENSE](https://github.com/droptype/proto/blob/master/UNLICENSE) for more information.

