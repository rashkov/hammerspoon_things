# Hammerspoon Configuration

A Hammerspoon configuration for macOS automation.

## Features

### Hotkeys
Global keyboard shortcuts:

- **⌘⌥⌃R**: Reload Hammerspoon configuration and display the console
- **⌘⌥⌃H**: Hide Hammerspoon console
- **⌘⌥⌃W**: Print all visible windows (debug info)
- **⌘⌥⌃X**: Print all notifications
- **⌘⌥⌃Space**: Dismiss top notification
- **⌘⌥⌃⇧Space**: Clear all notifications

### Notification Management
Notification center controls using accessibility APIs:

- Print all current notifications in console
- Dismiss the most recent notification
- Clear all notifications at once
- Expands notification stacks when needed

### UI Debugger Tools
Accessibility-based UI inspection tools:

- **⌘⌥⌃M**: Toggle element inspector (shows UI element under cursor)
- **⌘⌥⌃D**: Print DOM tree for all visible windows
- **⌘⌥⌃T**: Display interactive expandable tree viewer
- Shows accessibility attributes for UI elements

### Modules
Organized into separate modules:

- `hotkeys.lua` - Global keyboard shortcuts
- `mouse.lua` - Mouse movement functions
- `notifications.lua` - Notification center management
- `accessibility.lua` - Accessibility API utilities
- `debugger.lua` - UI inspection and debugging tools

## Installation

1. Install [Hammerspoon](https://www.hammerspoon.org/)
2. Copy this configuration to `~/.hammerspoon/`
3. Reload Hammerspoon (⌘⌥⌃R) or restart the application

## Requirements

- macOS
- Hammerspoon application
- Accessibility permissions for Hammerspoon in System Settings > Privacy & Security > Accessibility

## Usage

### Setup
1. Launch Hammerspoon
2. Grant accessibility permissions when prompted
3. The configuration loads all modules automatically

### Notification Management
Uses macOS accessibility APIs to interact with Notification Center. Requires accessibility permissions.

### UI Debugging
Tools for inspecting UI elements and accessibility attributes.

## Customization

### Hotkeys
Edit `modules/hotkeys.lua` to change shortcuts or add new ones.

### New Features
Create new modules in `modules/` and require them in `init.lua`.

## Troubleshooting

### Permissions
If features don't work:
1. Open System Settings > Privacy & Security > Accessibility
2. Ensure Hammerspoon is checked
3. Restart Hammerspoon

### Console
Use the Hammerspoon console (menu bar icon) to view output and errors.

### Configuration Changes
Reload with ⌘⌥⌃R or use the Hammerspoon menu after changes.
