# -*- mode: python ; coding: utf-8 -*-
# PyInstaller onedir：shuttle.exe + _internal/（动态依赖）
# 分发请复制 win/dist/shuttle/ 整个目录，勿只复制 win/build/ 下的 exe。

import sys
from pathlib import Path

from PyInstaller.compat import is_win

ROOT = Path(SPECPATH).resolve().parent
ENTRY = ROOT / "win" / "app.py"


def _win_python_runtime_binaries() -> list[tuple[str, str]]:
    """补齐 PyInstaller 易漏的 MSVC 运行库（否则换目录/换机后 LoadLibrary 失败）。"""
    if not is_win:
        return []
    base = Path(sys.base_prefix)
    out: list[tuple[str, str]] = []
    seen: set[str] = set()
    for pattern in ("vcruntime140*.dll",):
        for src in sorted(base.glob(pattern)):
            key = src.name.lower()
            if key in seen:
                continue
            seen.add(key)
            out.append((str(src), "."))
    return out


a = Analysis(
    [str(ENTRY)],
    pathex=[str(ROOT)],
    binaries=_win_python_runtime_binaries(),
    datas=[],
    hiddenimports=[
        "common",
        "common.git_client",
        "common.shuttle_env",
        "common.subprocess_util",
        "common.version",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="shuttle",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=False,
    upx_exclude=[],
    name="shuttle",
)
