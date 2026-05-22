"""跨平台 subprocess 封装（Windows GUI 下抑制 git 子进程控制台闪窗）。"""

from __future__ import annotations

import subprocess
import sys
from typing import Any


def run_subprocess(*args: Any, **kwargs: Any) -> subprocess.CompletedProcess[Any]:
    if sys.platform == "win32":
        flags = int(kwargs.get("creationflags", 0))
        kwargs["creationflags"] = flags | subprocess.CREATE_NO_WINDOW
    return subprocess.run(*args, **kwargs)
