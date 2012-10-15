fs              = require 'fs'
sys             = require 'sys'

cli             = require 'cli'
express         = require 'express'
rest            = require 'restler'

CoffeeScript    = require 'coffee-script'
Jade            = require 'jade'
Stylus          = require 'stylus'

proto_version = "0.0.3"


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
        'notes.md'      : "# #{ project_name }\n\n\n"
        'settings.json' : """{
            "version": "#{ proto_version }",
            "script_libraries": [
                "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.1/underscore-min.js",
                "https://cdnjs.cloudflare.com/ajax/libs/underscore.string/2.3.0/underscore.string.min.js",
                "https://cdnjs.cloudflare.com/ajax/libs/coffee-script/1.3.3/coffee-script.min.js",
                "https://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.2/backbone-min.js",
                "https://cdnjs.cloudflare.com/ajax/libs/jquery/1.8.2/jquery.min.js",
                "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.9.0/jquery-ui.min.js",
                "https://cdnjs.cloudflare.com/ajax/libs/jqueryui-touch-punch/0.2.2/jquery.ui.touch-punch.min.js",
                "https://raw.github.com/Marak/Faker.js/master/Faker.js"
            ],
            "style_libraries": [
                "https://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/base/jquery.ui.all.css"
            ]
        }"""


    project_path = "#{ CWD }/#{ project_name }"

    sys.puts("Initializing '#{ project_name }' in #{ project_path }")

    if not fs.existsSync(project_path)
        fs.mkdirSync(project_path)
        for file_name in ['script.coffee', 'markup.jade', 'style.styl', 'settings.json', 'notes.md']
            fs.writeFileSync("#{ project_path }/#{ file_name }", templates[file_name])
        quitWithMsg("#{ project_name } initialized!")
    else
        quitWithMsg("Error: #{ project_path } already exists")

gistProject = (project_name) ->
    # TODO: DRY this up
    project_path = "#{ CWD }/#{ project_name }"

    if not fs.existsSync(project_path)
        quitWithMsg("Error: #{ project_name } not found. Initialize with `proto -i #{ project_name }`.")

    post_data =
        description   : 'A proto project: https://github.com/droptype/proto'
        public        : false
        files         : {}

    sources = [
        'script.coffee'
        'markup.jade'
        'style.styl'
        'settings.json'
        'notes.md'
    ]


    for f in sources
        do ->
            source = project_path + '/' + f
            content = fs.readFileSync(source)
            post_data.files[f] =
                content: content.toString()

    GIST_API = 'https://api.github.com/gists'
    post_req = rest.post GIST_API,
        data: JSON.stringify(post_data)
    post_req.on 'complete', (data, response) ->
        if response.statusCode is 201
            gist_url = data.html_url
            quitWithMsg("Success! Gist created at #{ gist_url }")
        else
            sys.puts("Error: #{ request.statusCode }")
            sys.puts(data)



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

    loadSettings = (settings_source_file) ->
        settings_raw = fs.readFileSync(settings_source_file)
        settings = JSON.parse(settings_raw)
        # TODO: Validate settings
        if settings.version isnt proto_version
            quitWithMsg("Error: #{ project_name }'s version (#{ settings.version }) does not match Proto's (#{ proto_version })")
        return settings

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

    compileScriptLibraries = (settings) ->
        script_libs = ''
        for lib in settings.script_libraries
            script_libs += "<script src='#{ lib }'></script>"
        return script_libs

    compileStyleLibraries = (settings) ->
        style_libs = ''
        for lib in settings.style_libraries
            style_libs += "<link rel='stylesheet' href='#{ lib }' type='text/css'>"
        return style_libs

    compositePage = (compiled) ->
        page = """
        <!-- Generated by https://github.com/droptype/proto v#{ proto_version } -->
        <!doctype html>
        <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
            #{ compiled.script_libraries }
            #{ compiled.style_libraries }
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
        settings = loadSettings(sources.settings)
        output = compositePage
            style               : compileStyleFile(sources.style)
            script              : compileScriptFile(sources.script)
            markup              : compileMarkupFile(sources.markup)
            script_libraries    : compileScriptLibraries(settings)
            style_libraries     : compileStyleLibraries(settings)
        return output

    serveContent = ->
        stamp('Creating server')
        app = express()

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
    else if options.gist
        gistProject(new_project)
    else
        serveProject(new_project, options.port)