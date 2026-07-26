#!/usr/bin/env python3
"""tr.json / en.json geçerli JSON parse kontrolü (CI/local smoke)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ROOT / "assets" / "translations" / "tr.json",
    ROOT / "assets" / "translations" / "en.json",
]


def main() -> int:
    ok = True
    for path in FILES:
        try:
            with path.open(encoding="utf-8") as f:
                data = json.load(f)
            if not isinstance(data, dict) or not data:
                print(f"FAIL {path.name}: boş veya Map değil")
                ok = False
            else:
                print(f"OK   {path.name}: parse edildi ({len(data)} kök anahtar)")
        except FileNotFoundError:
            print(f"FAIL {path}: dosya yok")
            ok = False
        except json.JSONDecodeError as e:
            print(f"FAIL {path.name}: JSON hata — {e}")
            ok = False
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
