#!/usr/bin/env python3
"""Compile role documents from mined rules + an example taken from the repo.

Usage: compile_role.py <repo> --example TopflytechProtocolDecoder \
          --rules-out role_rules.md --example-out role_example.md
No hand-written rules: the rules section is exactly extract_rules.py output.
"""
import re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_rules import rules  # noqa: E402

LICENSE_RE = re.compile(r"\A\s*/\*.*?\*/\s*", re.DOTALL)

def find(repo: Path, cls: str) -> Path:
    hits = list(repo.glob(f"src/**/{cls}.java"))
    if len(hits) != 1:
        sys.exit(f"expected exactly one {cls}.java in {repo}, found {hits}")
    return hits[0]

def strip_license(src: str) -> str:
    return LICENSE_RE.sub("", src, count=1)

def main():
    a = sys.argv
    repo = Path(a[1]).resolve()
    example = a[a.index("--example") + 1]
    rules_out = Path(a[a.index("--rules-out") + 1])
    example_out = Path(a[a.index("--example-out") + 1])
    head = ("# Role: Traccar protocol developer\n\n"
            "Follow these project conventions. Each rule was mined from the repository; "
            "the fraction shows how many files obey it.\n\n")
    rules_out.write_text(head + "\n".join(rules(repo)) + "\n")
    dec = strip_license(find(repo, example).read_text())
    tst = strip_license(find(repo, example + "Test").read_text())
    example_out.write_text("# Example decoder from the repository\n\n```java\n" + dec.rstrip("\n") +
                           "\n\n```\n\n# Example test\n\n```java\n" + tst.rstrip("\n") + "\n\n```\n")
    print(f"wrote {rules_out} ({rules_out.read_text().count(chr(10))} lines) and {example_out}")

if __name__ == "__main__":
    main()
