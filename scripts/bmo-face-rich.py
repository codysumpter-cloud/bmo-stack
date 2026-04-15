#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys

FACES = {
    "idle": """╔══════════════════╗
║  ▄██████████▄    ║
║  █  BMO ^_^ █    ║
║  █   ready   █   ║
║  ▀██████████▀    ║
╚══════════════════╝""",
    "listening": """╔══════════════════╗
║  ▄██████████▄    ║
║  █  BMO o_o █    ║
║  █ listening █   ║
║  ▀██████████▀    ║
╚══════════════════╝""",
    "thinking": """╔══════════════════╗
║  ▄██████████▄    ║
║  █  BMO -_- █    ║
║  █ thinking █    ║
║  ▀██████████▀    ║
╚══════════════════╝""",
    "speaking": """╔══════════════════╗
║  ▄██████████▄    ║
║  █  BMO ^o^ █    ║
║  █ speaking █    ║
║  ▀██████████▀    ║
╚══════════════════╝""",
    "error": """╔══════════════════╗
║  ▄██████████▄    ║
║  █  BMO x_x █    ║
║  █  error   █    ║
║  ▀██████████▀    ║
╚══════════════════╝""",
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Render a richer BMO face state in the terminal.")
    parser.add_argument("state", choices=sorted(FACES))
    args = parser.parse_args()
    sys.stdout.write(FACES[args.state] + "\n")


if __name__ == "__main__":
    main()
