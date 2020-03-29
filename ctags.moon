{:app, :interact, :Project} = howl
{:File} = howl.io
{:PropertyTable} = howl.util

get_project_root = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory
  error "No file associated with the current view" unless file
  project = Project.get_for_file file
  error "No project associated with #{file}" unless project
  return project.root

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

  -- tags = {}
  location = nil

  for line in io.lines tags_file.path do
    unless line\starts_with('!')
      -- { tag, file, search, type } = line\split '\t'
      -- table.insert(tags, { tag, file, line_no, type })
      { tag, file } = line\split '\t'

      -- TODO: There can be multiple matches. At the moment we just jump to the first.
      -- Also, maybe support displaying Haskell instances for a data type?
      if tag == query_tag
        location =
          file: tags_dir\join file\usub(3)
          line_nr: line\umatch 'line:(%d+)'
          -- print "Found #{tag}, location #{location.file} #{location.line_nr}"
        break

  if location
    app\open location
  else
    log.error "Tag #{query_tag} not found!"

PropertyTable {
  :goto_definition,
}
