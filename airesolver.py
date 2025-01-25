import json
from http.server import BaseHTTPRequestHandler, HTTPServer
#stores data here
DATA_FILE = "resolver_data.json" 

def load_data():
    try:
        with open(DATA_FILE, "r") as file:
            return json.load(file)
    except FileNotFoundError:
        return {}

def save_data(data):
    with open(DATA_FILE, "w") as file:
        json.dump(data, file, indent=4)

def analyze_data(player_data):
    desync_side_count = {"left": 0, "right": 0}

    for side in player_data.get("desync_history", []):
        if side == 1:
            desync_side_count["right"] += 1
        else:
            desync_side_count["left"] += 1

    if desync_side_count["left"] > desync_side_count["right"]:
        return -1  #Left
    else:
        return 1  #Right

class ResolverHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        print("Received POST request")
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length).decode("utf-8")
        print("Request data:", post_data)

        try:
            data = json.loads(post_data)
        except json.JSONDecodeError:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Invalid JSON data")
            return

        steam_id = data.get("steam_id")
        if not steam_id:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b"Invalid request: Missing steam_id")
            return

        resolver_data = load_data()
        if steam_id not in resolver_data:
            resolver_data[steam_id] = {
                "desync_history": [],
                "missed_shots": 0,
                "learned_side": None,
            }

        resolver_data[steam_id]["desync_history"].extend(data.get("desync_history", []))
        resolver_data[steam_id]["desync_history"] = resolver_data[steam_id]["desync_history"][-12:]
        resolver_data[steam_id]["missed_shots"] = data.get("missed_shots", 0)
        resolver_data[steam_id]["learned_side"] = analyze_data(resolver_data[steam_id])

        save_data(resolver_data)
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        
        response = json.dumps({
            "learned_side": resolver_data[steam_id]["learned_side"]
        }).encode("utf-8")
        
        print("Sending response:", response.decode("utf-8"))  
        self.wfile.write(response)

def run_server(host="127.0.0.1", port=8080):
    server_address = (host, port)
    httpd = HTTPServer(server_address, ResolverHandler)
    print(f"Starting HTTP server on {host}:{port}...")
    httpd.serve_forever()

if __name__ == "__main__":
    run_server()