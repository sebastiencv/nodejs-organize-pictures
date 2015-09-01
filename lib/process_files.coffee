fs = require "fs"
walk = require "walk"
mkpath = require "mkpath"
picture_info = require "./picture_info"
picture_unique_in_folder = require "./picture_unique_in_folder"

# search all files in input folder
walker  = walk.walk "data/in", { followLinks: false }
walker.on "file", (root, fileStat, next) ->
  source_file = "#{root}/#{fileStat.name}"
  picture_info.get_data_time_and_uuid source_file
  , (date_time, unique_id) ->
    [year, month, day] = date_time.split(/[: ]/)
    target_dir = "data/out/#{year}/#{month}/#{day}"
    mkpath target_dir, (err) ->
      if err?
        console.log "* Error creating target folders : #{err}".trim()
      else
        # check if the file must be added
        picture_unique_in_folder.is_picture_to_add target_dir, unique_id
        , (is_to_add) ->
          if is_to_add
            target_file = "#{target_dir}/#{fileStat.name}"
            fs.rename source_file, target_file, (err) ->
              if err?
                console.log "Error moving #{source_file} to #{target_file} : #{err}"
              else
                console.log fileStat.name, "->", target_file
          else
            console.log fileStat.name, "already in", target_file
          next()
  , (error) ->
    console.log "*", source_file, "#{error}".trim()
    next()
