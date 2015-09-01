walk = require "walk"
picture_info = require "./picture_info"

folders_uuid = {} # will contain the list of all uuid in each folder

is_picture_to_add = (folder, picture_uuid, on_add) ->
  if folders_uuid[folder]? # folder info exists
    if folders_uuid[folder][picture_uuid]?
      on_add false # uuid already exist in that folder
    else
      folders_uuid[folder][picture_uuid] = true # save the uuid exists now
      on_add true # must be added
  else
    read_folder_uuids folder, () ->
      is_picture_to_add folder, picture_uuid, on_add

# collect all uuid for this folder
read_folder_uuids = (folder, done) ->
  walker  = walk.walk folder, { followLinks: false }
  walker.on "file", (root, fileStat, next) ->
    source_file = "#{root}/#{fileStat.name}"
    picture_info.get_data_time_and_uuid source_file
    , (date_time, unique_id) ->
      folders_uuid[folder] = {} unless folders_uuid[folder]?
      folders_uuid[folder][unique_id] = true # save the uuid exists now
      next()
    , (error) ->
      console.log "* could not read uuid from #{source_file}"
      next()
  walker.on "end", done


exports.is_picture_to_add = (folder, picture_uuid, on_add) ->
  is_picture_to_add folder, picture_uuid, on_add
