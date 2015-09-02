data_in = "/Volumes/Data/Pictures/SortedPictures/ToSort"
data_out = "/Volumes/Data/Pictures/SortedPictures"
data_duplicate = "/Volumes/Data/Pictures/SortedPictures/Duplicates"

fs = require "fs"
walk = require "walk"
mkpath = require "mkpath"
picture_info = require "./picture_info"
picture_unique_in_folder = require "./picture_unique_in_folder"

# search all files in input folder
walker  = walk.walk data_in, { followLinks: false }
walker.on "file", (root, fileStat, next) ->
  if fileStat.name.charAt(0) is "."
    next()
  else
    source_file = "#{root}/#{fileStat.name}"
    picture_info.get_data_time_and_uuid root, fileStat.name
    , (date_time, unique_id) ->
      [year, month] = date_time.split(/[: ]/)
      target_dir = "#{data_out}/#{year}/#{month}"
      mkpath target_dir, (err) ->
        if err?
          console.log "* Error creating target folders : #{err}".trim()
          next()
        else
          # check if the file must be added
          picture_unique_in_folder.is_picture_to_add target_dir, unique_id
          , (is_to_add) ->
            target_file = "#{target_dir}/#{fileStat.name}"
            if is_to_add
              move_to = target_file
            else
              move_to = "#{data_duplicate}/#{fileStat.name}"
            fs.rename source_file, move_to, (err) ->
              if err?
                console.log "Error moving #{source_file} to #{target_file} : #{err}"
              else
                if is_to_add
                  console.log fileStat.name, "->", target_file
                else
                  console.log fileStat.name, "already in", target_file
              next()
    , (error) ->
      console.log "*", source_file, "#{error}".trim()
      next()
