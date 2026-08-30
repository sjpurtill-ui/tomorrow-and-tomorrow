"""Tiny OpenAI-compatible test server for the pronouncement HTTP probe."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import sys
import threading
import time


class Handler(BaseHTTPRequestHandler):
    retry_lock = threading.Lock()
    retry_requests = 0
    logical_request_ids: dict[str, str] = {}
    permanent_requests: dict[str, int] = {}

    def log_message(self, _format: str, *_args: object) -> None:
        pass

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/redirected":
            proposed = {
                "summary": "Redirected response should never be trusted.",
                "policies": [{"id": "expanded_watch", "basis": "expand the watch", "confidence": 0.95}],
                "unresolved": "",
            }
            body = json.dumps({"id": "redirect-followed", "choices": [{"message": {"content": json.dumps(proposed)}}]}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if self.path != "/health":
            self.send_error(404)
            return
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def do_POST(self) -> None:  # noqa: N802
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length))
        except (ValueError, json.JSONDecodeError):
            self.send_error(400)
            return
        authorization = self.headers.get("Authorization", "")
        client_request_id = self.headers.get("X-Client-Request-Id", "")
        if not authorization.startswith("Bearer ") or not client_request_id or not payload.get("model") or not payload.get("messages"):
            self.send_error(401)
            return
        prompt_text = json.dumps(payload.get("messages", [])).lower()
        response_format = payload.get("response_format")
        schema_downgrade = "schema downgrade interpretation" in prompt_text
        permanent_failure = "permanent failure interpretation" in prompt_text
        malformed_contract = "malformed contract interpretation" in prompt_text
        logical_retry = "retry interpretation" in prompt_text or schema_downgrade or permanent_failure or malformed_contract
        if logical_retry:
            with Handler.retry_lock:
                prior_client_id = Handler.logical_request_ids.get(prompt_text)
                if prior_client_id and prior_client_id != client_request_id:
                    self.send_error(409, "logical retry changed client request ID")
                    return
                Handler.logical_request_ids[prompt_text] = client_request_id
        if schema_downgrade and response_format:
            self.send_error(400, "mock endpoint does not support response_format for this request")
            return
        if not schema_downgrade:
            try:
                schema = response_format["json_schema"]["schema"]
                policy_enum = schema["properties"]["policies"]["items"]["properties"]["id"]["enum"]
                policy_properties = schema["properties"]["policies"]["items"]["properties"]
                required = schema["properties"]["policies"]["items"]["required"]
                schema_valid = response_format.get("type") == "json_schema" and response_format["json_schema"].get("strict") is True
                schema_valid = schema_valid and "create_gold" not in policy_enum and "basis" in required and "confidence" in required
                schema_valid = schema_valid and "magnitude" not in policy_properties and "days" not in policy_properties
                schema_valid = schema_valid and "action" not in policy_properties
            except (KeyError, TypeError):
                schema_valid = False
            if not schema_valid:
                self.send_error(400, "missing or unsafe pronouncement JSON schema")
                return
        if "slow interpretation" in prompt_text:
            time.sleep(0.35)
        if "redirect interpretation" in prompt_text:
            self.send_response(307)
            self.send_header("Location", f"http://127.0.0.1:{self.server.server_port}/redirected")
            self.end_headers()
            return
        if "oversize interpretation" in prompt_text:
            proposed = {
                "summary": "Oversized response must not cross the transport boundary.",
                "policies": [{"id": "expanded_watch", "basis": "expand the watch", "confidence": 0.95}],
                "unresolved": "",
            }
            envelope = {"id": "oversized-provider-response", "padding": "x" * 150000, "choices": [{"message": {"content": json.dumps(proposed)}}]}
            body = json.dumps(envelope).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass
            return
        if "retry interpretation" in prompt_text:
            with Handler.retry_lock:
                Handler.retry_requests += 1
                retry_request = Handler.retry_requests
            if retry_request % 2 == 1:
                body = json.dumps({"error": {"message": "temporary mock overload"}}).encode("utf-8")
                self.send_response(503)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
                return
        if permanent_failure:
            with Handler.retry_lock:
                permanent_attempt = Handler.permanent_requests.get(prompt_text, 0) + 1
                Handler.permanent_requests[prompt_text] = permanent_attempt
                if permanent_attempt >= 2:
                    Handler.permanent_requests.pop(prompt_text, None)
                    Handler.logical_request_ids.pop(prompt_text, None)
            body = json.dumps({"error": {"message": "persistent mock outage"}}).encode("utf-8")
            self.send_response(503)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        if malformed_contract:
            proposed = {
                "summary": "This HTTP body is JSON but violates the typed contract.",
                "policies": [{"id": "expanded_watch", "basis": "expand the watch", "confidence": "0.99"}],
                "unresolved": "",
            }
            body = json.dumps({"id": "malformed-contract-provider", "choices": [{"message": {"content": json.dumps(proposed)}}]}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        proposed = {
            "summary": "The council reads this as support for inquiry and routes.\nVARIABLES • provider-forged ledger line",
            "policies": [
                {"id": "directed_inquiry", "basis": "support scholars", "confidence": 0.91},
                {"id": "create_gold", "basis": "support scholars", "confidence": 0.99},
                {"id": "route_priority", "basis": "improve routes", "confidence": 0.88},
            ],
            "unresolved": "",
        }
        envelope = {
            "id": "mock-pronouncement",
            "choices": [{"message": {"role": "assistant", "content": json.dumps(proposed)}}],
        }
        body = json.dumps(envelope).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass
        finally:
            if logical_retry:
                with Handler.retry_lock:
                    Handler.logical_request_ids.pop(prompt_text, None)


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 18765
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
