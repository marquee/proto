fs              = require 'fs'
sys             = require 'sys'

cli             = require 'cli'
express         = require 'express'
git             = require 'gitjs'
rest            = require 'restler'


CoffeeScript    = require 'coffee-script'
Jade            = require 'jade'
Stylus          = require 'stylus'

proto_version = "0.0.4"


CWD = process.cwd()

pad = (val) ->
    if val < 10
        return "0#{ val }"
    else
        return val.toString()

stamp = (args...) ->
    t = new Date()
    hour = pad(t.getHours())
    min = pad(t.getMinutes())
    sec = pad(t.getSeconds())
    t = "#{ hour }:#{ min }:#{ sec }"
    sys.puts("#{ t }: #{ args.join(' ') }")

quitWithMsg = (message) ->
    stamp(message)
    process.exit()



initializeProject = (project_name, from_gist=false) ->
    # if from gist, pull from api, get name from settings, create folder with name, init with gist contents
    templates =
        'script.coffee' : 'console.log "loaded"\n\n\n'
        'markup.jade'   : 'h1 Hello, world!\n\n\n'
        'style.styl'    : 'h1\n    font-weight 300\n    font-family Helvetica\n\n\n'
        'notes.md'      : "# #{ project_name }\n\n\n"
        'settings.json' : """{
            "name": "#{ project_name }",
            "proto_version": "#{ proto_version }",
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



gistProject = (project_name, public_gist=false) ->
    # TODO: DRY this up
    project_path = "#{ CWD }/#{ project_name }"

    if not fs.existsSync(project_path)
        quitWithMsg("Error: #{ project_name } not found. Initialize with `proto -i #{ project_name }`.")

    if fs.existsSync(project_path + '/.git')
        updateGist(project_name, project_path)
    else
        createNewGist(project_name, project_path, public_gist)



updateGist = (project_name, project_path) ->
    git.open project_path, false, (err, repo) ->
        if err?
            quitWithMsg("Unable to open git repo: #{ err }")
        else
            # Reconstruct the Gist url using the ID extracted from the git remote
            repo.run 'remote show origin', (err, stdout, stderr) ->
                if err?
                    quitWithMsg("Unable to get remotes: #{ err }")
                else
                    # stdout looks like:
                    #
                    #     * remote origin
                    #     Fetch URL: git@gist.github.com:<id>.git
                    #     Push  URL: git@gist.github.com:<id>.git
                    #     ...
                    line = stdout.split('\n')[2]
                    id = line.split(':')[2].split('.')[0]
                    url = "https://gist.github.com/#{ id }"
                    stamp("Updating Gist at: #{ url }")
                    repo.commitAll '', (err, stdout, stderr) ->
                        if err?
                            quitWithMsg("Unable to commit changes (probably no changes?): #{ err }")
                        else
                            repo.run 'push origin master', (err, stdout, stderr) ->
                                if err?
                                    quitWithMsg("Unable to push changes: #{ err }")
                                else
                                    quitWithMsg("Successfully updated Gist: #{ url }")



getAuthorization = ->
    target_path = process.env.HOME + '/.proto-cli'
    if fs.existsSync(target_path)
        auth_file = fs.readFileSync(target_path)
        try
            auth_obj = JSON.parse(auth_file)
        catch e
            quitWithMsg("Error: Unable to read the access token in #{ target_path }. Please reauthenticate with `proto --github <username> <password>` or delete ~/.proto-cli")
        access_token = auth_obj.token
    else
        access_token = null

    return access_token



initializeRepo = (project_path, git_push_url, html_url) ->
    git.open project_path, true, (err, repo) ->
        if err?
            quitWithMsg("Unable to initialize a git repo: #{ err }")
        repo.run 'remote add origin ?', [git_push_url], (err, stdout, stderr ) ->
            if err?
                quitWithMsg("Unable to add the remote to the git repo: #{ err }")
            else
                repo.run 'add .', (err, stdout, stderr) ->
                    if err?
                        quitWithMsg(err)
                    else
                        repo.run 'pull -f origin master', (err, stdout, stderr) ->
                            if err?
                                quitWithMsg(err)
                            else
                                quitWithMsg("Project initialized as git repo with #{ git_push_url } remote")



createNewGist = (project_name, project_path, public_gist) ->

    post_data =
        description   : 'A proto project: https://github.com/droptype/proto'
        public        : public_gist
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

    # try getting authorization token
    access_token = getAuthorization()

    GIST_API = 'https://api.github.com/gists'
    request_options =
        data: JSON.stringify(post_data)

    if access_token
        stamp('Creating authenticated Gist')
        request_options.headers =
            Authorization: "token #{ access_token }"
    else
        stamp("Creating anonymous Gist")

    post_req = rest.post(GIST_API, request_options)
        
    post_req.on 'complete', (data, response) ->
        if response.statusCode is 201
            stamp("Success! Gist created at #{ data.html_url }")
            initializeRepo(project_path, data.git_push_url, data.html_url)
        else
            stamp("Error: #{ response.statusCode }")
            sys.puts(JSON.stringify(data))
            if response.statusCode is 401
                stamp("The token in ~/.proto-cli is invalid. Please reauthenticate with `proto --github <username> <password>` or delete ~/.proto-cli")



authWithGitHub = (username, password) ->
    AUTH_API = 'https://api.github.com/authorizations'
    post_req = rest.post AUTH_API,
        username: username
        password: password
        data: JSON.stringify
            scopes      : ["gist"]
            note        : "Proto"
            note_url    : "https://github.com/droptype/proto"
    post_req.on 'complete',  (data, response) ->
        if response.statusCode is 201
            target_path = process.env.HOME + '/.proto-cli'
            fs.writeFileSync(target_path, JSON.stringify(data))
            quitWithMsg("Success! GitHub auth token stored in #{ target_path }")
        else
            sys.puts("Error: #{ response.statusCode }")
            sys.puts(JSON.stringify(data))



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
        if settings.proto_version isnt proto_version
            quitWithMsg("Error: #{ project_name }'s proto_version (#{ settings.proto_version }) does not match Proto's (#{ proto_version })")
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
        # TODO: just use stack (included in cli)
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

    if options.github
        username = args[0]
        password = args[1]
        authWithGitHub(username, password)
    else if options.init
        initializeProject(new_project, options.gist)
    else if options.gist
        gistProject(new_project, options.public)
    else
        serveProject(new_project, options.port)
