htmlResponse = (response, content, status_code=200) ->
    response.writeHead status_code,
        'Content-Type'      : 'text/html'
        'Content-Length'    : Buffer.byteLength(content).toString()
    response.end(content)

staticResponse = (response, content, content_type, status_code=200) ->
    response.writeHead status_code,
        'Content-Type'      : content_type
        'Content-Length'    : Buffer.byteLength(content).toString()
    response.end(content)

module.exports =
    htmlResponse: htmlResponse
    staticResponse: staticResponse
