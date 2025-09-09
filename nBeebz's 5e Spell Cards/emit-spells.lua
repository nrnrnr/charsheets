#!/usr/bin/env lua5.1
--------------------------------------------------------------------------
-- emit-spells.lua — Emit LaTeX spell-card calls from YAML
-- Usage examples:
--   emit-spells.lua Druid 1                 # write \card lines to stdout
--   emit-spells.lua Druid 1 -o druid.tex    # write full .tex file
--   emit-spells.lua Druid 1 -o druid.pdf    # write and compile to PDF
--   emit-spells.lua Druid 1 -x "Fog Cloud" -x "Sleep"
--------------------------------------------------------------------------

------------------ classic print functions ---------------------
local stringf = string.format
local function printf(...) return io.stdout:write(stringf(...)) end
local function eprintf(...) return io.stderr:write(stringf(...)) end
local function dief(...) eprintf(...); os.exit(1) end

local function slurp(path)
  local f, msg = io.open(path, 'rb')
  if not f then return nil, msg end
  local s = f:read('*a')
  f:close()
  return s
end

local function set_contents(path, s)
  local f, msg = io.open(path, 'wb')
  if not f then return nil, msg end
  f:write(s)
  f:close()
  return true
end

local function file_readable(path)
  local f = io.open(path, 'rb')
  if f then f:close(); return true else return false end
end

--------------------------------------------------------------------------

local flags = require 'flags'
local fields = flags.parser()
  :output_file('output as o'):help('output file (.tex or .pdf)')
  :string_list('exclude as x'):help('exclude spell (case-sensitive; repeat)')
  :numarg(2)
  :parse(arg)

local CLASS, LEVELSTR = arg[1], arg[2]
local LEVEL = tonumber(LEVELSTR)
if not LEVEL then
  dief("Level must be a number: %q\n", tostring(LEVELSTR))
end

--

-- Hardcoded absolute path to Spell Cards directory (with trailing slash)
local CARDS_DIR = "/home/nr/etc/dnd/resources/nBeebz's 5e Spell Cards/Spell Cards/"

-- YAML path
local YAML_PATH = "/home/nr/etc/dnd/resources/spells.yaml"

local lyaml = require 'lyaml'

local yaml_text, msg = slurp(YAML_PATH)
if not yaml_text then dief("Cannot read %s: %s\n", YAML_PATH, msg or 'unknown error') end

local ok, doc = pcall(lyaml.load, yaml_text)
if not ok then dief("Failed to parse YAML: %s\n", tostring(doc)) end
if type(doc) ~= 'table' then dief("Unexpected YAML root type: %s\n", type(doc)) end

local class_tbl = doc[CLASS]
if not class_tbl then dief("Class not found in YAML: %s\n", tostring(CLASS)) end
if type(class_tbl) ~= 'table' then dief("Class entry is not a table: %s\n", tostring(CLASS)) end

-- Build exclusion set (case-sensitive)
local exclude_set = {}
local function add_exclusion(name)
  if name and name ~= '' then exclude_set[name] = true end
end
-- From -x flags
if fields.exclude then
  for _, name in ipairs(fields.exclude) do add_exclusion(name) end
end
-- From EXCLUDED_SPELLS env (comma-separated)
do
  local env = os.getenv('EXCLUDED_SPELLS')
  if env and env ~= '' then
    for item in tostring(env):gmatch('[^,]*') do
      -- trim leading/trailing whitespace; ignore empty elements
      local trimmed = item:gsub('^%s+', ''):gsub('%s+$', '')
      add_exclusion(trimmed)
    end
  end
end

local function excluded(name)
  return exclude_set[name] or false
end

-- Validate spell names (letters, spaces, apostrophes). Warn on suspicious ones.
local function is_clean_name(name)
  return name:match("^[A-Za-z '%-]+$") ~= nil  -- allow hyphen just in case
end

-- Collect known spells for validation and groups in order: Cantrips, then 1..LEVEL
local known_spells = {}
do
  for k, v in pairs(class_tbl) do
    if (k == 'Cantrips' or type(k) == 'number') and type(v) == 'table' then
      for _, name in ipairs(v) do known_spells[tostring(name)] = true end
    end
  end
end

-- Validate excludes are known spell names (case-sensitive)
do
  local unknown = {}
  for name, _ in pairs(exclude_set) do
    if not known_spells[name] then table.insert(unknown, name) end
  end
  if #unknown > 0 then
    table.sort(unknown)
    dief("Unknown spell(s) on exclusion list for %s: %s\n",
         CLASS, table.concat(unknown, ", "))
  end
end

-- Now build groups to emit
local groups = {}
local order = {}
if class_tbl['Cantrips'] then
  groups['Cantrips'] = class_tbl['Cantrips']
  table.insert(order, 'Cantrips')
end
for n = 1, LEVEL do
  if class_tbl[n] then
    groups[n] = class_tbl[n]
    table.insert(order, n)
  end
end

