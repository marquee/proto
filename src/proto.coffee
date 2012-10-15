#!/usr/bin/env coffee

###
proto -i <project_name>
proto <project_name>
###


fs              = require 'fs'
sys             = require 'sys'

cli             = require 'cli'
express         = require 'express'

CoffeeScript    = require 'coffee-script'
Jade            = require 'jade'
Stylus          = require 'stylus'

CWD = process.cwd()


stamp = (args...) ->
    sys.puts("#{ new Date() }: #{ args.join(' ') }")

quitWithMsg = (message) ->
    stamp(message)
    process.exit()



initializeProject = (project_name) ->
    templates =
        'script.coffee' : 'console.log "loaded"\n\n\n'
        'markup.jade'   : 'h1 Hello, world!\n\n\n'
        'style.styl'    : 'h1\n    font-weight 300\n    font-family Helvetica\n\n\n'
        'settings.json' : '{}'
        'notes.md'      : "# #{ project_name }\n\n\n"

    project_path = "#{ CWD }/#{ project_name }"

    sys.puts("Initializing '#{ project_name }' in #{ project_path }")

    if not fs.existsSync(project_path)
        fs.mkdir(project_path)
        for file_name in ['script.coffee', 'markup.jade', 'style.styl', 'settings.json', 'notes.md']
            fs.writeFileSync("#{ project_path }/#{ file_name }", templates[file_name])
        quitWithMsg("#{ project_name } initialized!")
    else
        quitWithMsg("Error: #{ project_path } already exists")



serveProject = (project_name, port) ->
    project_path = "#{ CWD }/#{ project_name }"

    if not fs.existsSync(project_path)
        quitWithMsg("Error: #{ project_name } not found. Initialize with `proto -i #{ project_name }`.")

    sources =
        script      : project_path + '/script.coffee'
        markup      : project_path + '/markup.jade'
        style       : project_path + '/style.styl'
        settings    : project_path + '/settings.json'

    sys.puts("Working on #{ project_name }\n#{ project_path }")

    compileScriptFile = (script_source_file) ->
        stamp('Compiling script')

        script_source = fs.readFileSync(script_source_file)
        return CoffeeScript.compile(script_source.toString())

    compileMarkupFile = (markup_source_file) ->
        stamp('Compiling markup')
        markup_source = fs.readFileSync(markup_source_file)
        template = Jade.compile(markup_source.toString())
        return template()

    compileStyleFile = (style_source_file) ->
        stamp('Compiling style')
        style_source = fs.readFileSync(style_source_file)
        compiled_style = ''
        # This isn't actually async, just bonkers.
        Stylus.render style_source.toString(), (err, data) ->
            compiled_style = data
        return compiled_style

    compositePage = (compiled) ->
        page = """
        <!doctype html>
        <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.1/underscore-min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/underscore.string/2.3.0/underscore.string.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/coffee-script/1.3.3/coffee-script.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.2/backbone-min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.9.0/jquery-ui.min.js"></script>
            <script src="https://cdnjs.cloudflare.com/ajax/libs/jqueryui-touch-punch/0.2.2/jquery.ui.touch-punch.min.js"></script>
            <script src="https://raw.github.com/Marak/Faker.js/master/Faker.js"></script>
            <link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1.9/themes/base/jquery.ui.all.css">
            <style>
                #{ compiled.style }
            </style>
        </head>
        <body>
            #{ compiled.markup }
            <script>
                #{ compiled.script }
            </script>
        </body>
        </html>
        """
        return page

    doCompilation = ->
        stamp('Compiling all the things')
        output = compositePage
            style   : compileStyleFile(sources.style)
            script  : compileScriptFile(sources.script)
            markup  : compileMarkupFile(sources.markup)
        return output

    serveContent = ->
        stamp('Creating server')
        app = express.createServer()

        app.get '/', (req, res) ->
            res.send(doCompilation())
        stamp("Listening on http://localhost:#{ port }")
        app.listen(port)

    serveContent()



exports.run = (args, options) ->
    new_project = args[0]

    if not new_project
        if options.init
            msg = 'Error: Please specify a project name, eg `proto -i <project_name>`'
        else
            msg = 'Error: Please specify a project name, eg `proto <project_name>`'
        quitWithMsg(msg)

    if options.init
        initializeProject(new_project)
    else
        serveProject(new_project, options.port)
