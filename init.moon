import command, interact from howl
ctags = bundle_load 'ctags'

register_commands = ->

  command.register
    name: 'ctags-goto-definition',
    description: 'Go to the definition of the symbol under the cursor'
    -- input: interact.read_text
    handler: () ->
      ctags.goto_definition!

register_commands!

unload = ->
  command.unregister 'ctags-goto-definition'

return {
  info:
    author: 'Damian Gaweda'
    description: 'CTags support for Howl',
    license: 'MIT',
  :unload
}
