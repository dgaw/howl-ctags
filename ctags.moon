{:app, :interact, :Project, :activities, :config} = howl
{:Process} = howl.io
{:PropertyTable} = howl.util

get_project_root = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory
  error "No file associated with the current view" unless file
  project = Project.get_for_file file
  error "No project associated with #{file}" unless project
  return project.root

config.define
  name: 'ctags_command'
  description: 'Command line tool used to generate the "tags" file'
  default: 'ctags -R'
  type_of: 'string'

generate_tags = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory

  cmd = config.for_file(file).ctags_command
  cmd_with_args = {}
  for arg in cmd\gmatch '%S+'
    table.insert cmd_with_args, arg

  working_directory = get_project_root!

  success, ret = pcall Process.open_pipe, cmd_with_args, :working_directory
  if success
    process = ret
    out, err = activities.run_process {title: "Generating tags..."}, process
    unless process.successful
      msg = (if err.is_blank then out else err)\gsub '\n', '   '
      log.error "Error generating tags! #{cmd}: " .. msg
  else
    log.error ret

-- A version of generate_tags that doesn't block but doesn't show the nice
-- activity popup window. I can't decide which one is better so will try both for while.
generate_tags_async = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory

  cmd = config.for_file(file).ctags_command
  cmd_with_args = {}
  for arg in cmd\gmatch '%S+'
    table.insert cmd_with_args, arg

  working_directory = get_project_root!

  log.info "Generating tags..."

  out, err, p = Process.execute cmd_with_args, :working_directory
  if p.successful
    log.info "Done generating tags!"
  else
    msg = (if err.is_blank then out else err)\gsub '\n', '   '
    log.error "Error generating tags! #{cmd}: " .. msg

get_query_tag = ->
  editor = app.editor
  query = nil

  if editor.selection.empty
    query = editor.current_context.word.text
  else
    query = editor.selection.text

  if not query or query.is_empty
    query = interact.read_text prompt: "Enter tag name to jump to: "

  query

-- Search for the tags file, starting at the directory of the
-- currently edited file and going up until stop_dir is reached.
-- tags_filename: short file name of the tags file to look for. Typically 'tags' or 'TAGS'
get_tags_file = (tags_filename, stop_dir) ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory

  dir = file.parent
  tags_file = dir\join tags_filename

  if not tags_file.exists
    while dir != stop_dir do
      dir = dir.parent
      tags_file = dir\join tags_filename
      if tags_file.exists break

  tags_file, dir

goto_definition = ->
  query_tag = get_query_tag!
  if not query_tag or query_tag == ""
    log.error "No query tag specified!"
    return

  tags_file, tags_dir = get_tags_file "tags", get_project_root!
  unless tags_file.exists
    log.error "Tags file #{tags_file} doesn't exist!"
    return

  locations = {}
  found = false

  -- TODO: Inefficient. Find a better way to de-dupe locations.
  is_duplicate = (loc) ->
    for _, l in pairs locations
      if l.line_nr == loc.line_nr and l.file == loc.file
        return true
    return false

  for line in io.lines tags_file.path do
    unless line\starts_with('!')
      { tag, file } = line\split '\t'

      -- TODO: display Haskell instances for a data type? The info is in the tags file
      if tag == query_tag
        found = true
        line_nr = line\umatch 'line:(%d+)'
        file_relpath = file\usub(3)
        loc = {
          howl.ui.markup.howl "<comment>#{file_relpath}</>:<number>#{line_nr}</>"
          file: tags_dir\join file_relpath
          line_nr: tonumber line_nr
        }
        if not is_duplicate loc
          table.insert locations, loc
      else
        -- Speed optimisation. We assume that the tags file is sorted so we can break
        -- the loop when we leave the block of matching tags
        if found
          break

  if #locations == 1
    app\open locations[1]
  else if #locations > 1
    app\open interact.select_location
      title: "Definitions of '#{query_tag}' in #{tags_file.short_path}"
      items: locations
  else
    log.error "Tag #{query_tag} not found!"

PropertyTable {
  :generate_tags,
  :generate_tags_async,
  :goto_definition
}
