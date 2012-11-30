fs = require 'fs'

{ loadFromCache } = require './cache'

htmlResponse = (request, response, content, status_code=200) ->
    response.writeHead status_code,
        'Content-Type'      : 'text/html'
        'Content-Length'    : Buffer.byteLength(content).toString()
    response.end(content)

cacheResponse = (request, response) ->
    cache_key = request.url
    if /.js$/.test(request.url)
        content_type = 'text/javascript'
    else if /.css$/.test(request.url)
        content_type = 'text/css'
    else
        content_type = 'application/octet-stream'
    loadFromCache cache_key, (err, cache_content) ->
        if err
            if err.errno == 34
                err_msg = '<h1>File not found</h1>'
                status_code = 404
            else
                err_msg = '<h1>Server Error</h1><pre>' + err.toString() + '</pre>'
                status_code = 500
            htmlResponse(request, response, err_msg, status_code)
        else
            response.writeHead 200,
                'Content-Type'      : content_type
                'Content-Length'    : Buffer.byteLength(cache_content).toString()
            response.end(cache_content)


module.exports =
    htmlResponse    : htmlResponse
    cacheResponse   : cacheResponse