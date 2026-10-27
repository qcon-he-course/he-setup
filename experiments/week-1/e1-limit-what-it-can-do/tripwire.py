"""Tripwire for experiment 1.

A small web server that prints every request it receives, with its body,
and answers "ok". Seeded PetClinic sends to tripwire.course.invalid:9000;
compose.yaml gives this server that name on the demo network only.
"""
import datetime
import http.server
import os


def _local_zone():
    """The presenter's UTC offset, passed in by tripwire.sh as +HHMM or -HHMM."""
    raw = os.environ.get("TRIPWIRE_UTC_OFFSET", "+0000")
    sign = -1 if raw.startswith("-") else 1
    hours, minutes = int(raw[1:3]), int(raw[3:5])
    return datetime.timezone(sign * datetime.timedelta(hours=hours, minutes=minutes))


ZONE = _local_zone()


class Handler(http.server.BaseHTTPRequestHandler):
    def _record(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length).decode("utf-8", "replace") if length else ""
        stamp = datetime.datetime.now(ZONE).strftime("%H:%M:%S")
        print(f"{stamp}  {self.command} {self.path}", flush=True)
        for line in body.splitlines():
            print(f"          {line}", flush=True)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(b"ok\n")

    do_GET = do_POST = do_PUT = _record

    def log_message(self, *args):
        pass


print("tripwire: listening on port 9000 as tripwire.course.invalid", flush=True)
http.server.ThreadingHTTPServer(("0.0.0.0", 9000), Handler).serve_forever()
