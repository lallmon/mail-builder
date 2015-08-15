# MailBuilder.io

This is an amalgamation of [Grunt-Email-Workflow](https://github.com/leemunroe/grunt-email-workflow) for building emails, combined with the awesome [responsive layout system from Ink](https://github.com/zurb/ink)

DOCS FROM ORIGINAL REPO MOVED TO WIKI

Notes:

Gmail does't allow media queries, so to make fully supported mobile responsive email templates, we need to use the [BLOCK GRID](http://zurb.com/ink/docs.php) from Ink. Not as sexy, but wider support

# TODO

- Allow the users to edit the color/config variables from the front end which applies to templates globally.
- Allow the editing of the resources from the front-end, images, urls, copy, etc
- Provide the exposed/non-parsed HTML and Text versions for pasting into an ESP
- Only expose command line stuff if there are errors.
- Set up a better interface using React.js
- Start working on the Data model with Firebase
- Can we do this without the RUBY premailer gem (Perhaps using the Premailer API)
