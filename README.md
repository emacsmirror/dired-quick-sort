# dired-quick-sort

This [Emacs][] package provides persistent quick sorting of [Dired][] buffers in various ways with
[hydra][].

## Screenshot

![](https://gitlab.com/xuhdev/dired-quick-sort/raw/master/screenshot.png)

## Installation

### MELPA

dired-quick-sort can be installed from the [MELPA][] repository. Follow the
[instructions](http://melpa.org/#/getting-started) to set up MELPA and then run
`package-install RET dired-quick-sort RET` to install.

### el-get

dired-quick-sort can be installed via [el-get][]. Follow the
[instructions](https://github.com/dimitri/el-get#installation) to set up el-get and then run
`el-get-install RET dired-quick-sort RET` to install.

### Manual Installation

Download this package and add the following to your `~/.emacs` or `~/.emacs.d/init.el`:

    (add-to-list 'load-path "~/path/to/dired-quick-sort")
    (load "dired-quick-sort.el")

## Requirements

This extension requires GNU ls (part of [GNU coreutils](https://www.gnu.org/software/coreutils/)) to
be present on the system. It is usually shipped by default on most GNU/Linux distributions. If you
are on MacOS, please refer to [this
guide](https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/)
for installing GNU command line tools.

## Configuration

Add the following to your `~/.emacs` or `~/.emacs.d/init.el` for a quick setup:

    (require 'dired-quick-sort)
    (dired-quick-sort-setup)

This will bind "S" in dired-mode to invoke the quick sort hydra and new Dired buffers are
automatically sorted according to the setup in this package. See the document of
`dired-quick-sort-setup` if you need a different setup. It is recommended that at least `-l` should
be put into `dired-listing-switches`. If used with `dired+`, you may want to set
`diredp-hide-details-initially-flag` to nil.

To use this extension, please make sure that the variable `insert-directory-program` points to the
GNU version of ls.

Alternatively, to suppress warning and silently fail when you don't have the appropriate system
environment set up, set `dired-quick-sort-suppress-setup-warning` to t:

    (setq dired-quick-sort-suppress-setup-warning t)

## TRAMP Support

You may be able to use this package when your are using TRAMP, but the actual sorting may be only
working partly. This is likely due to the fact that TRAMP has its own way of listing files, of which
I don't have a good grasp.

## Questions, Comments, Bug Report, Feature Request and Contribution

Please send all comments, questions, bug reports and feature requests to the
[issue tracker](https://gitlab.com/xuhdev/dired-quick-sort/issues). To contribute, please create a
[merge request](https://gitlab.com/xuhdev/dired-quick-sort/merge_requests).


[Emacs]: https://www.gnu.org/software/emacs/
[Dired]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired.html
[MELPA]: http://melpa.org/#/dired-quick-sort
[el-get]: http://tapoueh.org/emacs/el-get.html
[hydra]: https://github.com/abo-abo/hydra
