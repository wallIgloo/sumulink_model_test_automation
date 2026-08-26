# Simulink Test Automation - Work Handoff

## Current baseline

This folder is the Work-ready baseline after adding target-model selection and CUT path discovery.

The automation assumes one selected Simulink model contains all CUT subsystems for the current verification batch. `TestManagement.xlsx` does not need a `ModelName` column.

## Recommended user flow

```matlab
st_setup
st_find_target_paths
st_run_from_harness
```

If Harnesses already exist:

```matlab
st_setup
st_find_target_paths
st_run_after_harness
```

`st_find_target_paths` performs the model selection and path resolution before any long Harness compile begins.

## Path finder behavior

1. Search `cfg.ModelSearchRoot` for `.slx` / `.mdl` files.
2. User selects one target model.
3. The selected model is loaded by full file path.
4. Every enabled Excel `CUTName` is searched as an exact Subsystem name inside that model.
5. One match is accepted automatically.
6. Multiple matches show a manual selection dialog.
7. No match is recorded as FAIL.
8. Resolved paths are written only to the existing `CUTPath` column.
9. The selected model is stored in `runtime_target.mat`.

## Excel columns

Required:

- `CUTName`
- `CUTPath`
- `HarnessName`
- `TestCaseName`

Optional:

- `No`
- `Enabled`

No `ModelName` column is required.

## Verification rules

- Verify targets are Harness top-level Outport signals that also exist as Test Assessment Input Data Symbols.
- CUT input-side Assessment symbols are not verify targets.
- Scalar numeric data: `verify(A == 0);`
- Numeric arrays: all elements are verified with linear indexing.
- Bus values are recursively expanded to leaf elements.
- `cfg.VerifyFirstBusElementOnly = true` verifies only the first repeated Bus instance, while still verifying all distinct Bus fields and numeric leaf-array elements.

## Test execution / expected value calibration

- `cfg.RunGeneratedTests` controls whether generated Enabled Test Cases run automatically.
- `cfg.AutoUpdateExpectedOnFail` can update failed verify RHS values using the actual Harness Outport value at `cfg.ExpectedValueSampleTime`.
- `cfg.RerunAfterExpectedUpdate` controls automatic rerun after an expected-value update.
- `cfg.VerifyAtSampleTimeOnly` controls whether the Assessment transition waits until the sample time.

## Runtime target

`runtime_target.mat` is generated data and should normally not be treated as a source file. Re-run `st_find_target_paths` when the target model changes or moves.

## Known considerations

- Harness creation still uses normal compile mode and can be slow on large models.
- Exact CUT-name duplicates require manual path selection.
- Model references and linked-library internals are not used as CUT search targets by the current path finder (`FollowLinks = off`).
- Automatically adopting current simulation output as an expected value should be used intentionally because it can turn an incorrect current model behavior into a new expected value.
