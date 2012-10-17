cli                 = require 'cli'

{ htmlResponse }    = require '../src/http_utils'
renderer            = require '../src/renderer'
rest                = require 'restler'



getGist = (url, cb) ->
    GIST_API = 'https://api.github.com/gists'
    post_req = rest.get(GIST_API + url)
    post_req.on 'complete', (data, response) ->
        cb(data, response)



handleIndex = (request, response, next) ->
    if request.url is '/'
        response.writeHead 303,
            'Location': 'https://github.com/droptype/proto'
        response.end()
    else
        next()

validGist = (files) ->
    for f in ['script.coffee', 'markup.jade', 'style.styl', 'settings.json', 'notes.md']
        if not files?[f]?
            return false
    return true

handleRequests = (request, response, next) ->
    unless request.url is '/favicon.ico'
        # The GitHub API doesn't handle trailing slashes, so trim them.
        url = request.url
        if url[url.length - 1] is '/'
            url = url.substring(0, url.length - 1)

        getGist url, (data, github_response) ->
            if github_response.statusCode is 200 and validGist(data.files)
                content = renderer
                    style       : data.files['style.styl'].content
                    script      : data.files['script.coffee'].content
                    markup      : data.files['markup.jade'].content
                    settings    : JSON.parse(data.files['settings.json'].content)
                htmlResponse(response, content)
            else
                raw_response = github_response.raw.toString()
                try
                    github_response_content = JSON.stringify((JSON.parse(raw_response)), null, 4)
                catch e
                    github_response_content = raw_response
                content = """
                    Valid <a href="https://github.com/droptype/proto">Proto</a> Gist not found at
                    <a href="https://gist.github.com#{ url }">gist.github.com#{ url }</a>:
                    <br><br>
                    <pre style="border: 1px solid #d3d4c7;background: #fdf6e3;padding: 1em;overflow-x: scroll;"><code>
                    <a href="https://api.github.com/gists#{ url }">GET https://api.github.com/gists#{ url }</a>
                    #{ github_response.statusCode }
                    <hr style="border: 0;border-top: 1px solid #d3d4c7;">
                    #{ github_response_content }
                    </code></pre>
                """
                htmlResponse(response, content, 404)
            



port = process.env.PORT or 5000

cli.createServer([
    handleIndex
    handleRequests
]).listen(port)


