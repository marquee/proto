PROTO_DIR = process.env.HOME + '/.proto-cli/'

module.exports =
    VIEWER_URL      : 'http://proto.es/'

    PROTO_DIR       : PROTO_DIR
    SETTINGS_FILE   : PROTO_DIR + 'settings.json'
    LIB_DIR         : PROTO_DIR + 'libcache/'

    PROTO_FILES     : ['script.coffee', 'markup.jade', 'style.styl', 'settings.json', 'notes.md']
    PRODUCTION      : process.env.PRODUCTION is 1

