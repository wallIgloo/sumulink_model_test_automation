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
