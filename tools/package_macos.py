"""Normalize and sign the generated macOS bundle, then create a distributable ZIP.

Godot 4.7.2 leaves an unescaped ampersand in CFBundleExecutable when the
project name contains '&'. Fix the generated metadata without renaming the
game or changing its save directory. No Apple credentials are required for
an ad-hoc signature; notarization requires a separate Apple Developer ID.
"""
import argparse
import html
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import zipfile
from xml.sax.saxutils import escape


def package(source: Path, output: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="corpse-effect-macos-") as directory:
        scratch = Path(directory)
        with zipfile.ZipFile(source) as archive:
            for item in archive.infolist():
                target = (scratch / item.filename).resolve()
                if not target.is_relative_to(scratch.resolve()):
                    raise ValueError("Unsafe path in exported bundle")
                archive.extract(item, scratch)
                mode = item.external_attr >> 16
                if mode:
                    os.chmod(target, mode & 0o777)
        apps = list(scratch.glob("*.app"))
        if len(apps) != 1:
            raise ValueError("Expected exactly one exported app")
        app = apps[0]
        info = app / "Contents/Info.plist"
        text = info.read_text()
        text = re.sub(
            r"(<key>CFBundleExecutable</key>\s*<string>)(.*?)(</string>)",
            lambda match: match[1] + escape(html.unescape(match[2])) + match[3],
            text,
        )
        metadata = plistlib.loads(text.encode())
        metadata["LSApplicationCategoryType"] = "public.app-category.games"
        with info.open("wb") as stream:
            plistlib.dump(metadata, stream, sort_keys=False)
        binary = app / "Contents/MacOS" / metadata["CFBundleExecutable"]
        binary.chmod(0o755)
        subprocess.run(["/usr/bin/plutil", "-lint", str(info)], check=True)
        subprocess.run(["/usr/bin/codesign", "--force", "--deep", "--sign", "-", "--options", "runtime", str(app)], check=True)
        subprocess.run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)], check=True)
        subprocess.run(["/usr/bin/lipo", "-info", str(binary)], check=True)
        temporary_zip = scratch / "signed.zip"
        subprocess.run(["/usr/bin/ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", str(app), str(temporary_zip)], check=True)
        output.parent.mkdir(parents=True, exist_ok=True)
        # The generated distribution replaces only the requested output artifact.
        with temporary_zip.open("rb") as src, output.open("wb") as dst:
            import shutil
            shutil.copyfileobj(src, dst)
        print(f"Verified universal macOS build: {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    package(args.source, args.output)
