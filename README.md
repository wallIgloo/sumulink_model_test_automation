# Simulink Test Automation v0.9.1

## Recommended path workflow

### 1. Select the target model

```matlab
st_setup
st_select_target_model
```

### 2. Build temporary CUTPath values from Excel indentation

`Targets.CUTName` may already be visually hierarchical using Excel's native cell indentation.

Example appearance in Excel:

```text
A
    B
    C
        D
    E
```

Run:

```matlab
st_fill_temp_paths_from_indent
```

The helper reads each CUTName cell's actual Excel `IndentLevel` property and writes one-line CUTPath values:

```text
TEST_TARGET_MODEL_NAME/A
TEST_TARGET_MODEL_NAME/A/B
TEST_TARGET_MODEL_NAME/A/C
TEST_TARGET_MODEL_NAME/A/C/D
TEST_TARGET_MODEL_NAME/A/E
```

It does **not** parse leading spaces and does **not** use a numeric `Depth` column. Indentation is only a temporary hierarchy hint. If a path is wrong, correct that CUTPath manually.

By default existing/manual CUTPath values are protected:

```matlab
cfg.IndentPathOverwriteExisting = false;
```

To rebuild every CUTPath from indentation:

```matlab
st_fill_temp_paths_from_indent(true)
```

Results are also written to `IndentPathResult`.

### 3. Export the actual model hierarchy when manual correction is needed

```matlab
st_export_subsystem_paths
```

This recreates `TestManagement.xlsx / ModelSubsystems`. `CUTName` retains the exact block name and hierarchy is shown using Excel native `IndentLevel`. The actual model `Depth`, `ParentName`, `RelativePath`, and `FullPath` are also exported.

Use `FullPath` to correct any temporary path in `Targets.CUTPath`.

### 4. Validate and run

```matlab
st_pre_validate_targets
st_run_from_harness
```

If Harnesses already exist:

```matlab
st_run_after_harness
```

## Default test behavior

The requested execution/update defaults remain enabled:

```matlab
cfg.OverwriteTestFile = true;
cfg.RunGeneratedTests = true;
cfg.AutoUpdateExpectedOnFail = true;
cfg.RerunAfterExpectedUpdate = true;
```

So the normal workflow recreates/overwrites the generated Test File, runs generated Test Cases, updates failed verify expected RHS values from the configured sample time, and reruns after updates.

## Compatibility

`st_fill_temp_paths_from_depth` remains only as a compatibility wrapper and now delegates to `st_fill_temp_paths_from_indent`. New code should call the indent-named function directly.