-- Build emitted lines, detect missing cards and suspicious names
local emitted = {}
local suspicious = {}
local missing_cards = {}

local function cmp(a, b) return a < b end  -- plain string sort

for idx, key in ipairs(order) do
  local spells = {}
  for _, name in ipairs(groups[key]) do
    if not excluded(name) then
      table.insert(spells, tostring(name))
    end
  end
  table.sort(spells, cmp)

  -- Emit \card lines
  for _, name in ipairs(spells) do
    if not is_clean_name(name) then
      table.insert(suspicious, name)
    end
    local img = CARDS_DIR .. name .. ".png"
    if not file_readable(img) then
      table.insert(missing_cards, name)
    end
    table.insert(emitted, stringf("\\card{%s}", name))
  end

  if idx < #order then
    table.insert(emitted, "")
    table.insert(emitted, "\\vspace*{1in}")
    table.insert(emitted, "")
  end
end

-- Report warnings to stderr
if #suspicious > 0 then
  eprintf("Warning: suspicious spell names (non [A-Za-z ' -]):\n")
  table.sort(suspicious, cmp)
  for _, n in ipairs(suspicious) do eprintf("  %s\n", n) end
end
if #missing_cards > 0 then
  eprintf("Warning: no card image found under %s for:\n", CARDS_DIR)
  table.sort(missing_cards, cmp)
  for _, n in ipairs(missing_cards) do eprintf("  %s\n", n) end
end

local function emit_cards_only()
  printf("%s\n", table.concat(emitted, "\n"))
end

local function full_document_body()
  local lines = {}
  -- Minimal preamble based on druid.tex
  table.insert(lines, "\\documentclass{article}")
  table.insert(lines, "\\usepackage[margin=0.5cm,head=0pt,foot=0pt]{geometry}")
  table.insert(lines, "\\pagestyle{empty}")
  table.insert(lines, "\\thispagestyle{empty}")
  table.insert(lines, "\\parindent=0pt")
  table.insert(lines, "\\usepackage{graphicx}")
  table.insert(lines, "")
  -- Card macro with absolute path and trim, matching druid.tex behavior
  table.insert(lines, stringf([[\def\card#1{{\includegraphics[height=0.26\vsize,trim=6mm 6mm 6mm 6mm,clip]{%s#1.png}}}]], CARDS_DIR))
  -- Spacing helper matching druid.tex
  table.insert(lines, [[
\newdimen\myspace
\myspace=10pt
\newcommand\nospaces{%
  \spaceskip=\myspace plus \myspace minus \myspace
  \xspaceskip=\myspace plus \myspace minus \myspace
  \baselineskip=\myspace
  \lineskip=\myspace
}]])
  table.insert(lines, "\\begin{document}")
  table.insert(lines, "\\raggedright")
  table.insert(lines, "\\nospaces")
  table.insert(lines, "")
  for _, line in ipairs(emitted) do table.insert(lines, line) end
  table.insert(lines, "")
  table.insert(lines, "\\end{document}")
  return table.concat(lines, "\n")
end

local function ends_with(s, suffix)
  return s:sub(-#suffix) == suffix
end

-- Simple shell quoting (borrowed style from charsheet)
local quote_me = "[^%w%+%-%=%@%_%/%.%:]"
local function shell_quote(s)
  if s:find(quote_me) or s == '' then
    return "'" .. string.gsub(s, "'", [['"'"']]) .. "'"
  else
    return s
  end
end

local function emit_to_output()
  local output = fields.output
  if not output then
    return emit_cards_only()
  end
  local doc = full_document_body()
  if ends_with(output, '.tex') then
    local ok, errmsg = set_contents(output, doc)
    if not ok then dief("Cannot write %s: %s\n", output, errmsg or 'unknown error') end
  elseif ends_with(output, '.pdf') then
    local pdflatex = 'pdflatex -interaction=nonstopmode -halt-on-error -file-line-error'
    local runlatex = [=[
pdflatex=$PDFLATEX
output=$OUTPUT

rm -f "$OUTPUT"
dir="$(mktemp -d)"
trap "rm -rf $dir" 0
tee "$dir/spells.tex" > /dev/null
$pdflatex -output-directory "$dir" "$dir/spells.tex"
rc=$?
if [[ $rc != 0 ]]; then exit $rc; fi
if [[ -r "$dir/spells.pdf" ]]; then cp "$dir/spells.pdf" "$output"; else exit 1; fi
]=]
    local cmd = runlatex:gsub('%$PDFLATEX', shell_quote(pdflatex))
                       :gsub('%$OUTPUT', shell_quote(output))
    local fd = assert(io.popen(stringf('bash -c %s', shell_quote(cmd)), 'w'))
    fd:write(doc)
    fd:close()
    -- Best-effort check
    local okpdf = file_readable(output)
    if not okpdf then os.exit(1) end
  else
    dief("Unsupported -o target (use .tex or .pdf): %s\n", output)
  end
end

emit_to_output()
