"""Serve only the exported Web game and expose it through a public Quick Tunnel."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import shutil
import subprocess
import threading


class GameHandler(SimpleHTTPRequestHandler):
    extensions_map = {**SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".pck": "application/octet-stream"}

    def list_directory(self, path):
        self.send_error(404)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path("docs"))
    parser.add_argument("--cloudflared", default="cloudflared")
    parser.add_argument("--port", type=int, default=8894)
    args = parser.parse_args()
    directory = args.directory.resolve()
    if not (directory / "index.html").is_file() or not (directory / "index.wasm").is_file():
        parser.error("Choose the exported Web folder containing index.html and index.wasm")
    binary = shutil.which(args.cloudflared)
    if binary is None:
        parser.error("Install the official cloudflared binary or pass --cloudflared /path/to/cloudflared")
    server = ThreadingHTTPServer(("127.0.0.1", args.port), partial(GameHandler, directory=str(directory)))
    worker = threading.Thread(target=server.serve_forever, daemon=True)
    worker.start()
    print("Sharing only the exported game through Cloudflare. Use the public HTTPS URL printed below.", flush=True)
    tunnel = subprocess.Popen([binary, "tunnel", "--no-autoupdate", "--protocol", "http2", "--url", f"http://127.0.0.1:{args.port}"])
    try:
        raise SystemExit(tunnel.wait())
    except KeyboardInterrupt:
        tunnel.terminate()
        tunnel.wait(timeout=15)
    finally:
        server.shutdown()
        server.server_close()


if __name__ == "__main__":
    main()
