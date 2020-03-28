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

goto_definition = ->
  proj_root = get_project_root!
  query_tag = get_query_tag!

  tags_file = proj_root\join "tags"
  unless tags_file.exists
    log.error "Tags file #{tags_file} doesn't exist!"
    return

  -- tags = {}
  location = nil

  for line in io.lines tags_file.path do
    unless line\starts_with('!')
      -- { tag, file, search, type } = line\split '\t'
      { tag, file } = line\split '\t'
      line_nr = line\umatch 'line:(%d+)'
      -- table.insert(tags, { tag, file, line_no, type })

      -- TODO: There can be multiple matches. At the moment we just jump to the first.
      -- Also, maybe support displaying Haskell instances for a data type?
      if tag == query_tag
        location =
          file: proj_root\join file\usub(3)
          :line_nr
        -- print "Found #{tag}, location #{location.file} #{location.line_nr}"
        break

  if location
    app\open location
  else
    log.warn "Tag #{query_tag} not found!"

PropertyTable {
  :goto_definition,
}
