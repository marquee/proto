# Proto

Proto is a front-end web prototyping tool, combining markup (.jade), script (.coffee), and style (.styl) into a single page. It creates a set of files each representing one of those three facets of the page, plus files for notes and settings, and serves up their rendered form. Every time the page is loaded, those files are compiled on-the-fly. It's helpful for creating prototypes using CoffeeScript, Jade, and Stylus, without having to set up a build process and environment.

## Installation

    npm install proto-cli

or from source

    git clone git://github.com/droptype/proto.git
    cd proto
    cake build
    npm install -g .

`cake build` will compile `src/proto.coffee` into `lib/proto.js` (ignored by git).


## Usage

### Init

    proto -i <project_name>

Initializes the project by creating a folder with the specified name and adding five files: `markup.jade`, `script.coffee`, `style.styl`, `settings.json`, and `notes.md`.

e.g. `proto -i my_project` creates a folder called `my_project` in the current working directory

    my_project/
        markup.jade       - the source for the markup code, in [Jade](http://jade-lang.com/)
        script.coffee     - the source for the script code, in [CoffeeScript](http://coffeescript.org)
        style.styl        - the source for the style code, in [Stylus](http://learnboost.github.com/stylus/)
        settings.json     - settings for the project, specifically extra libraries to include into the page
        notes.coffee      - a place for extra notes


### Work on a project

To serve the project at [localhost:5000](http://localhost:5000):

    proto <project_name>

Or specify a port:

    proto <project_name> -p 8080

This starts a server that serves the compiled markup, script, and style on the specified port (default 5000). The source files are compiled every time the page is requested.

The source files are compiled and inserted into a full `html` template. Libraries specified in `settings.json`, and the CSS compiled from `style.styl`, are added to the `<head>` of the page. `markup.jade` gets compiled to HTML and inserted into the `<body>`, and `script.coffee` gets compiled to JavaScript and added to the end of the `<body>`.

To have additional libraries loaded, add them to the `script_libraries` or `style_libraries`. They must be served from somewhere else, like a [CDN](http://cdnjs.com/).


## FAQ

### Why not LiveReload?

LiveReload is awesome and works great — in fact it works really well alongside Proto — but doesn't serve the files (and nor should it). Certain JavaScript features require the file to be served instead of loaded using `file://` for security reasons. Proto is simpler to use and provides an easy way to initialize the project. It is also intended to be opinionated about the languages and structure it supports, creating simplicity through useful defaults.

### Why can't I have (more|fewer|other) files?

Convention. Proto restricts the sources to one file for each type to limit the kinds of things that can be built with it. It's a tool for prototyping relatively small interactions, kind of like a command-line version of [Pad Hacker](http://padhacker.net) or [JSFiddle](http://jsfiddle.net). Keeping the projects simple also makes it easy for others to understand quickly.


## License

Unlicensed aka Public Domain. See /UNLICENSE for more information.

