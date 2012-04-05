# VPBlog, a static weblog generator for VoodooPad

Right now, this guy isn't exactly ready from primetime use.  And it also exposes a bunch of private APIs in VoodooPad that Gus is working to try and make public versions for.

But if you want to play, read on.

## Requirements:
VPBlog requires VoodooPad 5.0.1 or later.

## Installing:
Drag and drop VPBlog.vpplugin onto VoodooPad 5, and it will offer to install it into your plugins directory.  Relaunch VoodooPad, and it will show up in the palettes list.

## Usage:
***Note:** you should play with this on a brand new document.*

Once you see the VPBlog entry in VoodooPad's palette, you're going to want to click the "Setup" button.  This will modify your document to make Markdown pages the default new page type, as well as creating the following pages:

**VPBlogExportScript**
This is a JavaScript / JSTalk page that contains event methods for you to fill out if you wish.  You can use this to alter the output of your site.

**VPWebExportPageTemplate**
This is the default page that is used in VoodoooPad documents for web export.  It makes sense to also use it in VPBlog.  This is a wrapper for your pages, and it contains css and such.

**VPBlogPageEntryTemplate**
This is similar to VPWebExportPageTemplate, but it's for a single entry in your blog.  It'll be used one or more times on your front page, and a single time for the archive pages.

## Scriptlets:
You can use scriptlets in your posts and templates.  You can read about VoodooPad's scriptlet support here: http://flyingmeat.com/voodoopad/docs-5/scriptlets.html





