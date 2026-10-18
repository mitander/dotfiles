"""Check the installed editable environment without starting tracker applications."""

import importlib.metadata
import importlib.util
import json
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse


def main() -> None:
    checkout = Path(sys.argv[1]).resolve()
    for package, module, directory in (
        ("ltui-linear", "ltui", "ltui"),
        ("jtui", "jtui", "jtui"),
        ("flume-tracker-theme", "flume_tracker_theme", "flume-theme"),
    ):
        distribution = importlib.metadata.distribution(package)
        record = json.loads(distribution.read_text("direct_url.json") or "{}")
        assert record.get("dir_info", {}).get("editable"), f"{package} is not editable"
        source = Path(unquote(urlparse(record["url"]).path)).resolve()
        expected = checkout / directory
        assert source == expected, f"{package} uses {source}, expected {expected}"

        spec = importlib.util.find_spec(module)
        assert spec and spec.origin, f"{module} is not importable"
        assert Path(spec.origin).resolve() == expected / f"{module}.py", spec.origin
        print(f"PASS: {module} runs directly from {expected}")


if __name__ == "__main__":
    main()
