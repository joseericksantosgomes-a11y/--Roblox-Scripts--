# Smart Tab Library

Inject custom tabs and settings-style controls into the **Roblox Settings / Esc menu**.

Compatible with most executors via `loadstring` + `HttpGet`.

---

## Loadstring

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/joseericksantosgomes-a11y/--Roblox-Scripts--/refs/heads/main/SmartTab.lua"))()
```

Then create tabs and elements **after** the loadstring.

---

## Features

- Custom tabs inside the Roblox HubBar (with horizontal scroll)
- Each tab has its own **PageView** content area
- Switching tabs hides the previous PageView and shows the new one
- Reopening the Settings menu restores the last selected custom tab
- Components styled like Roblox settings UI
- **Lucide icons** support (names, `rbxassetid://`, or numeric IDs)
- **SetOption** lock/unlock from inside callbacks
- **SizeType** (`Full` / `Default`) and **Side** (`Left` / `Right`)

---

## Quick Start

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/joseericksantosgomes-a11y/--Roblox-Scripts--/refs/heads/main/SmartTab.lua"))()

Tab {
    Name = "Panel",
    Icon = "settings"
}

Label {
    Tab = "Panel",
    Text = "General",
    Icon = "sliders-horizontal",
    Description = "Main options"
}

Button {
    Tab = "Panel",
    Text = "Run",
    Icon = "play",
    SizeType = "Full",
    Callback = function(ctrl)
        print("Clicked")
    end
}
```

Open the Roblox menu (**Esc → Settings / Options**) and select the **Panel** tab.

---

## API Reference

### `Tab`

Creates a custom tab in the settings HubBar.

| Field | Type | Description |
|-------|------|-------------|
| `Name` | string | Tab title (also used as key for elements) |
| `Icon` | string/number | Lucide name, `rbxassetid://...`, or asset id |

```lua
Tab {
    Name = "Panel",
    Icon = "settings"
}
```

---

### `Label`

Section title + optional description.

| Field | Type | Description |
|-------|------|-------------|
| `Tab` | string | Parent tab name |
| `Text` | string | Title |
| `Description` | string? | Subtitle |
| `Icon` | string? | Optional icon |

```lua
Label {
    Tab = "Panel",
    Text = "Combat",
    Icon = "sword",
    Description = "Combat related options"
}
```

---

### `Button` / `BlueButton`

| Field | Type | Description |
|-------|------|-------------|
| `Tab` | string | Parent tab |
| `Text` | string | Button label |
| `Icon` | string? | Optional icon |
| `SizeType` | `"Full"` \| `"Default"` | Full width or compact (~160px) |
| `Side` | `"Left"` \| `"Right"` | Place side by side on the same row |
| `Callback` | function | `function(ctrl)` |

```lua
Button {
    Tab = "Panel",
    Text = "Leave",
    Icon = "log-out",
    SizeType = "Default",
    Side = "Left",
    Callback = function(ctrl)
        print("Leave")
    end
}

BlueButton {
    Tab = "Panel",
    Text = "Continue",
    Icon = "play",
    SizeType = "Default",
    Side = "Right",
    Callback = function(ctrl)
        ctrl.SetOption("Locked")
    end
}
```

---

### `Toggle`

| Field | Type | Description |
|-------|------|-------------|
| `Tab` | string | Parent tab |
| `Text` | string | Label |
| `Icon` | string? | Optional icon |
| `Default` | boolean | Initial state |
| `SizeType` | `"Full"` \| `"Default"` | Width style |
| `Side` | `"Left"` \| `"Right"` | Side placement |
| `Callback` | function | `function(state, ctrl)` |

```lua
Toggle {
    Tab = "Panel",
    Text = "ESP",
    Icon = "eye",
    Default = false,
    SizeType = "Full",
    Callback = function(state, ctrl)
        print("ESP:", state)
    end
}
```

---

### `Textbox` / `Input`

| Field | Type | Description |
|-------|------|-------------|
| `Tab` | string | Parent tab |
| `Text` | string | Label |
| `Icon` | string? | Optional icon |
| `Placeholder` | string? | Placeholder text |
| `Default` | string? | Initial text |
| `SizeType` | `"Full"` \| `"Default"` | Width style |
| `Side` | `"Left"` \| `"Right"` | Side placement |
| `Callback` | function | `function(text, enterPressed, ctrl)` |

```lua
Textbox {
    Tab = "Panel",
    Text = "Player",
    Icon = "user",
    Placeholder = "Username...",
    SizeType = "Full",
    Callback = function(text, enter, ctrl)
        print(text)
    end
}
```

---

### `Dropdown`

| Field | Type | Description |
|-------|------|-------------|
| `Tab` | string | Parent tab |
| `Text` | string | Label |
| `Icon` | string? | Optional icon |
| `Options` | table | List of strings |
| `Callback` | function | `function(selected, index, ctrl)` |

Scrollable list (shows up to 5 options, drag for more). Selected option is highlighted.

```lua
Dropdown {
    Tab = "Panel",
    Text = "Language",
    Icon = "languages",
    Options = {"English", "Portuguese", "Spanish", "French", "German", "Italian"},
    Callback = function(selected, index, ctrl)
        print(selected, index)
    end
}
```

---

### `Slider`

| Field | Type | Description |
|-------|------|-------------|
| `Tab` | string | Parent tab |
| `Text` | string | Label |
| `Icon` | string? | Optional icon |
| `Min` | number | Minimum value |
| `Max` | number | Maximum value |
| `Default` | number? | Starting value |
| `Callback` | function | `function(value, ctrl)` |

