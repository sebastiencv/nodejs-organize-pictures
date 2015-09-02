walk = require "walk"
picture_info = require "./picture_info"

folders_uuid = {} # will contain the list of all uuid in each folder

is_picture_to_add = (folder, picture_uuid, is_to_add) ->
  if folders_uuid[folder]? # folder info exists
    if folders_uuid[folder][picture_uuid]?
      is_to_add false # uuid already exist in that folder
    else
      folders_uuid[folder][picture_uuid] = true # save the uuid exists now
      is_to_add true # must be added
  else
    read_folder_uuids folder, () ->
      is_picture_to_add folder, picture_uuid, is_to_add

# collect all uuid for this folder
read_folder_uuids = (folder, done) ->
  folders_uuid[folder] = {} unless folders_uuid[folder]?
  walker  = walk.walk folder, { followLinks: false }
  walker.on "file", (root, fileStat, next) ->
    if fileStat.name.charAt(0) is "."
      next()
    else
      picture_info.get_data_time_and_uuid root, fileStat.name
      , (date_time, unique_id) ->
        folders_uuid[folder][unique_id] = fileStat.name # save the uuid exists now
        next()
      , (error) ->
        console.log "* could not read uuid from #{root}/#{fileStat.name}"
        next()
  walker.on "end", done


exports.is_picture_to_add = (folder, picture_uuid, is_to_add) ->
  is_picture_to_add folder, picture_uuid, is_to_add
