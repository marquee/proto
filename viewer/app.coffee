cli                 = require 'cli'

{ htmlResponse }    = require '../src/http_utils'
renderer            = require '../src/renderer'
rest                = require 'restler'



getGist = (url, cb) ->
    GIST_API = 'https://api.github.com/gists'
    post_req = rest.get(GIST_API + url)
    post_req.on 'complete', (data, response) ->
        cb(data, response.statusCode)



handleIndex = (request, response, next) ->
    if request.url is '/'
        html_content = 'Hello World!'
        htmlResponse(response, html_content)
    else
        next()

handleRequests = (request, response, next) ->
    unless request.url is '/favicon.ico'
        # The GitHub API doesn't handle trailing slashes, so trim them.
        url = request.url
        if url[url.length - 1] is '/'
            url = url.substring(0, url.length - 1)

        getGist request.url, (data, res_code) ->
            if res_code is 200
                content = renderer
                    style       : data.files['style.styl'].content
                    script      : data.files['script.coffee'].content
                    markup      : data.files['markup.jade'].content
                    settings    : JSON.parse(data.files['settings.json'].content)
                htmlResponse(response, content)
            else
                content = 'Gist not found'
                htmlResponse(response, content, 404)
            



port = process.env.PORT or 5000

cli.createServer([
    handleIndex
    handleRequests
]).listen(port)


