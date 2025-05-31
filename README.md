# Roadmap

The goal is to eventually have as much of the functionality of Visual Studio
and Rider as possible, but with a Neovim emphasis on keyboard navigation and
shortcuts.

## Missing Features

### Tree View

Tree view components:

- [ ] file tree
- [ ] file icons
- [ ] code behind grouping
  - [ ] razor, razor.cs, razor.css, razor.js etc.
  - [ ] appsettings.json, appsettings.Development.json, etc.
- [ ] expand/collapse folders
- [ ] controls to open/close files
- [ ] Special c# icons
  - [ ] Properties
  - [ ] wwwroot
- [ ] github integration (file/icon highlighting)
- [ ] dependencies section
  - [ ] ⚙ imports
  - [ ] ⛭ .NET dependencies

### File Management

- [ ] file management
  - [ ] create file
    - [ ] class
    - [ ] interface
    - [ ] razor component
  - [ ] delete file
  - [ ] rename file
    - [ ] investigate smart rename with LSP
    - [ ] ability to rename file and class
  - [ ] move file
    - [ ] ability to automatically update namespaces with LSP
  - [ ] copy file
  - [ ] upload file
- [ ] helpers
  - [ ] intelligent default namespace on cs files
  - [ ] templates for file creation (class, interface, razor component, etc.)
- [ ] file search

### Solution/Project Management

- [ ] projects
  - [ ] create project
  - [ ] delete project
  - [ ] rename project
  - [ ] move project
  - [ ] copy project
- [ ] templates and scaffolding
  - [ ] picker ui for selection project templates
  - [ ] configuration wizards for creating projects from templates
  - [ ] create solution from template
  - [ ] create project from template
  - [ ] create file from template
