# Simulink Test Automation - Work Handoff

## Current baseline: v0.9.0

The path workflow now supports a deliberately simple temporary mode based on the `Depth` column in `TestManagement.xlsx / Targets`. This is separate from the recommendation Path Finder.

### Temporary Depth path helper

```matlab
st_fill_temp_paths_from_depth
```

- Requires `CUTName`, `CUTPath`, and `Depth` columns.
- Uses row order plus Depth only.
- The nearest preceding lower-Depth row is the ancestor.
- Does not attempt duplicate-name inference.
- Writes temporary paths even when they do not exist in the model; `DepthPathResult` records whether each exact path exists.
- Existing/manual paths are preserved by default.
- `st_fill_temp_paths_from_depth(true)` forces overwrite.
- Disabled rows still participate in hierarchy context.

### Manual inventory helper

```matlab
st_export_subsystem_paths
```

Exports every actual model Subsystem into `ModelSubsystems`. `CUTName` uses Excel native `IndentLevel`; the cell value itself is not prefixed with spaces or dashes.

### Default run behavior

```matlab
cfg.OverwriteTestFile = true;
cfg.RunGeneratedTests = true;
cfg.AutoUpdateExpectedOnFail = true;
cfg.RerunAfterExpectedUpdate = true;
```

The normal workflow therefore recreates the Test File, executes generated Test Cases, updates expected verify RHS values on failure, and reruns if an update occurred.

### Recommended flow

```matlab
st_setup
st_fill_temp_paths_from_depth   % optional fast initial fill
st_export_subsystem_paths        % optional manual reference
st_pre_validate_targets
st_run_from_harness
```

If Harnesses already exist, use `st_run_after_harness`.

---

# v0.8 handoff note

For ambiguous CUT names, the preferred safe workflow is manual path matching from a generated subsystem inventory. Run `st_export_subsystem_paths` to recreate `TestManagement.xlsx / ModelSubsystems`. The inventory `CUTName` retains the exact subsystem name and is visually indented with Excel native `IndentLevel` using the actual Simulink hierarchy depth. No spaces or prefix characters are inserted into the cell value; `RawCUTName` also retains the exact subsystem name. Users manually copy the desired `FullPath` into `Targets.CUTPath`; `st_pre_validate_targets` remains the gate before Harness creation. `st_find_target_paths` is retained only as an optional recommendation helper.

---

# Work handoff - Simulink Test Automation v0.6

## Current project goal

Automate Simulink Test setup for many subsystem CUTs contained in one selected model.

## Target model policy

- There is no `ModelName` column in Excel.
- The user selects one model per automation run.
- The selection is stored in `runtime_target.mat` as `TopModel` / `ModelFile`.
- Example/documentation model placeholder: `TEST_TARGET_MODEL_NAME`.

## Path resolution policy

`st_find_target_paths` is a discovery step and `st_pre_validate_targets` is a validation step. Keep these responsibilities separate.

For duplicated CUT names:

1. collect all candidate subsystem paths;
2. resolve existing valid paths and unique matches first;
3. use those resolved paths as anchors;
4. rank ambiguous candidates structurally;
5. Excel row proximity is only a secondary hint and must never imply parenthood;
6. a user-confirmed path becomes an anchor immediately for later ambiguous CUTs.

The current scoring helper is `st_score_path_candidates.m`.

Strong evidence includes descendant/ancestor relationship, shared parent/grandparent, deep common ancestor, and short tree distance. Both previous and next uniquely resolved rows may act as anchors.

## Existing downstream rules

- Pre-validation checks CUT path existence and Subsystem type before harness creation.
- Verify targets are Test Assessment Inputs corresponding to top-level Harness Outport signals.
- `VerifyFirstBusElementOnly` can restrict repeated Bus arrays to the first Bus instance while still verifying all fields / numeric leaf elements in that instance.
- Optional generated-test execution and expected-value calibration are controlled in `st_config.m`.

## Main entry points

```matlab
st_find_target_paths
st_run_from_harness
st_run_after_harness
st_run_generated_tests
```


## v0.7 path finder update

- Excel depth/indent is intentionally ignored.
- Duplicate CUT selection shows nearby Excel rows and resolved paths.
- Candidates under a confidently resolved later Excel CUT are hard-filtered before recommendation scoring.
- Remaining candidates are ranked with a stable context derived from several nearby resolved paths.
- `cfg.PathFinderHighlightSelection` controls optional Simulink highlighting and defaults to false.
- `cfg.PathFinderExcelContextRows` controls the nearby Excel context shown in the selection dialog.
