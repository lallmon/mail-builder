module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    secrets: grunt.file.readJSON('secrets.json')
    paths:
      src: 'src'
      src_img: 'src/img'
      dist: 'dist'
      dist_img: 'dist/img'
      preview: 'preview'
    sass:
      dist:
        options: style: 'expanded'
        files: '<%= paths.src %>/css/main.css': '<%= paths.src %>/css/scss/main.scss'
      preview:
        options: style: 'compressed'
        files: '<%= paths.preview %>/css/preview.css': '<%= paths.preview %>/scss/preview.scss'
    assemble:
      options:
        layoutdir: '<%= paths.src %>/layouts'
        partials: [ '<%= paths.src %>/partials/**/*.hbs' ]
        helpers: [ '<%= paths.src %>/helpers/**/*.js' ]
        data: [ '<%= paths.src %>/data/*.{json,yml}' ]
        flatten: true
      pages:
        src: [ '<%= paths.src %>/emails/*.hbs' ]
        dest: '<%= paths.dist %>/'
    replace: src_images:
      options:
        usePrefix: false
        patterns: [
          {
            match: /(<img[^>]+[\"'])(\.\.\/src\/img\/)/gi
            replacement: '$1../<%= paths.dist_img %>/'
          }
          {
            match: /(url\(*[^)])(\.\.\/src\/img\/)/gi
            replacement: '$1../<%= paths.dist_img %>/'
          }
        ]
      files: [ {
        expand: true
        flatten: true
        src: [ '<%= paths.dist %>/*.html' ]
        dest: '<%= paths.dist %>'
      } ]
    premailer:
      html:
        options: removeComments: true
        files: [ {
          expand: true
          src: [ '<%= paths.dist %>/*.html' ]
          dest: ''
        } ]
      txt:
        options: mode: 'txt'
        files: [ {
          expand: true
          src: [ '<%= paths.dist %>/*.html' ]
          dest: ''
          ext: '.txt'
        } ]
    imagemin: dynamic:
      options:
        optimizationLevel: 3
        svgoPlugins: [ { removeViewBox: false } ]
      files: [ {
        expand: true
        cwd: '<%= paths.src_img %>'
        src: [ '**/*.{png,jpg,gif}' ]
        dest: '<%= paths.dist_img %>'
      } ]
    watch:
      emails:
        files: [
          '<%= paths.src %>/css/scss/*'
          '<%= paths.src %>/emails/*'
          '<%= paths.src %>/layouts/*'
          '<%= paths.src %>/partials/*'
          '<%= paths.src %>/data/*'
          '<%= paths.src %>/helpers/*'
        ]
        tasks: [ 'default' ]
      preview_dist:
        files: [ './dist/*' ]
        tasks: []
        options: livereload: true
      preview:
        files: [ '<%= paths.preview %>/scss/*' ]
        tasks: [
          'sass:preview'
          'autoprefixer:preview'
        ]
        options: livereload: true
    mailgun: mailer:
      options:
        key: '<%= secrets.mailgun.api_key %>'
        sender: '<%= secrets.mailgun.sender %>'
        recipient: '<%= secrets.mailgun.recipient %>'
        subject: 'This is a test email'
      src: [ '<%= paths.dist %>/' + grunt.option('template') ]
    cloudfiles: prod:
      'user': '<%= secrets.cloudfiles.user %>'
      'key': '<%= secrets.cloudfiles.key %>'
      'region': '<%= secrets.cloudfiles.region %>'
      'upload': [ {
        'container': '<%= secrets.cloudfiles.container %>'
        'src': '<%= paths.dist_img %>/*'
        'dest': '/'
        'stripcomponents': 0
      } ]
    cdn:
      cloudfiles:
        options:
          cdn: '<%= secrets.cloudfiles.uri %>'
          flatten: true
          supportedTypes: 'html'
        cwd: './<%= paths.dist %>'
        dest: './<%= paths.dist %>'
        src: [ '*.html' ]
      aws_s3:
        options:
          cdn: '<%= secrets.s3.bucketuri %>/<%= secrets.s3.bucketname %>/<%= secrets.s3.bucketdir %>'
          flatten: true
          supportedTypes: 'html'
        cwd: './<%= paths.dist %>'
        dest: './<%= paths.dist %>'
        src: [ '*.html' ]
    aws_s3:
      options:
        accessKeyId: '<%= secrets.s3.key %>'
        secretAccessKey: '<%= secrets.s3.secret %>'
        region: '<%= secrets.s3.region %>'
        uploadConcurrency: 5
        downloadConcurrency: 5
      prod:
        options:
          bucket: '<%= secrets.s3.bucketname %>'
          differential: true
          params: CacheControl: '2000'
        files: [ {
          expand: true
          cwd: '<%= paths.dist_img %>'
          src: [ '**' ]
          dest: '<%= secrets.s3.bucketdir %>/<%= paths.dist_img %>'
        } ]
    litmus: test:
      src: [ '<%= paths.dist %>/' + grunt.option('template') ]
      options:
        username: '<%= secrets.litmus.username %>'
        password: '<%= secrets.litmus.password %>'
        url: 'https://<%= secrets.litmus.company %>.litmus.com'
        clients: [
          'android4'
          'aolonline'
          'androidgmailapp'
          'aolonline'
          'ffaolonline'
          'chromeaolonline'
          'appmail6'
          'iphone6'
          'ipadmini'
          'ipad'
          'chromegmailnew'
          'iphone6plus'
          'notes85'
          'ol2002'
          'ol2003'
          'ol2007'
          'ol2010'
          'ol2011'
          'ol2013'
          'outlookcom'
          'chromeoutlookcom'
          'chromeyahoo'
          'windowsphone8'
        ]
    autoprefixer: preview:
      options: browsers: [
        'last 6 versions'
        'ie 9'
      ]
      src: 'preview/css/preview.css'
    express: server: options:
      port: 4000
      hostname: '127.0.0.1'
      bases: [
        '<%= paths.dist %>'
        '<%= paths.preview %>'
        '<%= paths.src %>'
      ]
      server: './server.js'
      livereload: true
    open: preview: path: 'http://localhost:4000'

  # Load assemble
  grunt.loadNpmTasks 'assemble'
  # Load all Grunt tasks
  # https://github.com/sindresorhus/load-grunt-tasks
  require('load-grunt-tasks') grunt
  # Where we tell Grunt what to do when we type "grunt" into the terminal.
  grunt.registerTask 'default', [
    'sass'
    'assemble'
    'premailer'
    'imagemin'
    'replace:src_images'
  ]
  # Use grunt send if you want to actually send the email to your inbox
  grunt.registerTask 'send', [ 'mailgun' ]
  # Upload images to our CDN on Rackspace Cloud Files
  grunt.registerTask 'cdnify', [
    'default'
    'cloudfiles'
    'cdn:cloudfiles'
  ]
  # Upload image files to Amazon S3
  grunt.registerTask 's3upload', [
    'aws_s3:prod'
    'cdn:aws_s3'
  ]
  # Launch the express server and start watching
  # NOTE: The server will not stay running if the grunt watch task is not active
  grunt.registerTask 'serve', [
    'default'
    'autoprefixer:preview'
    'express'
    'open'
    'watch'
  ]
