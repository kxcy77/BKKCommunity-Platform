#!/usr/bin/env python3
"""Run bounded XML Android journeys via ADB; never write credentials to reports."""
import argparse
import json
import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("journey", type=Path)
parser.add_argument("--serial", required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
adb = os.environ.get("ADB", "adb")
root = ET.parse(args.journey).getroot()
args.output.mkdir(parents=True, exist_ok=True)
report = {"journey": root.get("name"), "serial": args.serial, "results": []}

def command(*values):
    return subprocess.run([adb, "-s", args.serial, *values], check=True,
                          capture_output=True, timeout=30).stdout

def screen():
    command("shell", "uiautomator", "dump", "/sdcard/bkk-journey.xml")
    return ET.fromstring(command("exec-out", "cat", "/sdcard/bkk-journey.xml"))

def matching(tree, text):
    return [n for n in tree.iter("node")
            if n.get("text") == text or n.get("content-desc") == text]

def center(node):
    x1, y1, x2, y2 = map(int, re.findall(r"\d+", node.get("bounds")))
    if x2 <= x1 or y2 <= y1:
        raise AssertionError("Target has no visible bounds")
    return (x1 + x2) // 2, (y1 + y2) // 2

failed = False
for number, action in enumerate(root.find("actions"), 1):
    row = {"action": (action.text or "").strip(), "status": "SKIPPED", "commands": []}
    report["results"].append(row)
    if failed:
        continue
    try:
        kind, target = action.get("type"), action.get("target")
        if kind == "assert":
            deadline = time.monotonic() + 15
            while True:
                tree = screen()
                found = bool(matching(tree, target))
                if found != (action.get("absent") == "true"):
                    break
                if time.monotonic() > deadline:
                    raise AssertionError("Expected visible state not found: " + target)
                time.sleep(1)
            if action.get("screenshot"):
                path = args.output / action.get("screenshot")
                path.write_bytes(command("exec-out", "screencap", "-p"))
                row["screenshot"] = path.name
        elif kind in ("tap", "input"):
            tree = screen()
            if kind == "input":
                nodes = [n for n in tree.iter("node")
                         if n.get("class") == "android.widget.EditText"
                         and any(x.get("text") == target for x in n.iter("node"))]
            else:
                nodes = matching(tree, target)
            if not nodes:
                raise AssertionError("Visible target missing: " + target)
            x, y = center(nodes[-1] if action.get("last") == "true" else nodes[0])
            command("shell", "input", "tap", str(x), str(y))
            row["commands"].append(f"adb shell input tap {x} {y}")
            if kind == "input":
                value = os.environ[action.get("env")]
                command("shell", "input", "text", value.replace(" ", "%s"))
                row["commands"].append("adb shell input text [REDACTED_TEST_INPUT]")
                command("shell", "input", "keyevent", "4")
                row["commands"].append("adb shell input keyevent 4")
            time.sleep(1)
        elif kind == "swipe":
            tree = screen()
            nodes = [n for n in tree.iter("node") if n.get("scrollable") == "true"]
            if not nodes:
                raise AssertionError("No visible scrollable container")
            x1, y1, x2, y2 = map(int, re.findall(r"\d+", nodes[0].get("bounds")))
            x, upper, lower = (x1 + x2) // 2, y1 + (y2-y1)//4, y2-(y2-y1)//4
            command("shell", "input", "swipe", str(x), str(lower), str(x), str(upper), "500")
            row["commands"].append(f"adb shell input swipe {x} {lower} {x} {upper} 500")
            time.sleep(1)
        elif kind == "resume":
            command("shell", "input", "keyevent", "3")
            time.sleep(1)
            command("shell", "am", "start", "-n",
                    "za.co.bkkcommunity.app.debug/za.co.bkkcommunity.app.MainActivity")
            row["commands"] += ["adb shell input keyevent 3", "adb shell am start [MainActivity]"]
            time.sleep(2)
        else:
            raise ValueError("Unknown journey action type: " + str(kind))
        row["status"] = "PASSED"
    except Exception as error:
        row["status"] = "FAILED"
        # Never include subprocess stderr/argv: they may contain typed secrets.
        row["comment"] = str(error) if isinstance(error, (AssertionError, ValueError)) else type(error).__name__
        failed = True

report["status"] = "FAILED" if failed else "PASSED"
(args.output / (args.journey.stem + ".json")).write_text(json.dumps(report, indent=2) + "\n")
print(report["journey"] + ": " + report["status"])
raise SystemExit(1 if failed else 0)
