import base64, json, os, socket, struct, sys, urllib.request

expr = sys.argv[1]
targets = json.load(urllib.request.urlopen("http://127.0.0.1:9222/json/list"))
ws = [t for t in targets if t["type"] == "page"][0]["webSocketDebuggerUrl"]
path = ws.split("127.0.0.1:9222", 1)[1]

s = socket.create_connection(("127.0.0.1", 9222))
key = base64.b64encode(os.urandom(16)).decode()
s.sendall(("GET %s HTTP/1.1\r\nHost: 127.0.0.1:9222\r\nUpgrade: websocket\r\n"
           "Connection: Upgrade\r\nSec-WebSocket-Key: %s\r\n"
           "Sec-WebSocket-Version: 13\r\n\r\n" % (path, key)).encode())
buf = b""
while b"\r\n\r\n" not in buf:
    buf += s.recv(4096)

def send(payload):
    data = json.dumps(payload).encode()
    hdr = b"\x81"
    n = len(data)
    if n < 126:
        hdr += bytes([0x80 | n])
    elif n < 65536:
        hdr += bytes([0x80 | 126]) + struct.pack(">H", n)
    else:
        hdr += bytes([0x80 | 127]) + struct.pack(">Q", n)
    mask = os.urandom(4)
    s.sendall(hdr + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(data)))

def recvall(n):
    out = b""
    while len(out) < n:
        out += s.recv(n - len(out))
    return out

def recv():
    b1, b2 = recvall(2)
    n = b2 & 127
    if n == 126:
        n = struct.unpack(">H", recvall(2))[0]
    elif n == 127:
        n = struct.unpack(">Q", recvall(8))[0]
    return json.loads(recvall(n))

send({"id": 1, "method": "Runtime.evaluate",
      "params": {"expression": expr, "returnByValue": True, "awaitPromise": True}})
while True:
    msg = recv()
    if msg.get("id") == 1:
        print(json.dumps(msg.get("result", {}), indent=1, ensure_ascii=False)[:4000])
        break
