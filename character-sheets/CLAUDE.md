# Overall guidance

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

The user always prefers simple solutions with minimal dependencies.

The user hates repetitive and near-repetitive code.  When possible, eliminate or reduce such code by using table-driven approaches and first-class functions.

Whenever the users asks Claude to tackle a substantial coding task, whether it's new code or an edit, Claude should first pause, think of what questions it has or what assumptions it may be making, then ask those questions.  Basically, treat any significant request as being followed by "But first, what questions do you have?"

## This project

We're working on a D&D character sheet generation system that converts YAML character data into professional LaTeX-typeset character sheets. The system consists of:

- `charsheet.sty` LaTeX package: declares every variable that may
  appear in YAML, using either `\newDND` or `\newDNDitems`.  Also
  contains a plethora of macros used to query variables and render
  character sheets.  As well as custom shapes for TikZ.

    The core macros are as follows:

    - `\setDND{key}{value}` - Set character data
    - `\setDNDfont{field}{font}` - Set font for specific fields
    - `\addDNDitem[<weight>]{<category>}{<item>}` - Add an item of equipment to a list
    - `\dndkeys{key1={val1},key2={val2}}` - Specify keyword properties, as for attacks
    - `\described{name}{description}` - For features and spells
    - `\spellslevel[numslots]{level}` - Gives level of spells that are to follow, with optionally the number of slots of that level


- `YAML.md`: documentation that defines the meaning and format of every variable declared in `charsheet.sty`.

- `charsheet` script: Reads YAML data, supplement where needed by adding missing fields, and renders the data into the variables declared in `charsheet.sty`.

- `caster.tex` and `3col.tex`: two alternative styles for rendering character sheets.  `caster.tex` is the primary style; it looks good and has been exercised significantly.  `3col.tex` is still in the prototype stage.

- `QUICKSTART.yaml`: documentation that uses examples of valid YAML files to help human creators get started. The background colors in the quick-start guide match the corresponding colors used defined in `charsheet.sty` and used in `caster.tex`.

- `character-form.html`: A web form, plus JavaScript, that provides a means of creating a character sheet by filling in the form, without knowing the YAML.  This form includes a button that forwards YAML to a web service that is backed by the `charsheet` script.  **Important:** The form must send the YAML data raw, and the form just trust the server's response, complete with headers.  It must never try to capture or massage the server's response.  Let the browser take care of it.

### Ancillary components

- `charinfo` - Lua script for DM info sheets with multiple characters
- `key-declarations` - Generates \newDND{} declarations for all YAML keys

## Example files

Example YAML files may be found here in `*.yaml` as well as in `/home/nr/etc/dnd/my-adventures/*.yaml`.


## Common Commands

### Generate a character sheet
```bash
# From YAML to PDF
./charsheet -o character.pdf character.yaml

# From YAML to LaTeX (for debugging)
./charsheet -o character.tex character.yaml

# Just the macro definitions (no template)
./charsheet -s character.yaml > macros.tex
```

### Generate DM info sheet
```bash
# Multiple characters for DM reference
./charinfo character1.yaml character2.yaml character3.yaml > dm-sheet.tex
pdflatex dm-sheet.tex
```

### Generate key declarations
```bash
# Create LaTeX declarations for all YAML keys found
./key-declarations *.yaml > keys.tex
```

### Test compilation
```bash
# Compile any .tex file to PDF
pdflatex filename.tex
```

## LaTeX Style System

The `charsheet.sty` package provides:

### Core Macros

### Visual Elements
- TikZ-based decorative boxes with rounded corners
- Color-coded sections (stats, proficiencies, attacks, magic, etc.)
- Custom shapes for coins, hit point boxes, etc.

### Layout Components
- Responsive column layouts
- Automatic text wrapping and spacing

## File Naming Conventions

- Character YAML files: `character-name.yaml`
- Generated LaTeX: `character-name.tex`
- Template files: `template-name.tex` (e.g., silverpine.tex)
- Generated PDFs follow input name with .pdf extension

## Dependencies

- **lua5.1** - Script runtime
- **lyaml** - YAML parsing library
- **pdflatex** - LaTeX compilation (from TeX Live)
- **Required LaTeX packages**: tikz, times, xcolor, colortbl, tabularx, booktabs, calc, etc.

## HTML and CSS

Never use `nth-child` in CSS.  At need, invent a new class and label the child.

## Common Troubleshooting

- Ensure all YAML files use double quotes for keys that have spaces
- Check that ability scores are numeric

## Markdown documentation

Documentation is written using Pandoc Markdown with HTML extensions.  Outputs should include a title using the opening `%` sign, and the body should be wrapped in <article>...</article>, which will provide a hook for CSS.

The Markdown should include a Pandoc metadata block with the `article` and `body` tags from `/home/nr/cs/106/server/www/course.css`.

# What to do when adding a new YAML field

 1. Update YAML.md and QUICKSTART.md.  If uncertain of examples for
    QUICKSTART.md, ask the user where to find an example.

 2. Add a declaration of the field to `charsheet.sty`

 3. Ask the user whether he wants to add a rendering to `caster.tex`.

 4. Ask the user whether to add support for the field in `character-form.html`.


### Web form version markers

**IMPORTANT**: Every time `character-form.html` changes, its internal "Version"
string needs to be updated.  Our convention is to name each version
after a vegetable or other food category.  The next version gets a new
vegetable with its initial letter advancing by one letter of the
alphabet.  For example: eggplant could be followed by fennel which
could be followed by garlic.  If Claude can't think of an appropriate
food it is OK to skip a difficult letter like X or Z.

### Special treatment of CLASS and LEVEL fields

A character's CLASS and LEVEL fields are expected to be distinct.  However, both the web form and the `charsheet` script must support a legacy format that uses a single `"CLASS & LEVEL"` key to specify CLASS, LEVEL, and possibly BACKGROUND.  The legacy format may be found in existing YAML files.  Any component *reading* the legacy `"CLASS & LEVEL"` key will always parse it into separate fields. And any component *writing* YAML always uses the separate `CLASS` and `LEVEL` format.

### Web form requirements

An empty sheet or a sheet with no magic should just show the header "Magic (click to open)."  Clicking on it should open.
  
Spells should be segregated by level, each level in its own section.
A section is headed either "Cantrips" or "Level N spells (k slots)", where the N is fixed for each level but the k can be filled in by the user in a small textbox.

Initially, no empty magic sections should be shown.  And at the end of the last section there should be a box "open level N+1 spells," where "N+1" is as appropriate.  When opened, this section will be empty, and should be succeeded by a button to open level N+2 spells, and so on up through spell level 9.  There are no spells of level 10 or beyond.
  

## Troubleshooting

### PDF Generation "Failed to fetch" Error
If the character form's "Generate PDF" button gives a "Failed to fetch" error, remind the user that this commonly happens when accessing the form via a `file://` URL instead of through a web server. The PDF generation requires HTTP/HTTPS to make fetch requests to the server endpoint. The form must be served through a web server (like Apache) for the PDF generation to work properly.
