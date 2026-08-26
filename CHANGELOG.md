# Changelog

## v0.5 - Work-ready path finder baseline

- Added `st_find_target_paths.m`.
  - Searches `.slx` / `.mdl` files under `cfg.ModelSearchRoot`.
  - Lets the user select one model for the whole verification batch.
  - Resolves Excel `CUTName` values to Subsystem paths.
  - Auto-selects unique matches and prompts on duplicates.
  - Writes only the `CUTPath` column back to `TestManagement.xlsx`.
  - Stores selected model information in `runtime_target.mat`.
- Added `st_require_runtime_target.m` so automation can reopen the selected model by full file path across MATLAB sessions.
- Added `st_pre_validate_targets.m` for path-only validation before Harness creation.
- Added/updated `st_run_from_harness.m` to run Pre-Validate before any long Harness compile.
- Updated existing-Harness workflow to use the runtime-selected model and optional test execution.
- Added Harness creation entry point `st_create_harnesses.m`.
- Kept Harness top-level Outport-only verify target selection.
- Kept recursive Bus leaf verify generation and `VerifyFirstBusElementOnly` option.
- Kept optional generated-test execution and failed-verify expected-value auto update.
- Added `WORK_HANDOFF.md` for moving this baseline into ChatGPT Work.

## Earlier baseline

The project incorporates the v0.3/v0.4 changes for Signal Editor, Test Assessment, Test Manager coverage hierarchy, Harness output selection, Bus handling, generated test execution, and expected-value update.
