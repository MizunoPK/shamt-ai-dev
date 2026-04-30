"""Drive the Shamt import pipeline via MCP."""

import subprocess
from pathlib import Path


def _project_root() -> Path:
    return Path(__file__).resolve().parents[4]


def import_pipeline(dry_run: bool = False) -> dict:
    """
    Drive the Shamt import pipeline.

    Invokes `import.sh` to pull master changes into the child project.
    In dry_run mode, surfaces what would change without applying it.

    Parameters:
        dry_run: If True, fetch and diff only — do not apply changes.

    Returns:
        {
            "ok": bool,
            "dry_run": bool,
            "changed_files": list[str],
            "error": str | None,
        }
    """
    root = _project_root()
    import_sh = root / ".shamt" / "scripts" / "import" / "import.sh"

    if not import_sh.exists():
        return {
            "ok": False,
            "dry_run": dry_run,
            "changed_files": [],
            "error": f"import.sh not found: {import_sh}",
        }

    cmd = ["bash", str(import_sh)]
    if dry_run:
        cmd.append("--dry-run")

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=str(root),
    )

    changed_files: list[str] = []
    for line in (result.stdout or "").splitlines():
        if line.startswith(("A\t", "M\t", "D\t")):
            changed_files.append(line[2:].strip())

    if result.returncode != 0:
        return {
            "ok": False,
            "dry_run": dry_run,
            "changed_files": changed_files,
            "error": result.stderr or result.stdout,
        }

    return {"ok": True, "dry_run": dry_run, "changed_files": changed_files, "error": None}
