# Atlas Commands - GitHub Bridge

This repo is the **command queue** between Atlas (VPS) and your Windows machine.

## How It Works

1. You send Atlas a command via Telegram
2. Atlas writes the command to a JSON file here
3. Your Windows watcher script pulls this repo every 5 seconds
4. Your script executes the command via the companion service
5. Your script deletes the file (command done)

## Setup (Windows)

See `watcher.bat` for the polling script.

## Command Format

```json
{
  "id": "cmd-12345",
  "timestamp": "2026-03-23T05:30:00Z",
  "commands": [
    {
      "type": "primitive",
      "primitive": "mouse.move",
      "params": {"x": 500, "y": 300}
    },
    {
      "type": "primitive",
      "primitive": "mouse.click",
      "params": {"button": "left"}
    }
  ]
}
```
