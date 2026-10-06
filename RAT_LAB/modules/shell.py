# shell.py — Remote shell execution module
# Runs arbitrary commands via cmd.exe/powershell with working directory tracking

import subprocess
import os


class RemoteShell:
    """Maintains a stateful working directory across shell commands."""

    def __init__(self):
        self.cwd = os.path.expanduser("~")

    def execute(self, command: str) -> dict:
        """Execute a shell command and return stdout/stderr/returncode.

        Handles 'cd' as a special case to update the persistent cwd.

        Args:
            command: Shell command string to execute.

        Returns:
            Dict with stdout, stderr, returncode, and current cwd.
        """
        command = command.strip()
        if not command:
            return {
                "stdout": "", "stderr": "Empty command",
                "returncode": -1, "cwd": self.cwd,
            }

        # Handle cd specially — subprocess cd doesn't persist
        if command.lower().startswith("cd "):
            return self._change_dir(command[3:].strip())
        if command.lower() == "cd":
            return {
                "stdout": self.cwd, "stderr": "",
                "returncode": 0, "cwd": self.cwd,
            }

        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=self.cwd,
            )
            return {
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode,
                "cwd": self.cwd,
            }
        except subprocess.TimeoutExpired:
            return {
                "stdout": "", "stderr": "Command timed out (60s)",
                "returncode": -1, "cwd": self.cwd,
            }
        except Exception as e:
            return {
                "stdout": "", "stderr": str(e),
                "returncode": -1, "cwd": self.cwd,
            }

    def _change_dir(self, path: str) -> dict:
        """Update the persistent working directory."""
        try:
            target = os.path.abspath(os.path.join(self.cwd, path))
            if os.path.isdir(target):
                self.cwd = target
                return {
                    "stdout": self.cwd, "stderr": "",
                    "returncode": 0, "cwd": self.cwd,
                }
            return {
                "stdout": "", "stderr": f"Not a directory: {target}",
                "returncode": 1, "cwd": self.cwd,
            }
        except Exception as e:
            return {
                "stdout": "", "stderr": str(e),
                "returncode": -1, "cwd": self.cwd,
            }
