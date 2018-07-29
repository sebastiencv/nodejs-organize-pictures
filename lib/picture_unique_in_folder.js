/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const walk = require("walk");
const picture_info = require("./picture_info");

const folders_uuid = {}; // will contain the list of all uuid in each folder

var is_picture_to_add = function(folder, picture_uuid, is_to_add) {
  if (folders_uuid[folder] != null) { // folder info exists
    if (folders_uuid[folder][picture_uuid] != null) {
      return is_to_add(false); // uuid already exist in that folder
    } else {
      folders_uuid[folder][picture_uuid] = true; // save the uuid exists now
      return is_to_add(true); // must be added
    }
  } else {
    return read_folder_uuids(folder, () => is_picture_to_add(folder, picture_uuid, is_to_add));
  }
};

// collect all uuid for this folder
var read_folder_uuids = function(folder, done) {
  if (folders_uuid[folder] == null) { folders_uuid[folder] = {}; }
  const walker  = walk.walk(folder, { followLinks: false });
  walker.on("file", function(root, fileStat, next) {
    if (fileStat.name.charAt(0) === ".") {
      return next();
    } else {
      return picture_info.get_data_time_and_uuid(root, fileStat.name
      , function(date_time, unique_id) {
        folders_uuid[folder][unique_id] = fileStat.name; // save the uuid exists now
        return next();
      }
      , function(error) {
        console.log(`* could not read uuid from ${root}/${fileStat.name}`);
        return next();
      });
    }
  });
  return walker.on("end", done);
};


exports.is_picture_to_add = (folder, picture_uuid, is_to_add) => is_picture_to_add(folder, picture_uuid, is_to_add);
