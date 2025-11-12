#!/usr/bin/env python3
"""Utility to scaffold a fresh PromptBar-inspired project repository."""
from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path
from textwrap import dedent


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a new project directory with starter files and optional git repo.",
    )
    parser.add_argument(
        "name",
        help="Name of the new project. Used for the folder name and README title.",
    )
    parser.add_argument(
        "destination",
        nargs="?",
        default=".",
        help="Directory where the project folder will be created (defaults to current working directory).",
    )
    parser.add_argument(
        "--no-git",
        action="store_true",
        help="Skip initializing a git repository in the new project folder.",
    )
    return parser.parse_args()


def ensure_directory(path: Path) -> None:
    if path.exists() and any(path.iterdir()):
        raise FileExistsError(f"Destination '{path}' already exists and is not empty.")
    path.mkdir(parents=True, exist_ok=True)


def write_file(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def create_readme(project_name: str) -> str:
    return dedent(
        f"""\
        # {project_name}

        This repository was bootstrapped with the PromptBar project scaffolding tool.

        ## Getting Started

        1. Update this README with details about your new project.
        2. Add your source code inside the `src/` directory.
        3. Document architecture decisions inside `docs/`.
        4. Add automated tests to the `tests/` directory.

        ## Next Steps

        - Configure continuous integration.
        - Update licensing information.
        - Replace placeholder files with real implementations.
        """
    )


def create_gitignore() -> str:
    return dedent(
        """\
        # macOS
        .DS_Store

        # Xcode
        build/
        DerivedData/
        *.xcworkspace/
        *.xcuserdata/

        # Swift Package Manager
        .build/

        # Python virtual environments
        .venv/
        env/
        venv/

        # Logs
        *.log
        """
    )


def create_license_placeholder() -> str:
    return dedent(
        """\
        Copyright (c) {year}

        Add your preferred license here.
        """
    ).format(year=os.environ.get("YEAR", "2025"))


def initialize_git(project_path: Path) -> None:
    try:
        subprocess.run(["git", "init"], cwd=project_path, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except (OSError, subprocess.CalledProcessError) as exc:
        raise RuntimeError(
            "Failed to initialize git repository. Run with --no-git or initialize manually."
        ) from exc


def main() -> None:
    args = parse_args()

    destination_root = Path(args.destination).expanduser().resolve()
    project_path = destination_root / args.name

    ensure_directory(project_path)

    # Create base directories
    (project_path / "src").mkdir(parents=True, exist_ok=True)
    (project_path / "docs").mkdir(parents=True, exist_ok=True)
    (project_path / "tests").mkdir(parents=True, exist_ok=True)

    # Add placeholder files
    write_file(project_path / "README.md", create_readme(args.name))
    write_file(project_path / ".gitignore", create_gitignore())
    write_file(project_path / "LICENSE", create_license_placeholder())
    write_file(project_path / "docs" / "OVERVIEW.md", "# Project Documentation\n\nStart documenting here.\n")
    write_file(project_path / "src" / "main.swift", "// TODO: Add application entry point.\n")
    write_file(project_path / "tests" / "README.md", "# Tests\n\nAdd your test suites in this directory.\n")

    if not args.no_git:
        initialize_git(project_path)

    print(f"Created new project at {project_path}")
    if not args.no_git:
        print("Initialized empty git repository.")
    else:
        print("Skipped git initialization.")


if __name__ == "__main__":
    main()
