migrations = [
    # {
    #     'to_version': 'VERSION'
    #     'description': 'Some description'
    #     'migrationFn': (settings) ->
    #         # do stuff to settings
    # }
]

fs = require 'fs'
VERSION = require('../package.json').version



target_path = process.env.HOME + '/.proto-cli'

settings_file = target_path + '/settings.json'

if not fs.existsSync(settings_file)
    # do initial migration
    console.log 'Doing pre-v2.0.0 settings migration'
    try
        old_settings = JSON.parse(fs.readFileSync(target_path))
        fs.unlinkSync(target_path)
        old_settings =
            github_authorization: old_settings
    catch e
        old_settings = {}

    old_settings.version = VERSION

    fs.mkdirSync(target_path)
    fs.writeFileSync(settings_file, JSON.stringify(old_settings))

settings = JSON.parse(fs.readFileSync(settings_file))
migrations.forEach (migration) ->
    if migration.to_version > settings.to_version
        migration.migrationFn(settings)
fs.writeFileSync(settings_file, JSON.stringify(settings))

