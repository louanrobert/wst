import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import struct
import subprocess
import tempfile
import termios
import time


repo = Path(__file__).resolve().parents[2]
root = Path(tempfile.mkdtemp(prefix="wst-cd-menu-"))
home = root / "home"
home.mkdir()
work = root / "directories"
work.mkdir()
names = ("alpha-choice", "beta-choice", "gamma-choice")
for name in names:
    (work / name).mkdir()
(work / "not-a-directory.txt").write_text("test")
for name in (".zshrc", ".zshenv", ".aliases"):
    shutil.copyfile(repo / "dotfiles" / name, home / name)
env = dict(
    os.environ, HOME=str(home), ZDOTDIR=str(home), TMUX="test",
    ZSH_CONFIG=str(home / ".zsh-config"), TERM="xterm-256color",
    XDG_CACHE_HOME=str(home / ".cache"),
    XDG_CONFIG_HOME=str(home / ".config"),
    XDG_DATA_HOME=str(home / ".local/share"),
    XDG_STATE_HOME=str(home / ".local/state"),
)
pid = None
fd = None


def read_for(seconds):
    deadline = time.monotonic() + seconds
    output = bytearray()
    while time.monotonic() < deadline:
        if select.select([fd], [], [], 0.1)[0]:
            try:
                data = os.read(fd, 65536)
            except OSError as exc:
                if exc.errno == errno.EIO:
                    break
                raise
            if not data:
                break
            output.extend(data)
    return output.decode(errors="replace")


try:
    subprocess.run(
        ["zsh", "-dfi", "-c",
         'source "$HOME/.zshenv" && source "$HOME/.zshrc"'],
        cwd=work, env=env, check=True, stdout=subprocess.DEVNULL, timeout=180,
    )
    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(work)
        os.execvpe("zsh", ["zsh", "-d"], env)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))
    initial = read_for(5)
    assert "╭─" in initial and "╰─" in initial, initial

    os.write(fd, b"cd ")
    listing = read_for(2)
    assert all(name in listing for name in names), listing
    assert "not-a-directory.txt" not in listing, listing

    os.write(fd, b"\x1b[B")
    first = read_for(0.5)
    os.write(fd, b"\x1b[B")
    down = read_for(0.5)
    assert first != down, (first, down)
    os.write(fd, b"\x1b[C\x1b[D\x1b[A")
    read_for(0.5)
    os.write(fd, b"\r")
    read_for(0.5)
    os.write(fd, b"\r")
    read_for(1)
    os.write(fd, b"print -r -- WST_FINAL_DIRECTORY:$PWD\n")
    result = read_for(1)
    assert any(f"WST_FINAL_DIRECTORY:{work}/{name}" in result for name in names), result

    os.write(fd, b"cd ../bet")
    filtered = read_for(2)
    assert "beta-choice" in filtered, filtered
    assert "alpha-choice" not in filtered and "gamma-choice" not in filtered, filtered
    os.write(fd, b"\x03")
    read_for(0.5)
    os.write(fd, b"exit 0\n")
    read_for(1)
    deadline = time.monotonic() + 5
    while True:
        finished, status = os.waitpid(pid, os.WNOHANG)
        if finished:
            break
        assert time.monotonic() < deadline, "Shell did not exit after the menu test."
        time.sleep(0.1)
    pid = None
    assert os.waitstatus_to_exitcode(status) == 0
    print("OK: automatic cd directory lists, arrow selection, Enter, and prefix filtering.")
finally:
    if pid:
        os.kill(pid, signal.SIGKILL)
        os.waitpid(pid, 0)
    if fd is not None:
        os.close(fd)
    shutil.rmtree(root)
