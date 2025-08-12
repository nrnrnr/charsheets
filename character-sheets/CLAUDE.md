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

## Common Troubleshooting

- Ensure all YAML files use double quotes for keys with spaces
- Check that ability scores are numeric
- Verify template files exist in the templates directory (default: current directory)
- LaTeX compilation errors often indicate missing packages or malformed macro calls


# Goals to extend the system

Our current goals are to extend the system to make it more easily usable by others.  The extension will take place one step at a time using the following numbered steps:

 1. An alphabetical guide to all YAML keys (YAML.md).  The entry for each key should say what it means, whether it is meaningfully usable on a character sheet, and whether it is optional or required on a character sheet, and whether it may be empty.  The entry should also give one or two examples of how the key can be used.

    Claude will write the first draft of this documentation using the following sources of information:

    - The collective set of *.yaml files.  As part of analyzing the *.yaml files, Claude will flag any instances where the same information seems to be specified using different keys in different *.yaml files.

    - The set of keys declared using `\newDND` in file charsheet.sty.

    - The way keys are used in the `charsheet` script, with particular attention to function `extend`.

    - The way keys are used in the template file `caster.tex`.  This file in particular is the source for determining what keys are actually used or optional.
    
 2. A quick-start guide to the use of the YAML.  This quick-start guide should cover the keys necessary to create a character sheet like `zanogh.pdf` or `miriel.pdf`, and the order of explanation should parallel the order in which elements appear on those sheets.  The colored backgrounds should be mentioned, and all keys with the same colored background should be dealt with together as a group.  File `caster.tex` may also be of help putting together this guide; it is the source from which both `zanogh.pdf` and `miriel.pdf` are made (together with their corresponding *.yaml files).
 
 3. A web form making it easy for people to create a character sheet without resulting to the YAML.  The structure of that form should resemble the structure of the PDF character sheets, and likely the color scheme as well.  Some CSS will be required. The web form should include buttons to save the contents as a yaml file and to populate the form from a yaml file.

 4. A web service, added to the web form, that will enable anyone to press a button and have the server reply with PDF generated by the `charsheet` script.

## Implementation Guidelines for Extension Goals

### Step 1 Implementation Details
- **Scope**: YAML.md should cover ALL keys found in the system (including internal keys), with user-facing keys **highlighted** or **emphasized**
- **Key variations**: When the same information uses different keys in different files, document all variants but keep standardization recommendations off to the side
- **Template dependency**: Focus on `caster.tex` as it is currently the only template in use
- **Sources priority**: Use caster.tex as primary source for determining what keys are actually used/optional

### Steps 3-4 Implementation Details
- **Technology preferences**: Simple solutions with minimal dependencies preferred
- **Color scheme**: Colors defined in `charsheet.sty` (via `\colorlet`) match the colors in generated PDFs
- **Development environment**: Debian Linux + Apache + full LaTeX toolchain
- **Deployment target**: Red Hat Linux + Apache + full LaTeX toolchain (possibly older Apache version)
- **Web framework**: Minimize dependencies, avoid complex frameworks if possible
- **Server setup**: Can assume full LaTeX toolchain (pdflatex, lua5.1, lyaml) available on server

### Web Service Architecture Recommendations
- Keep the web service simple - direct shell execution of `charsheet` script should work
- Consider basic file upload/download handling for YAML files
- PDF generation can be synchronous (direct response) given the speed of LaTeX compilation
- Error handling should capture both YAML parsing errors and LaTeX compilation errors
 