```lua
Slider {
    Tab = "Panel",
    Text = "Volume",
    Icon = "volume-2",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value, ctrl)
        print(value)
    end
}
```

---

### `Selector`

Alias of `Dropdown` (left/right style can be extended later).

---

## SizeType & Side

Applies to **Button**, **BlueButton**, **Toggle**, **Textbox/Input**.

| Property | Values | Behavior |
|----------|--------|----------|
| `SizeType` | `"Full"` | Stretches to full content width |
| `SizeType` | `"Default"` | Compact width (~160px) |
| `Side` | `"Left"` | Half-width, left slot of a row |
| `Side` | `"Right"` | Half-width, right slot of a row |

`Side = Left` + `Side = Right` on consecutive elements places them on the **same row**.

```lua
Button {
    Tab = "Panel",
    Text = "A",
    SizeType = "Default",
    Side = "Left",
    Callback = function(ctrl) end
}

BlueButton {
    Tab = "Panel",
    Text = "B",
    SizeType = "Default",
    Side = "Right",
    Callback = function(ctrl) end
}
```

---

## SetOption (Lock / Unlock)

**Must be called inside `Callback`**, via the `ctrl` object.

```lua
ctrl.SetOption("Locked")              -- lock THIS element
ctrl.SetOption("Unlocked")            -- unlock THIS element
ctrl.SetOption("Unlocked", "Continue") -- unlock another element by Text
ctrl.IsLocked()                       -- returns boolean
```

Global helper:

```lua
SetOption("Continue", "Unlocked")
SetOption("Continue", "Locked", "Panel") -- with tab name
```

### Example

```lua
BlueButton {
    Tab = "Panel",
    Text = "Continue",
    Icon = "play",
    Callback = function(ctrl)
        print("Continue pressed")
        ctrl.SetOption("Locked")
    end
}

Button {
    Tab = "Panel",
    Text = "Unlock",
    Icon = "unlock",
    Callback = function(ctrl)
        ctrl.SetOption("Unlocked", "Continue")
    end
}
```

When **Locked**, a dark overlay with the text `Locked` is shown and the action is blocked until unlocked.

---

## Icons (Lucide)

Uses [Footagesus/Icons](https://github.com/Footagesus/Icons) with type `lucide`.

| Format | Example |
|--------|---------|
| Lucide name | `"house"`, `"settings"`, `"user"`, `"lock"` |
| Asset URL | `"rbxassetid://6031097220"` |
| Numeric id | `6031097220` |

Browse names at: [https://lucide.dev/icons](https://lucide.dev/icons)

Works on: `Tab`, `Label`, `Button`, `BlueButton`, `Toggle`, `Dropdown`, `Slider`, `Input` / `Textbox`.

---

## Callback Signatures

| Component | Callback |
|-----------|----------|
| Button / BlueButton | `function(ctrl)` |
| Toggle | `function(state, ctrl)` |
| Dropdown | `function(selected, index, ctrl)` |
| Slider | `function(value, ctrl)` |
| Input / Textbox | `function(text, enterPressed, ctrl)` |

---

## Full Example

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/joseericksantosgomes-a11y/--Roblox-Scripts--/refs/heads/main/SmartTab.lua"))()

Tab {
    Name = "Panel",
    Icon = "settings"
}

Label {
    Tab = "Panel",
    Text = "Main",
    Icon = "layout-dashboard",
    Description = "Smart Tab demo"
}

Button {
    Tab = "Panel",
    Text = "Leave",
    Icon = "log-out",
    SizeType = "Default",
    Side = "Left",
    Callback = function(ctrl)
        print("Leave")
    end
}

BlueButton {
    Tab = "Panel",
    Text = "Continue",
    Icon = "play",
    SizeType = "Default",
    Side = "Right",
    Callback = function(ctrl)
        ctrl.SetOption("Locked")
    end
}

Button {
    Tab = "Panel",
    Text = "Unlock Continue",
    Icon = "unlock",
    SizeType = "Full",
    Callback = function(ctrl)
        ctrl.SetOption("Unlocked", "Continue")
    end
}

Toggle {
    Tab = "Panel",
    Text = "ESP",
    Icon = "eye",
    SizeType = "Full",
    Callback = function(state, ctrl)
        print("ESP:", state)
    end
}

Dropdown {
    Tab = "Panel",
    Text = "Language",
    Icon = "languages",
    Options = {"English", "Portuguese", "Spanish", "French", "German", "Italian", "Japanese"},
    Callback = function(selected, index, ctrl)
        print(selected)
    end
}

Slider {
    Tab = "Panel",
    Text = "Volume",
    Icon = "volume-2",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(value, ctrl)
        print(value)
    end
}

Textbox {
    Tab = "Panel",
    Text = "Username",
    Icon = "user",
    Placeholder = "Type here...",
    SizeType = "Full",
    Callback = function(text, enter, ctrl)
        print(text)
    end
}
```

---

## Notes

- Run the script, then open the Roblox **Settings** menu for the tab to appear.
- Custom tab content uses a dedicated PageView; native tabs remain usable.
- Closing and reopening Settings restores the last custom tab you had selected.
- Requires HTTP access for Lucide icons (`Footagesus/Icons`).

---

## License

Free to use and modify. Icons belong to their respective authors (Lucide / Roblox assets).
