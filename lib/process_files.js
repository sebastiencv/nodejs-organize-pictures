/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const data_in = "/Volumes/Data/Pictures/SortedPictures/ToSort"
const data_out = "/Volumes/Data/Pictures/SortedPictures"
const data_duplicate = "/Volumes/Data/Pictures/SortedPictures/Duplicates"

const fs = require("fs")
const walk = require("walk")
const mkpath = require("mkpath")
const picture_info = require("./picture_info")
const picture_unique_in_folder = require("./picture_unique_in_folder")

// search all files in input folder
const walker  = walk.walk(data_in, { followLinks: false })
walker.on("file", function(root, fileStat, next) {
  if (fileStat.name.charAt(0) === ".") {
    return next()
  } else {
    const source_file = `${root}/${fileStat.name}`
    return picture_info.get_data_time_and_uuid(root, fileStat.name
    , function(date_time, unique_id) {
      const [year, month] = Array.from(date_time.split(/[: ]/))
      const target_dir = `${data_out}/${year}/${month}`
      return mkpath(target_dir, function(err) {
        if (err != null) {
          console.log(`* Error creating target folders : ${err}`.trim())
          return next();
        } else {
          // check if the file must be added
          return picture_unique_in_folder.is_picture_to_add(target_dir, unique_id
          , function(is_to_add) {
            let move_to;
            const target_file = `${target_dir}/${fileStat.name}`
            if (is_to_add) {
              move_to = target_file;
            } else {
              move_to = `${data_duplicate}/${fileStat.name}`
            }
            return fs.rename(source_file, move_to, function(err) {
              if (err != null) {
                console.log(`Error moving ${source_file} to ${target_file} : ${err}`)
              } else {
                if (is_to_add) {
                  console.log(fileStat.name, "->", target_file)
                } else {
                  console.log(fileStat.name, "already in", target_file)
                }
              }
              return next()
            })
          })
        }
      })
    }
    , function(error) {
      console.log("*", source_file, `${error}`.trim())
      return next()
    })
  }
})
