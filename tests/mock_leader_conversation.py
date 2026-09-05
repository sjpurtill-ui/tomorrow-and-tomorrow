"""Local contract fixture; never calls a model or stores credentials."""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_args):
        pass

    def do_POST(self):
        payload = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        messages = payload["messages"]
        latest = messages[-1]["content"]
        history = json.dumps(messages)
        assert "CURRENT SIMULATION DATA" in messages[1]["content"]
        assert "mass_repression" in messages[1]["content"]
        assert "leader_conversation" == payload["response_format"]["json_schema"]["name"]
        reply = {"reply": "Would you prefer rationing or increasing food gathering?", "decree": "", "policies": []}
        if "thirty days" in latest:
            assert "stretch our stores" in history
            reply = self.draft(30)
        elif "What if" in latest:
            assert "Enact rationing for 30 days." in history
            reply["reply"] = "Sixty days would sustain the reduction longer. Do you want that term in the decree?"
        elif "draft rationing for sixty" in latest:
            assert "What if" in history
            reply = self.draft(60)
        data = json.dumps({"choices": [{"message": {"content": "bad-json" if latest == "MALFORMED" else json.dumps(reply)}}]}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass

    @staticmethod
    def draft(days):
        decree = f"Enact rationing for {days} days."
        return {"reply": "Here are the rationing terms we discussed.", "decree": decree,
                "policies": [{"id": "rationing", "basis": decree, "confidence": 0.99}]}


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 18769), Handler).serve_forever()
