crypto  = require 'crypto'
fs      = require 'fs'
rest    = require 'restler'
sys     = require 'sys'

{ PRODUCTION, LIB_DIR } = require './settings'

_generateCacheKey = (url) ->
    url_hash = crypto.createHash('md5')
    url_hash.update(url)
    ext = url.split('.').pop()
    return url_hash.digest('hex') + '.' + ext

getCacheKey = (url) ->
    # Cache only works if running the local `proto` command.
    if not process.env.RUNNING_APP
        key = _generateCacheKey(url)
        if fs.existsSync(LIB_DIR + key)
            return key
        else
            return null
    else
        return null

cacheFileFromURL = (remote_path) ->
    if not fs.existsSync(LIB_DIR)
        fs.mkdirSync(LIB_DIR)

    key = _generateCacheKey(remote_path)
    target_path = LIB_DIR + key
    sys.puts("Getting: #{ remote_path }")
    get_req = rest.get(remote_path)
    get_req.on 'complete',  (data, response) ->
        if response.statusCode is 200
            fs.writeFile target_path, data, (err) ->
                if err?
                    sys.puts("Error saving #{ remote_path }: #{ err }")
                else
                    sys.puts("Saved: #{ remote_path }")
        else
            sys.puts("Error: #{ response.statusCode }")
            sys.puts(data)

loadFromCache = (key, cb=null) ->
    if cb?
        fs.readFile(LIB_DIR + key, 'utf8', cb)
    else
        return fs.readFileSync(LIB_DIR + key, 'utf8')

module.exports =
    getCacheKey         : getCacheKey
    cacheFileFromURL    : cacheFileFromURL
    loadFromCache       : loadFromCache