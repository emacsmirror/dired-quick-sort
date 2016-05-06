# dired-quick-sort

This [Emacs][] package provides persistent quick sorting of [Dired][] buffers in various ways with
[hydra][].

## Screenshot

![](https://gitlab.com/xuhdev/dired-quick-sort/raw/master/screenshot.png)

## Installation

### Manual Installation

Download this package and add the following to your `~/.emacs` or `~/.emacs.d/init.el`:

    (add-to-list 'load-path "~/path/to/dired-quick-sort")
    (load "dired-quick-sort.el")

## Configuration

Add the following to your `~/.emacs` or `~/.emacs.d/init.el` for a quick setup:

    (require 'dired-quick-sort)
    (dired-quick-sort-setup)

This will bind "S" in dired-mode to invoke the quick sort hydra and new Dired buffers are
automatically sorted according to the setup in this package. See the document of
`dired-quick-sort-setup` if you need a different setup. It is recommended that at least `-l` should
be put into `dired-listing-switches`.


[Emacs]: https://www.gnu.org/software/emacs/
[Dired]: https://www.gnu.org/software/emacs/manual/html_node/emacs/Dired.html
[hydra]: https://github.com/abo-abo/hydra
