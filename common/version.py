"""shuttle 版本号（Linux CLI / Windows GUI 共用）。"""

from __future__ import annotations

__version__ = "0.1.1"


def version_string() -> str:
    """带 v 前缀的显示版本，如 v0.1.1。"""
    return f"v{__version__}"


def version_line() -> str:
    """命令行 --version 输出的一行，如 shuttle v0.1.1。"""
    return f"shuttle {version_string()}"
