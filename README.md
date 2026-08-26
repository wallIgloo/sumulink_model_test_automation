# Simulink Test Automation v0.5

One selected Simulink model contains all CUT subsystems for the current verification batch. The Excel file does not need a `ModelName` column.

## 1. First-time / changed-model flow

```matlab
st_setup
st_find_target_paths
```

`st_find_target_paths`:

- searches `cfg.ModelSearchRoot` for `.slx` / `.mdl` files,
- shows a single-model selection dialog,
- loads the selected model,
- searches each enabled `CUTName` as an exact Subsystem name,
- automatically accepts a unique match,
- asks the user when the same CUT name exists at multiple paths,
- writes resolved values to the existing Excel `CUTPath` column,
- saves the selected model to `runtime_target.mat`.

Then run either:

```matlab
st_run_from_harness
```

for Harness creation onward, or:

```matlab
st_run_after_harness
```

when Harnesses already exist.

## 2. Management Excel

Required columns:

| Column | Purpose |
| --- | --- |
| `CUTName` | Exact Subsystem block name to search |
| `CUTPath` | Resolved full Simulink path |
| `HarnessName` | Harness name |
| `TestCaseName` | Test Manager Test Case name |

Optional:

- `No`
- `Enabled`

`CUTPath` may be blank before `st_find_target_paths` is run.

## 3. Pre-validation

`st_pre_validate_targets` runs before Harness creation and checks only:

- CUTPath is present,
- the path resolves in the selected model,
- the block exists,
- the block is a Subsystem.

It deliberately does not require a Harness, Signal Editor, Assessment, Scenario, or Test Case.

## 4. Harness / Signal Editor / Assessment

Current defaults are controlled by `st_config.m`.

Important verify rules:

- With `cfg.VerifyHarnessOutportsOnly = true`, only signals connected to top-level Harness Outport blocks are considered verify targets.
- Those names must also exist as Test Assessment Input Data Symbols.
- Assessment input-side signals that are not Harness outputs are ignored.
- Numeric arrays are expanded element by element.
- Bus values are recursively expanded to leaf elements.
- `cfg.VerifyFirstBusElementOnly = true` keeps only the first repeated Bus instance such as `a(1,1)`, but still verifies every distinct field and every numeric leaf-array element inside that instance.

## 5. Test Manager

The generated Test File is:

```text
{SelectedModel}.mldatx
```

The default suite is:

```text
New Test Suite 1
```

Each Test Case uses one table iteration named `Iteration 1`. Signal Editor and Test Sequence scenario selection is applied at the iteration level.

Coverage recording is enabled at Test File, Test Suite, and Test Case levels.

## 6. Optional test execution

```matlab
cfg.RunGeneratedTests = false;
```

Set to `true` to run generated Enabled Test Cases after Test Manager creation.

Tests can also be run independently:

```matlab
st_run_generated_tests
```

## 7. Optional expected-value update

```matlab
cfg.AutoUpdateExpectedOnFail = false;
cfg.ExpectedValueSampleTime = 0.01;
cfg.RerunAfterExpectedUpdate = true;
cfg.VerifyAtSampleTimeOnly = false;
```

When enabled, failed verify RHS values can be replaced with the actual logged Harness output value at `ExpectedValueSampleTime` and then rerun.

Use this intentionally: the current model output becomes the new expected value.

## 8. Main entry points

```matlab
st_find_target_paths
st_pre_validate_targets
st_create_harnesses
st_run_from_harness
st_run_after_harness
st_run_generated_tests
```

## 9. Runtime target

`runtime_target.mat` stores the selected target model name and full file path. Re-run `st_find_target_paths` if the model changes or moves.

See `WORK_HANDOFF.md` for the current project contract and Work migration notes.
