import command from howl
ctags = bundle_load 'ctags'

register_commands = ->
  command.register
    name: 'ctags-generate',
    description: 'Generate the "tags" file using a command line tool'
    handler: ctags.generate_tags
    -- handler: ctags.generate_tags_async -- A version without the 'activity' popup

  command.register
    name: 'ctags-goto-definition',
    description: 'Go to the definition of the symbol under the cursor'
    handler: ctags.goto_definition

register_commands!

unload = ->
  command.unregister 'ctags-generate'
  command.unregister 'ctags-goto-definition'

return {
  info:
    author: 'Damian Gaweda'
    description: 'CTags support for Howl',
    license: 'MIT',
  :unload
}
