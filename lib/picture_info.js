/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
/*

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

*/


const child_process = require('child_process');
// returns a unique id for a file

const build_id_from_thumbnail = function(path, file, date_time, on_id, on_error) {
  // build a uuid by computing the sha of the thumbnail
  const path_file = `${path}/${file}`.replace(/[ ]/g, "\\ ");
  const shell_command = `exiftool -b -ThumbnailImage ${path_file} | shasum`;
  const exif = child_process.spawn('sh', ['-c', shell_command]);
  let uuid = "";
  let error = "";
  exif.on('error', err => error += `(build_id_from_thumbnail) ${err}`);
  exif.stderr.on('data', data => error += `(build_id_from_thumbnail) ${data}`);
  exif.stdout.on('data', function(data) { if (data != null) { return uuid += `${data}`.trim(); } });
  return exif.on('close', function() {
    if (uuid !== "") {
      return on_id(date_time, uuid); // uuid found
    } else {
      return on_id(date_time, file);
    }
  }); // no uuid found, set file name as uuid
};

const build_id_from_unique_id = function(path, file, on_id, on_error) {
  // first try to get the picture uuid (exif 2.0)
  const exif = child_process.spawn('exiftool', ["-S", "-json", "-DateTimeOriginal", "-MediaCreateDate", "-FileModifyDate", "-ImageUniqueID", "-ThumbnailImage", `${path}/${file}`]);
  let uuid = null;
  let error = "";
  let date_time = null;
  let thumbnail_exists = false;
  exif.on('error', err => error += `(build_id_from_unique_id) ${err}`);
  exif.stderr.on('data', data => error += `(build_id_from_unique_id) ${data}`);
  exif.stdout.on('data', function(data) {
    data = JSON.parse(data);
    if (data.length === 1) {
      date_time = data[0].DateTimeOriginal != null ? data[0].DateTimeOriginal.trim() : undefined;
      if (date_time == null) { date_time = data[0].MediaCreateDate != null ? data[0].MediaCreateDate.trim() : undefined; }
      if (date_time == null) { date_time = data[0].FileModifyDate != null ? data[0].FileModifyDate.trim() : undefined; }
      thumbnail_exists = (data[0].ThumbnailImage != null);
      return uuid = data[0].ImageUniqueID != null ? data[0].ImageUniqueID.trim() : undefined;
    }
  });
  return exif.on('close', function() {
    switch (true) {
      case (date_time == null): return on_error("no date"); // no date found
      case (uuid != null) && (date_time != null): return on_id(date_time, uuid); // uuid found
      case error !== "": return on_error(error);  // only error found
      case thumbnail_exists: return build_id_from_thumbnail(path, file, date_time, on_id, on_error);
      default: return on_id(date_time, file);
    }
  }); // no other info found, then return the file name as id
};

exports.get_data_time_and_uuid = (path, file, on_id, on_error) => build_id_from_unique_id(path, file, on_id, on_error);
