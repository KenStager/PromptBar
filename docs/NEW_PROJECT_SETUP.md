# New Project & Repository Setup

Use the `tools/create_new_project.py` helper to scaffold a fresh project and optional git repository based on the PromptBar conventions.

## Requirements
- Python 3.9+
- `git` available on your `PATH` (unless you opt out with `--no-git`)

## Usage
```bash
# Create a project in the current directory and initialize a git repo
tools/create_new_project.py MyNewPromptBar

# Create a project in a custom directory without initializing git
tools/create_new_project.py MyPrototype ~/Developer --no-git
```

The script generates the following structure:
```
MyNewPromptBar/
├── .git/              # optional, created unless --no-git is passed
├── .gitignore         # starter ignore rules for macOS & Swift projects
├── LICENSE            # placeholder text – replace with your license
├── README.md          # quick-start instructions to customize
├── docs/
│   └── OVERVIEW.md    # documentation starting point
├── src/
│   └── main.swift     # placeholder entry point
└── tests/
    └── README.md      # guidance for adding tests
```

After scaffolding, update the README, add your source files, and configure any CI/CD workflows needed for the new repository.
