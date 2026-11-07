#!/usr/bin/env python
"""idalib-mcp 可用性探针：stdio 起 server，跑 initialize / tools/list / resources/list。

用法（在 mcp/idalib-mcp 的 venv 里）：
    .venv\\Scripts\\python.exe ..\\probe_idalib_mcp.py

退出码：0 = 协议层可用；2 = server 未启动；3 = 协议异常
"""
import json
import os
import queue
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.join(HERE, "idalib-mcp")
PY = os.path.join(PROJECT, ".venv", "Scripts", "python.exe")
TIMEOUT = 30.0


def read_lines(stream, q, name):
    for raw in iter(stream.readline, b""):
        line = raw.decode("utf-8", "replace").strip()
        if line:
            q.put(("stdout", line))
    q.put(("eof", name))


def main():
    if not os.path.exists(PY):
        print(f"[x] venv python 不存在: {PY}")
        return 2

    args = [PY, "-m", "idalib_mcp", "--stdio", "--max-workers", "2", "--sync-wait", "5", "--verbose"]
    print("== 启动 ==")
    print("  " + " ".join(args))
    proc = subprocess.Popen(
        args,
        cwd=PROJECT,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        bufsize=0,
    )
    q = queue.Queue()
    threading.Thread(target=read_lines, args=(proc.stdout, q, "stdout"), daemon=True).start()
    threading.Thread(target=read_lines, args=(proc.stderr, q, "stderr"), daemon=True).start()

    def send(payload):
        data = json.dumps(payload, separators=(",", ":")) + "\n"
        proc.stdin.write(data.encode("utf-8"))
        proc.stdin.flush()
        print(f"  -> {data.strip()[:110]}")

    def wait_for_id(mid, timeout=TIMEOUT):
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                kind, line = q.get(timeout=1.0)
            except queue.Empty:
                continue
            if kind == "stderr":
                print(f"  [stderr] {line[:150]}")
                continue
            if kind == "eof":
                print("  [x] stdout 关闭")
                return None
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                print(f"  [stdout] {line[:150]}")
                continue
            if msg.get("id") == mid:
                return msg
        print(f"  [x] 等待 id={mid} 超时")
        return None

    initialized = None
    try:
        send({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "protocolVersion": "2024-11-05",
                "capabilities": {},
                "clientInfo": {"name": "probe", "version": "1.0"},
            },
        })
        initialized = wait_for_id(1)
        if not initialized:
            return 2
        info = initialized.get("result", {}).get("serverInfo", {})
        caps = initialized.get("result", {}).get("capabilities", {})
        print(f"  [ok] serverInfo={info}")
        print(f"  [ok] capabilities={sorted(caps.keys())}")

        send({"jsonrpc": "2.0", "method": "notifications/initialized"})

        send({"jsonrpc": "2.0", "id": 2, "method": "tools/list", "params": {}})
        tools_msg = wait_for_id(2)
        if not tools_msg:
            return 3
        tools = tools_msg.get("result", {}).get("tools", [])
        names = [t.get("name") for t in tools]
        print(f"  [ok] tools={len(names)}")
        for n in names:
            print(f"       - {n}")

        send({"jsonrpc": "2.0", "id": 3, "method": "resources/list", "params": {}})
        res = wait_for_id(3, timeout=10)
        if res is not None:
            items = res.get("result", {}).get("resources", [])
            print(f"  [ok] resources={len(items)}")

        # 真正调一个管理工具，验证工具层可达
        send({"jsonrpc": "2.0", "id": 4, "method": "tools/call",
              "params": {"name": "idalib_list", "arguments": {}}})
        call = wait_for_id(4, timeout=20)
        if call:
            result = call.get("result", {})
            text = ""
            for c in result.get("content", []):
                text += c.get("text", "")
            print(f"  [ok] idalib_list -> {text[:300] or json.dumps(result)[:300]}")
        return 0
    finally:
        try:
            proc.stdin.close()
        except Exception:
            pass
        time.sleep(0.3)
        if proc.poll() is None:
            proc.terminate()
        try:
            proc.wait(timeout=5)
        except Exception:
            proc.kill()
        print("== 结束 ==")


if __name__ == "__main__":
    sys.exit(main())
