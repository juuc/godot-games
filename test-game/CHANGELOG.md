# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-12-24
### Changed
- Refactored the core generation system to use Godot 4's built-in `WorkerThreadPool` instead of a manual `Thread` + `Semaphore` loop.
- **Why?** This allows chunk generation to scale with CPU cores (Parallel processing) rather than being limited to a single background thread (Serial processing).
- Added `generation_mutex` to ensure thread-safe access to the chunk generation queue when running multiple worker tasks.

## [1.0.0] - 2025-12-23
### Added
- Initial release of the Infinite 2D World Generation engine.
- Features:
    - Threaded terrain generation.
    - Custom bitmask autotiling solver.
    - Render budget system for smooth drawing.
    - Safe-spawn algorithm.
    - Biome-aware decoration system (Trees).
    - Player controller with shooting mechanics.
