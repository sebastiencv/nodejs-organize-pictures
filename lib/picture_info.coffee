# Credits to https://github.com/nathanpeck/exiftool

child_process = require('child_process')
# returns a unique id for a file

build_id_from_thumbnail = (file, date_time, on_id, on_error) ->
  # build a uuid by computing the sha of the thumbnail
  shell_command = "exiftool -b -ThumbnailImage #{file} | shasum"
  exif = child_process.spawn 'sh', ['-c', shell_command]
  uuid = ""
  error = ""
  exif.on 'error', (err) -> error += err
  exif.stderr.on 'data', (data) -> error += data
  exif.stdout.on 'data', (data) -> uuid += "#{data}".trim() if data?
  exif.on 'close', ->
    switch true
      when uuid isnt "" then on_id date_time, uuid # uuid found
      when error isnt "" then on_error error # only error found
      else on_error "nothing found"

build_id_from_unique_id = (file, on_id, on_error) ->
  # frist try to get the picture uuid (exif 2.0)
  exif = child_process.spawn 'exiftool', ["-S", "-json", "-DateTimeOriginal", "-ImageUniqueID", file]
  uuid = null
  error = ""
  date_time = ""
  exif.on 'error', (err) -> error += err
  exif.stderr.on 'data', (data) -> error += data
  exif.stdout.on 'data', (data) ->
    data = JSON.parse data
    if data.length is 1
      date_time = data[0].DateTimeOriginal?.trim()
      uuid = data[0].ImageUniqueID?.trim()
  exif.on 'close', ->
    switch true
      when uuid? then on_id date_time, uuid # uuid found
      when error isnt "" then on_error error  # only error found
      else build_id_from_thumbnail file, date_time, on_id, on_error

exports.get_data_time_and_uuid = (file, on_id, on_error) ->
  build_id_from_unique_id file, on_id, on_error
