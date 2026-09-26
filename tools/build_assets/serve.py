#!/usr/bin/env python3
"""Serve dist-assets/ like the production CDN, for development.

    python3 tools/build_assets/serve.py [--port 8090] [--dir dist-assets] [--origin '*']

Headers it sends (the CDN must send the same):
  * Access-Control-Allow-Origin: <origin>   (the Mini App's origin in production)
  * Cache-Control: public, max-age=31536000, immutable   for hashed files
  * Cache-Control: no-cache                              for manifest.json
  * Content-Encoding: br / gzip from the precompressed .br / .gz siblings,
    when the client accepts it (Vary: Accept-Encoding)
"""
import argparse
import http.server
import os

TYPES = {".glb": "model/gltf-binary", ".webp": "image/webp", ".png": "image/png", ".svg": "image/svg+xml",
         ".json": "application/json", ".ttf": "font/ttf", ".otf": "font/otf", ".ogg": "audio/ogg"}


def handler(root, origin):
    class H(http.server.BaseHTTPRequestHandler):
        def _headers(self, path, size, enc):
            self.send_header("Content-Type", TYPES.get(os.path.splitext(path)[1], "application/octet-stream"))
            self.send_header("Content-Length", str(size))
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
            self.send_header("Vary", "Accept-Encoding")
            if enc:
                self.send_header("Content-Encoding", enc)
            if os.path.basename(path) == "manifest.json":
                self.send_header("Cache-Control", "no-cache")
            else:
                self.send_header("Cache-Control", "public, max-age=31536000, immutable")

        def do_OPTIONS(self):
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
            self.send_header("Access-Control-Max-Age", "86400")
            self.end_headers()

        def do_HEAD(self):
            self.do_GET(body=False)

        def do_GET(self, body=True):
            rel = self.path.split("?")[0].lstrip("/")
            path = os.path.normpath(os.path.join(root, rel))
            if not path.startswith(os.path.abspath(root)) or not os.path.isfile(path):
                self.send_error(404)
                return
            accept = self.headers.get("Accept-Encoding", "")
            send, enc = path, ""
            if "br" in accept and os.path.isfile(path + ".br"):
                send, enc = path + ".br", "br"
            elif "gzip" in accept and os.path.isfile(path + ".gz"):
                send, enc = path + ".gz", "gzip"
            data = open(send, "rb").read()
            self.send_response(200)
            self._headers(path, len(data), enc)
            self.end_headers()
            if body:
                self.wfile.write(data)

        def log_message(self, *a):
            pass
    return H


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8090)
    ap.add_argument("--dir", default=os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "dist-assets"))
    ap.add_argument("--origin", default="*")
    a = ap.parse_args()
    root = os.path.abspath(a.dir)
    print("serving %s on http://127.0.0.1:%d/" % (root, a.port))
    http.server.ThreadingHTTPServer(("127.0.0.1", a.port), handler(root, a.origin)).serve_forever()


if __name__ == "__main__":
    main()
