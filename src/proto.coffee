fs              = require 'fs'
sys             = require 'sys'

cli             = require 'cli'
express         = require 'express'
git             = require 'gitjs'
rest            = require 'restler'

renderer            = require './renderer'
{ htmlResponse }    = require './http_utils'
VERSION             = require './version'

VIEWER_URL  = 'http://proto.es/'
PROTO_FILES = ['script.coffee', 'markup.jade', 'style.styl', 'settings.json', 'notes.md']

CWD         = process.cwd()

# Some helpers...

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

projectPath = (project_name) ->
    return "#{ CWD }/#{ project_name }"



# Fetch a Gist from the GitHub API. Calls the callback whether or not the
# request was successful.
getGist = (url, cb) ->
getGist = (url, callback) ->
    GIST_API = 'https://api.github.com/gists'
    post_req = rest.get(GIST_API + url)
    post_req.on 'complete', (data, response) ->
        callback(data, response.statusCode)


# Initialize a project using the specified project name and the default
# template. Optionally, use the specified Gist URL/ID to load a gist and use
# that as the template.
initializeProject = (project_name, from_gist=false, cli_args) ->

    # Actual init function, taking a set of templates for each file. If the
    # project_path already exists, warns and quits.
    doInit = (templates) ->
        project_path = "#{ CWD }/#{ project_name }"

        sys.puts("Initializing '#{ project_name }' in #{ project_path }")

        if not fs.existsSync(project_path)
            fs.mkdirSync(project_path)
            for file_name in PROTO_FILES
                fs.writeFileSync("#{ project_path }/#{ file_name }", templates[file_name])
            quitWithMsg("#{ project_name } initialized!")
        else
            quitWithMsg("Error: #{ project_path } already exists")

    if from_gist
        # Parse the ID and fetch the Gist, using that as a template.
        gist_id = project_name.split('/')
        gist_id = gist_id[gist_id.length - 1]
        stamp("Fetching Gist: #{ gist_id }")
        getGist '/' + gist_id, (data, status_code) ->
            if status_code isnt 200
                quitWithMsg("Unable to fetch gist: #{ status_code }")
            else
                # Load the Gist contents into a template for the init.
                templates = {}
                for proto_f in PROTO_FILES
                    # If the needed file isn't in the Gist, warn and quit.
                    if not data.files?[proto_f]?
                        quitWithMsg("Gist is invalid Proto project, missing file: #{ proto_f }")
                    else
                        templates[proto_f] = data.files[proto_f].content

                if cli_args[1]?
                    # If there is a second name specified, use that as the
                    # project name.
                    project_name = cli_args[1]
                else
                    # Use the name specified name in the settings file.
                    project_name = JSON.parse(templates['settings.json']).name

                stamp("Fetched Gist, project name is #{ project_name }")

                doInit(templates)

    else
        # Do the init with the default template.
        doInit
            'script.coffee' : "$ = jQuery\n$ ->\n\t$('meta').append('<title>#{ project_name  }</title>')\n\n"
            'markup.jade'   : 'h1 Hello, world!\n\n\n'
            'style.styl'    : 'h1\n    font-weight 300\n    font-family Helvetica\n\n\n'
            'notes.md'      : "# #{ project_name }\n\n\n"
            'settings.json' : """{
                "name": "#{ project_name }",
                "proto_version": "#{ VERSION }",
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
                ],
                "extra_head_markup": "<meta name='viewport' content='width=device-width'>"
            }"""


# Send the project to a Gist, creating a new one or updating an existing one.
gistProject = (project_name, public_gist=false) ->
    project_path = projectPath(project_name)

    if not fs.existsSync(project_path)
        quitWithMsg("Error: #{ project_name } not found. Initialize with `proto -i #{ project_name }`.")

    if fs.existsSync(project_path + '/.git')
        updateGist(project_name, project_path)
    else
        createNewGist(project_name, project_path, public_gist)


getGistId = (project_path, cb) ->
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
                    viewer_url = VIEWER_URL + id
                    cb(repo, id, url, viewer_url)


displayUrlsFor = (project_name) ->
    project_path = projectPath(project_name)
    getGistId project_path, (repo, id, url, viewer_url) ->
        quitWithMsg """\n\n
            #{ project_path }

            Gist ID    : #{ id }
            Gist URL   : #{ url }
            Viewer URL : #{ viewer_url }\n\n\n
        """


updateGist = (project_name, project_path) ->
    getGistId project_path, (repo, id, url, viewer_url) ->
        stamp("Updating Gist at: #{ url }")
        repo.commitAll '', (err, stdout, stderr) ->
            if err?
                quitWithMsg("Unable to commit changes (probably no changes?): #{ err }")
            else
                repo.run 'push origin master', (err, stdout, stderr) ->
                    if err?
                        quitWithMsg("Unable to push changes: #{ err }")
                    else
                        quitWithMsg("Successfully updated Gist: \n#{ url }\n#{ viewer_url }")


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

    # Try getting authorization token. If the user hasn't authorized, returns null.
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
            stamp("View rendered project at #{ VIEWER_URL + data.id }")
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
    project_path = projectPath(project_name)

    if not fs.existsSync(project_path)
        quitWithMsg("Error: #{ project_name } not found. Initialize with `proto -i #{ project_name }`.")

    sources =
        script      : project_path + '/script.coffee'
        markup      : project_path + '/markup.jade'
        style       : project_path + '/style.styl'
        settings    : project_path + '/settings.json'

    stamp("Working on #{ project_name }\n#{ project_path }")

    loadSources = ->
        source_content = {}
        for k, v of sources
            source_content[k] = fs.readFileSync(v)
        source_content.settings = JSON.parse(source_content.settings)
        return source_content

    doCompilation = ->
        output = loadSources(sources)
        output = renderer(output)
        return output

    handleRequest = (req, res, next) ->
        if req.url is '/'
            htmlResponse(res, doCompilation())
        else
            htmlResponse(res, '404 - Proto only handles requests to /', 404)

    serveContent = ->
        cli.createServer([
            handleRequest
        ]).listen(port)
        stamp("Listening on http://localhost:#{ port }")

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
    else if options.urls
        displayUrlsFor(new_project)
    else if options.init
        initializeProject(new_project, options.gist, args)
    else if options.gist
        gistProject(new_project, options.public)
    else
        serveProject(new_project, options.port)
