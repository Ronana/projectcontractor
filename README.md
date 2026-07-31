# Project Contractor

A mobile idle/incremental construction tycoon game built with **Godot 4.6** and **GDScript**. Start with a shed, end with a skyline — mine raw materials, craft components, manage a crew, and complete building contracts across 8 tiers, from a humble Shed to a towering Skyscraper.

> Solo developer project by Ronan Frew. Built as both a passion project and a portfolio piece on my path into game development (HNC Computing, 2026).

## Screenshots

*Coming soon — see [`docs/screenshots/`](docs/screenshots/)*

## Gameplay Features

- **Mining & crafting loop** — tap or idle-mine raw resources (timber, stone, sand, steel ore...) and craft them into building materials
- **8 building tiers** — progress from Shed to Skyscraper, each with multi-stage builds and unlockable blueprints
- **Crew management** — hire crew members to automate work
- **Prestige system** — complete contracts to reset with permanent bonuses and grow a persistent skyline
- **Skill tree & upgrades** — long-term progression layered on top of the core loop
- **Missions & Site Inspections** — weekly missions plus 16 permanent inspection challenges (Clean Build / Fast Track) rewarding blueprint fragments
- **Trade Shows** — rotating 7-day live events with tasks and tiered gem rewards
- **Delivery pallets & chests** — animated reward openings
- **Offline progress** — the site keeps working while you're away
- **Customisable quick bar** — pin your 4 favourite shortcuts

## Tech Highlights

- **Engine:** Godot 4.6 (GL Compatibility renderer, mobile-first: 720×1280 portrait, DPI-aware UI scaling)
- **Architecture:** autoload singletons for game state, save/load, offline progress, and data-driven content databases (builds, upgrades, missions, blueprints, skills, inspections, trade shows, chests)
- **Data-driven design:** building tiers, stages, materials and crew defined as Godot `Resource` classes
- **Persistence:** custom save system with versioning and prestige-safe permanent unlocks
- **Platform target:** Android (exports configured), runs on desktop for development

## Project Structure

```
├── assets/          # Sprites, UI art, animations
├── data/resources/  # Game data resources
├── docs/            # Development log & screenshots
├── scenes/main/     # Main scene + gameplay UI (Main.gd)
├── scripts/
│   ├── autoload/    # Singletons: GameState, SaveManager, content databases
│   └── data/        # Resource class definitions
└── project.godot
```

## Running the Project

1. Install [Godot 4.6+](https://godotengine.org/download)
2. Clone the repo and open `project.godot` in the Godot editor
3. Run the main scene (`scenes/main/Main.tscn`)

## Development Log

Detailed session-by-session progress is kept in [`docs/progress_log.md`](docs/progress_log.md).

## License

Copyright © 2026 Ronan Frew. All rights reserved.

This repository is shared for portfolio and educational viewing. The code and assets may not be copied, modified, or redistributed without permission.
