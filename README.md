# Howl Ctags

"Go to definition" for the Howl editor, which uses ctags-compatible files.

## Installation

Install the howl-ctags bundle

    cd ~/.howl/bundles
    git clone https://github.com/dgaw/howl-ctags

Add keyboard shortcuts to your `~/.howl/init.moon` file. E.g.

    bindings.push {
      editor:
        alt_enter: 'ctags-goto-definition'
        ctrl_shift_t: 'ctags-generate'
    }

## Usage

This bundle provides the following commands:

* `ctags-goto-definition` - go to the definition of the tag under the cursor. If there's no tag under the cursor, a prompt to enter a tag name to look up will be shown.

* `ctags-generate` - run the ctags binary to generate the "tags" file. The binary is run in the project root. Use the `ctags_command` configuration variable to customise the path and arguments for ctags.


