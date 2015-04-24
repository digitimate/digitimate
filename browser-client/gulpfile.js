var gulp = require('gulp');
var concat = require('gulp-concat');
var uglify = require('gulp-uglify');

gulp.task('default', function () {
  return gulp.src('digitimate.js')
    .pipe(uglify())
    .pipe(concat('digitimate.min.js'))
    .pipe(gulp.dest('.'));
});
