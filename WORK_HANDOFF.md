# Simulink Test Automation - Work Handoff

## Current baseline: v0.9.1

The current preferred path workflow is deliberately simple and auditable.

1. Select one target model with `st_select_target_model`.
2. If `Targets.CUTName` is already arranged with Excel native indentation, run `st_fill_temp_paths_from_indent` to flatten that hierarchy into one-line `CUTPath` strings.
3. If any temporary path is incorrect, run `st_export_subsystem_paths` and use the actual `ModelSubsystems.FullPath` inventory for manual correction.
4. Run `st_pre_validate_targets` before Harness creation.
5. Continue with `st_run_from_harness` or `st_run_after_harness`.

## Indentation path rule

Example Excel display:

```text
A
    B
    C
        D
    E
```

The source is the cell format property `IndentLevel`, not spaces in CUTName and not a numeric Depth column.

Generated one-line paths:

```text
MODEL/A
MODEL/A/B
MODEL/A/C
MODEL/A/C/D
MODEL/A/E
```

`st_fill_temp_paths_from_depth` is now only a compatibility wrapper for the corrected indent-based helper.

## Model inventory

`st_export_subsystem_paths` writes `ModelSubsystems` with exact subsystem names and actual Simulink hierarchy. Visual hierarchy uses Excel native indentation. Actual Depth and FullPath are retained as data columns.

## Test defaults

```matlab
cfg.OverwriteTestFile = true;
cfg.RunGeneratedTests = true;
cfg.AutoUpdateExpectedOnFail = true;
cfg.RerunAfterExpectedUpdate = true;
```

## Important caution

Automatic expected-value update intentionally adopts current simulation output as the new expected RHS. Keep it enabled only when that behavior is desired for the current verification workflow.
