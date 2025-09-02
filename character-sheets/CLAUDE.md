# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Whenever I ask Claude to tackle a substantial coding task, whether it's new code or an edit, Claude should first pause, think of what questions it has or what assumptions it may be making, then ask those questions.  Basically just treat any significant request as being followed by "But first, what questions do you have?"

## Repository Overview

This is a D&D character sheet generation system that converts YAML character data into professional LaTeX-typeset character sheets. The system consists of:

- **YAML character data files** (*.yaml) - Human-readable character definitions
- **LaTeX style package** (charsheet.sty) - Provides custom macros and styling for character sheets
- **Lua conversion scripts** (charsheet) - Convert YAML to LaTeX macro calls
- **Template file** (caster.tex) - Defines character-sheet layout

## Core Architecture

### YAML to LaTeX Workflow

1. **Character data** is defined in YAML files with standardized keys (CHARACTER NAME, CLASS & LEVEL, STR, DEX, etc.)
2. **Lua scripts** parse YAML and generate LaTeX macro calls (\setDND{key}{value})
3. **LaTeX templates** use these macros to render formatted character sheets
4. **pdflatex** compiles the final PDF character sheets

### Key Components

- `charsheet` - Main Lua script for full character sheet conversion
- `charsheet.sty` - LaTeX package with character sheet styling and macros
- Template file (caster.tex, which is symlinked to silverpine.tex) - Character sheet layout

### Ancillary components

- `charinfo` - Lua script for DM info sheets with multiple characters
- `key-declarations` - Generates \newDND{} declarations for all YAML keys

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

## YAML Character Format

Character data uses standardized keys:

### Required Fields
- `"CHARACTER NAME"`, `"CLASS & LEVEL"`, `"RACE"`, `"BACKGROUND"`
- Ability scores: `STR`, `DEX`, `CON`, `INT`, `WIS`, `CHA`
- `"PROFICIENCY BONUS"`, `"ARMOR CLASS"`, `"MAX HP"`, etc.

### Structured Data
- `PROFICIENCIES` - List of strings, supports special skip markers
- `EQUIPMENT` - List of equipment items
- `ATTACKS` - List with NAME, ATTACK, DAMAGE, TYPE, RANGE, AMMO keys
- `MAGIC` - Spells with level markers and name/description pairs
- `FEATURES` - Character features with name/description pairs

### Special Conventions
- Proficiency bonus auto-adds + if missing
- Class determines saving throw proficiencies automatically
- Font settings use `"FIELD FONT"` pattern (e.g., `"MAGIC FONT": "\\small"`)

## LaTeX Style System

The `charsheet.sty` package provides:

### Core Macros
- `\setDND{key}{value}` - Set character data
- `\setDNDfont{field}{font}` - Set font for specific fields
- `\dndkeys{key1={val1},key2={val2}}` - For attack records
- `\described{name}{description}` - For features/spells
- `\spellslevel{level}` - Spell level headers

### Visual Elements
- TikZ-based decorative boxes with rounded corners
- Color-coded sections (stats, proficiencies, attacks, magic, etc.)
- Custom shapes for coins, hit point boxes, etc.

### Layout Components
- Responsive column layouts
- Automatic text wrapping and spacing
- Professional typography with Times font

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

- Ensure all YAML files use double quotes for keys with spaces
- Check that ability scores are numeric
- Verify template files exist in the templates directory (default: current directory)
- LaTeX compilation errors often indicate missing packages or malformed macro calls

## Markdown output

We'll be using Pandoc Markdown with HTML extensions.  Outputs should include a title using the opening `%` sign, and the body should be wrapped in <article>...</article>, which will provide a hook for CSS.

The Markdown should include a Pandoc metadata block with the `article` and `body` tags from `/home/nr/cs/106/server/www/course.css`.



# Key parts of the system

 1. Documentation: An alphabetical guide to all YAML keys (YAML.md).  The entry for each key says what it means, whether it is meaningfully usable on a character sheet, and whether it is optional or required on a character sheet, and whether it may be empty.  The entry also gives one or two examples of how the key can be used.

 2. `charsheet` script: fills in some missing entries in a YAML file, turns YAML into TeX definitions used in `caster.tex`.
 
 3. `caster.tex`: specifies typography, color, and layout for a PDF a character sheet.  Uses definitions emitted by `charsheet`.

 4. `charsheet.sty`: the core latex macros used in caster.tex.

 5. Documentation: A quick-start guide to the YAML, aimed at readers
    who may write or edit YAML by hand (QUICKSTART.md).  The
    background colors in the quick-start guide match the corresponding
    colors used defined in `charsheet.sty` and used in `caster.tex`.
 
 6. `character-form.html`: A web form, plus JavaScript, which provides
    a means of creating a character sheet by filling in the form,
    without known the YAML.  This form includes a button that forwards
    YAML to a web service of my design.  The form needs only to trust
    the server's response, complete with headers.  It must never try to capture or massage the server's response.  Let the browser take care of it.

### Steps 3-4 Implementation Details

- **Technology preferences**: Simple solutions with minimal dependencies preferred
- **Color scheme**: Colors defined in `charsheet.sty` (via `\colorlet`) match the colors in generated PDFs
- **Development environment**: Debian Linux + Apache + full LaTeX toolchain

# What to do when adding a new YAML field

 1. Update YAML.md and QUICKSTART.md.  If uncertain of examples for
    QUICKSTART.md, ask the user where to find an example.

 2. Ask the user whether he wants to add a rendering to `caster.tex`.

 3. Ask the user whether to add support for the field in `character-form.html`.


### Web Form Changes

The character-form.html web form generates YAML using separate `CLASS` and `LEVEL` fields rather than the combined `"CLASS & LEVEL"` field approach found in existing YAML files. This provides better form usability with dropdowns and number inputs.

When loading existing YAML files that use `"CLASS & LEVEL"`, the form will parse this into separate fields. When saving, it always uses the separate `CLASS` and `LEVEL` format.

How to handle the magic section:

  - An empty sheet or a sheet with no magic should just show the header "Magic (click to open)."  Clicking on it should open.
  
  - Spells should be segregated by section.

  - Each section should be headed either "Cantrips" or "Level N spells (k slots)", where the N is fixed for each level but the k can be filled in by the user in a small textbox (just one digit, please).

  - Initially no empty sections should be shown.  And at the end of the last section there should be a box "open level N+1 spells," where "N+1" is as appropriate.  When opened, this section will be empty, and should be succeeded by a button to open level N+2 spells, and so on up through level 9.  There is no level 10 or beyond.
  

## Troubleshooting

### PDF Generation "Failed to fetch" Error
If the character form's "Generate PDF" button gives a "Failed to fetch" error, remind the user that this commonly happens when accessing the form via a `file://` URL instead of through a web server. The PDF generation requires HTTP/HTTPS to make fetch requests to the server endpoint. The form must be served through a web server (like Apache) for the PDF generation to work properly.

- every time you update the character form, you need to change its internal version string.
