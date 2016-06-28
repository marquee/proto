fs              = require 'fs'
sys             = require 'sys'

cli             = require 'cli'
git             = require 'simple-git'
rest            = require 'restler'

renderer                            = require './renderer'
{ htmlResponse, fileResponse }      = require './http_utils'
{ cacheFileFromURL }                = require './cache'
VERSION                             = require('../package.json').version

{
    VIEWER_URL
    PROTO_DIR
    SETTINGS_FILE
    LIB_DIR
    PROTO_FILES
} = require './SETTINGS'


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
    console.info("#{ t }: #{ args.join(' ') }")

quitWithMsg = (message) ->
    stamp(message)
    process.exit()

projectPath = (project_name) ->
    return "#{ CWD }/#{ project_name }"



# Fetch a Gist from the GitHub API. Calls the callback whether or not the
# request was successful.
getGist = (url, callback) ->
    GIST_API = 'https://api.github.com/gists'
    post_req = rest.get(GIST_API + url)
    post_req.on 'complete', (data, response) ->
        callback(data, response.statusCode)


# Initialize a project using the specified project name and the default
# template. Optionally, use the specified Gist URL/ID to load a gist and use
# that as the template.
initializeProject = (project_name, gist_url=null, react=false, cli_args) ->

    # No name was specified, so use a generated on in the format
    # proto-YYYYMMDD-N, where N is an incremental counter to avoid conflicts.
    if not project_name and not gist_url
        counter = 1
        date = new Date()
        makeName = -> "proto-#{ date.getFullYear() }#{ date.getMonth() + 1 }#{ date.getDate() }-#{ counter }"
        project_name = makeName()
        while fs.existsSync(project_name)
            counter += 1
            project_name = makeName()

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

    if gist_url
        # Parse the ID and fetch the Gist, using that as a template.
        gist_id = gist_url.split('/')
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

                if cli_args[0]?
                    # If there is a second name specified, use that as the
                    # project name.
                    project_name = cli_args[0]
                else
                    # Use the name specified name in the settings file.
                    project_name = JSON.parse(templates['settings.json']).name

                stamp("Fetched Gist, project name is #{ project_name }")

                doInit(templates)

    else if react
        # Do the init with the default template.
        doInit
            'script.coffee' : """
                Component = React.createClass
                    displayName: 'Component'
                    render: ->
                        <div className='Component'>
                            Component! {@props.time.toString()}
                        </div>

                ReactDOM.render(<Component time={new Date()} />, document.getElementById('app'))
            """
            'markup.pug'    : '#app\n'
            'style.sass'    : """
                html,
                body
                    margin: 0
            """
            'notes.md'      : "# #{ project_name }\n\n\n"
            'settings.json' : """{
                "name": "#{ project_name }",
                "proto_version": "#{ VERSION }",
                "script_libraries": [
                    "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/react/15.1.0/react.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/react/15.1.0/react-dom.js"
                ],
                "style_libraries": [
                ],
                "extra_head_markup": "<meta name='viewport' content='width=device-width'>"
            }"""
    else
        # Do the init with the default template.
        doInit
            'script.coffee' : 'console.log "loaded"\n\n\n'
            'markup.jade'   : 'h1 Hello, world!\n\n\n'
            'style.styl'    : '@import \'nib\'\n\nh1\n    font-weight 300\n    font-family Helvetica\n\n\n'
            'notes.md'      : "# #{ project_name }\n\n\n"
            'settings.json' : """{
                "name": "#{ project_name }",
                "proto_version": "#{ VERSION }",
                "script_libraries": [
                    "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.0/jquery.min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/jqueryui/1.10.4/jquery-ui.min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/jqueryui-touch-punch/0.2.2/jquery.ui.touch-punch.min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.7.0/underscore-min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/underscore.string/2.3.3/underscore.string.min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/coffee-script/1.7.1/coffee-script.min.js",
                    "https://cdnjs.cloudflare.com/ajax/libs/backbone.js/1.1.2/backbone-min.js"
                ],
                "style_libraries": [
                    "https://ajax.googleapis.com/ajax/libs/jqueryui/1.10.4/themes/base/jquery.ui.all.css"
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
    git(project_path).getRemotes true, (err, remotes) ->
        if err?
            quitWithMsg("Unable to get remotes: #{ err }")
        id = null
        for remote in remotes
            if remote.name is 'origin'
                id = remote.refs.push.match(/([0-9a-f]+).git$/)
                if id
                    id = id[1]
                    _url = "https://gist.github.com/#{ id }"
                    viewer_url = VIEWER_URL + id
                    cb(id, _url, viewer_url)
                    return
        unless id
            quitWithMsg("No gist remote found.")



displayUrlsFor = (project_name) ->
    project_path = projectPath(project_name)
    getGistId project_path, (id, url, viewer_url) ->
        quitWithMsg """\n\n
            #{ project_path }

            Gist ID    : #{ id }
            Gist URL   : #{ url }
            Viewer URL : #{ viewer_url }\n\n\n
        """


updateGist = (project_name, project_path) ->
    getGistId project_path, (id, url, viewer_url) ->
        stamp("Updating Gist at: #{ url }")
        git(project_path).add('.').commit 'Update from CLI', (err) ->
            if err?
                quitWithMsg("Unable to commit changes (probably no changes?): #{ err }")
            else
                git(project_path).push 'origin', 'master', (err) ->
                    if err?
                        quitWithMsg("Unable to push changes: #{ err }")
                    else
                        quitWithMsg("Successfully updated Gist: \n#{ url }\n#{ viewer_url }")


getAuthorization = ->
    access_token = getSetting('github_authorization')?.token
    if not access_token
        quitWithMsg("Error: No access token in ~/.proto-cli/settings.json. Please reauthenticate with `proto --github <username> <password>`.")
    return access_token


initializeRepo = (project_path, gist_id, html_url) ->
    git_push_url = "git@gist.github.com:#{ gist_id }.git"
    git(project_path).init (err) ->
        if err?
            quitWithMsg("Unable to init repo: #{ err }")
        git(project_path).addRemote 'origin', git_push_url, (err) ->
            if err?
                quitWithMsg("Unable to add the remote to the git repo: #{ err }")
            else
                git(project_path).add('.').commit 'Init from CLI', (err) ->
                    if err?
                        quitWithMsg(err)
                    else
                        git(project_path).push ['-f', 'origin', 'master'], (err) ->
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
        'markup.pug'
        'style.sass'
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
            initializeRepo(project_path, data.id, data.html_url)
        else
            stamp("Error: #{ response.statusCode }")
            sys.puts(JSON.stringify(data))
            if response.statusCode is 401
                stamp("The token in #{ SETTINGS_FILE } is invalid. Please reauthenticate with `proto --github <username> <password>` or delete ~/.proto-cli")

getSetting = (key=null) ->
    settings = JSON.parse(fs.readFileSync(SETTINGS_FILE))
    if key
        return settings[key]
    else
        return settings

saveSetting = (key, value) ->
    settings = getSetting()
    settings[key] = value
    sys.puts(JSON.stringify(settings))
    fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings))


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
        console.dir(data)
        if response.statusCode is 201
            saveSetting('github_authorization', data)
            quitWithMsg("Success! GitHub auth token stored in #{ SETTINGS_FILE }")
        else
            sys.puts("Error: #{ response.statusCode }")
            sys.puts(JSON.stringify(data))


loadProjectData = (project_name, for_migration=false) ->
    project_path = projectPath(project_name)

    if not fs.existsSync(project_path)
        quitWithMsg("Error: #{ project_name } not found. Initialize with `proto -i #{ project_name }`.")

    sources =
        script      : project_path + '/script.coffee'
        markup      : project_path + '/markup.pug'
        style       : project_path + '/style.sass'
        settings    : project_path + '/settings.json'

    stamp("Working on #{ project_name }\n#{ project_path }\n")

    checkVersion = (settings) ->
        if settings.proto_version isnt VERSION and MIGRATIONS.length > 0
            message = "#{ project_name } version (#{ settings.proto_version }) does not match Proto version (#{ VERSION })"
            if settings.proto_version < VERSION
                message += "\nMigrate #{ project_name } using `proto -m #{ project_name }`."
            else
                message += '\nUpdate Proto using `npm install -g proto-cli`'
            quitWithMsg(message)

    loadSettings = (settings_source) ->
        settings = JSON.parse(fs.readFileSync(sources.settings))
        if not for_migration
            checkVersion(settings)
        return settings

    loadSources = ->
        source_content = {}
        for k in ['script', 'markup', 'style']
            source_content[k] = fs.readFileSync(sources[k])
        source_content.settings = loadSettings(source_content.settings)
        return source_content

    return loadSources()    

serveProject = (project_name, port) ->

    doCompilation = ->
        output = loadProjectData(project_name)
        output = renderer(output)
        return output

    handleRequest = (req, res, next) ->
        if req.url is '/'
            htmlResponse(req, res, doCompilation())
        else
            fileResponse(projectPath(project_name), req, res)

    serveContent = ->
        cli.createServer([
            handleRequest
        ]).listen(port)
        stamp("Listening on http://localhost:#{ port }")

    # Force a project load to check versions
    loadProjectData(project_name)

    serveContent()

MIGRATIONS = [
]

migrateProject = (project_name) ->
    # Migrations, listed in order of execution.
    #
    # A migration looks like this:
    #
    #    {
    #        'to_version': 'VERSION',
    #        'description': 'A description explaining what it does.'
    #        'migrationFn': (project) ->
    #             code that modifies the project (in place)
    #    },
    #

    project = loadProjectData(project_name, true)

    if project.settings.proto_version is VERSION
        quitWithMsg("#{ project_name } is already at v#{ VERSION }")

    stamp("Migrating #{ project_name } to v#{ VERSION }")

    for migration in MIGRATIONS
        if migration.to_version > project.settings.proto_version
            stamp("v#{ project.settings.proto_version } --> v#{ migration.to_version }")
            migration.migrationFn(project)
            project.settings.proto_version = migration.to_version

    project.settings.proto_version = VERSION
    settings_file = projectPath(project_name) + '/settings.json'
    fs.writeFileSync(settings_file, JSON.stringify(project.settings, null, '    '))

    quitWithMsg("#{ project_name } migrated")



downloadLibs = (project_name) ->
    project = loadProjectData(project_name)
    project.settings.script_libraries.forEach(cacheFileFromURL)
    project.settings.style_libraries.forEach(cacheFileFromURL)


exports.run = (args, options) ->
    if options.version
        quitWithMsg("Proto v#{ VERSION }")

    if options.github
        username = args[0]
        password = args[1]
        authWithGitHub(username, password)
    else if options.urls
        displayUrlsFor(options.urls)
    else if options.gist
        gistProject(options.gist, options.public)
    else if options.migrate
        migrateProject(options.migrate)
    else if options.download_libs
        downloadLibs(options.download_libs)
    else if options.init
        project_name = args[0] or ''
        initializeProject(project_name, options.gist, options.react, args)
    else
        project_name = args[0]
        if not project_name
            quitWithMsg('Error: Please specify a project name, eg `proto <project_name>`')
        serveProject(project_name, options.port)
