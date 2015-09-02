###

get_data_time_and_uuid will return the creation date and a uuid for each media

creation date is the first found value from :
1) exif DateTimeOriginal
2) exif MediaCreateDate
3) exif FileModifyDate

uuid date is the first found value from :
1) exif ImageUniqueID
2) shasum of exif ThumbnailImage
3) file name

Credits to https://github.com/nathanpeck/exiftool

###


child_process = require('child_process')
# returns a unique id for a file

build_id_from_thumbnail = (path, file, date_time, on_id, on_error) ->
  # build a uuid by computing the sha of the thumbnail
  path_file = "#{path}/#{file}".replace(/[ ]/g, "\\ ")
  shell_command = "exiftool -b -ThumbnailImage #{path_file} | shasum"
  exif = child_process.spawn 'sh', ['-c', shell_command]
  uuid = ""
  error = ""
  exif.on 'error', (err) -> error += "(build_id_from_thumbnail) #{err}"
  exif.stderr.on 'data', (data) -> error += "(build_id_from_thumbnail) #{data}"
  exif.stdout.on 'data', (data) -> uuid += "#{data}".trim() if data?
  exif.on 'close', ->
    if uuid isnt ""
      on_id date_time, uuid # uuid found
    else
      on_id date_time, file # no uuid found, set file name as uuid

build_id_from_unique_id = (path, file, on_id, on_error) ->
  # frist try to get the picture uuid (exif 2.0)
  exif = child_process.spawn 'exiftool', ["-S", "-json", "-DateTimeOriginal", "-MediaCreateDate", "-FileModifyDate", "-ImageUniqueID", "-ThumbnailImage", "#{path}/#{file}"]
  uuid = null
  error = ""
  date_time = null
  thumbnail_exists = false
  exif.on 'error', (err) -> error += "(build_id_from_unique_id) #{err}"
  exif.stderr.on 'data', (data) -> error += "(build_id_from_unique_id) #{data}"
  exif.stdout.on 'data', (data) ->
    data = JSON.parse data
    if data.length is 1
      date_time = data[0].DateTimeOriginal?.trim()
      date_time = data[0].MediaCreateDate?.trim() unless date_time?
      date_time = data[0].FileModifyDate?.trim() unless date_time?
      thumbnail_exists = data[0].ThumbnailImage?
      uuid = data[0].ImageUniqueID?.trim()
  exif.on 'close', ->
    switch true
      when not date_time? then on_error "no date" # no date found
      when uuid? and date_time? then on_id date_time, uuid # uuid found
      when error isnt "" then on_error error  # only error found
      when thumbnail_exists then build_id_from_thumbnail path, file, date_time, on_id, on_error
      else on_id date_time, file # no other info found, then return the file name as id

exports.get_data_time_and_uuid = (path, file, on_id, on_error) ->
  build_id_from_unique_id path, file, on_id, on_error
