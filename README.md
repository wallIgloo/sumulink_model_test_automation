# Simulink Test Automation v0.3

기존 Harness가 이미 생성되어 있고, 관리 Excel에 CUTPath / HarnessName / TestCaseName이 있는 상태부터 사용하는 자동화 프로젝트입니다.

이번 v0.3의 핵심 변경은 **Test Assessment verify 대상을 설정으로 전환할 수 있게 한 것**입니다.

```matlab
cfg.VerifyAllAssessmentInputs = true;
```

- `true`  : Test Assessment에 등록된 모든 Input Data Symbol을 verify
- `false` : 기존 방식대로 CUT의 직접 Outport만 verify

---

## 1. 폴더 구조

권장 구조:

```text
프로젝트/
├─ TEST_TARGET_MODEL_NAME.slx
└─ auto/
   ├─ TestManagement.xlsx
   ├─ st_config.m
   ├─ st_setup.m
   ├─ st_run_after_harness.m
   ├─ ...
   └─ result/
```

압축을 푼 뒤 `SimulinkTestAutomation_v03` 폴더의 파일들을 프로젝트의 `auto` 폴더에 넣어 사용할 수 있습니다.

---

## 2. TestManagement.xlsx

기본 파일명:

```text
TestManagement.xlsx
```

기본 Sheet:

```text
Targets
```

필수 컬럼:

| CUTName | CUTPath | HarnessName | TestCaseName |
|---|---|---|---|
| AbsoluteTime_Service_Response | TEST_TARGET_MODEL_NAME/.../AbsoluteTime_Service_Response | TEST_TARGET_MODEL_NAME_Harness4 | AbsoluteTime_Service_Response_001 |

선택 컬럼:

- `Enabled`
- `No`

`No`가 없으면 프로그램이 Excel 행 순서 기준으로 자동 생성합니다.
`Enabled`가 없으면 모든 행을 처리합니다.

---

## 3. st_config.m

최소한 실제 최상위 모델명을 수정합니다.

```matlab
cfg.TopModel = 'TEST_TARGET_MODEL_NAME';
```

### Assessment verify 모드

#### 모든 Assessment Input을 verify

```matlab
cfg.VerifyAllAssessmentInputs = true;
```

이 모드에서는 Test Assessment에 등록되어 있는 모든 `Input Data Symbol`을 대상으로 합니다.

예를 들어 Assessment Input이:

```text
EnableCond
TempErr
FailThr
DataOutput
```

이라면 모두 `step2`에 verify가 생성됩니다.

이 모드는 verify 대상을 찾기 위해 Top Model을 compile하지 않습니다.

#### CUT 직접 Outport만 verify

```matlab
cfg.VerifyAllAssessmentInputs = false;
```

기존 방식입니다. CUT 경계의 직접 Outport만 verify 대상으로 사용합니다.
이 경우 출력 width 확인을 위해 Top Model을 한 번 compile합니다.

---

## 4. verify 생성 규칙

현재 기대값은 모두 임시 `0`입니다.

Scalar:

```matlab
verify(SigState == 0);
```

Width가 4라면:

```matlab
verify(DataOutput(1) == 0);
verify(DataOutput(2) == 0);
verify(DataOutput(3) == 0);
verify(DataOutput(4) == 0);
```

Assessment Input 전체 모드에서는 `sltest.testsequence.readSymbol`의 `Size` 값을 사용해 element 수를 계산합니다.

- Size가 비어 있으면 scalar로 간주합니다.
- `[2 3]` 같은 숫자 Size는 6개 element로 처리합니다.
- `N`, `[1 N]` 같은 계산식/변수 기반 Size는 안전하게 element 수를 알 수 없으므로 해당 CUT를 FAIL 처리합니다.

---

## 5. Test Assessment 구조

각 CUT에 대해 Scenario 이름은:

```text
UT_REQ_{CUTName}_001
```

구조:

```text
Scenario
├─ step1
│   Action: 없음
│
│   true
│    ↓
└─ step2
    verify(...)
```

---

## 6. Signal Editor

CUT에 직접 Inport가 있을 경우:

- Sample Time = `0.01`
- 첫 Scenario 이름 = `UT_REQ_{CUTName}_001`
- 입력 값/파형은 변경하지 않음

---

## 7. Harness

기존 Harness를 그대로 사용합니다.

Harness Configuration Parameters:

```text
Stop Time = 0.01
```

Harness 생성 기능은 v0.3의 기본 흐름에 포함하지 않습니다.

---

## 8. Test Manager

생성 구조:

```text
{TopModel}.mldatx
└─ New Test Suite 1
   └─ {TestCaseName}
      └─ Iteration 1
```

### Test Case Inputs

기본 Test Case 레벨에서는 Scenario를 선택하지 않습니다.

```text
Signal Editor Scenario       OFF
Test Sequence Block          Test Assessment 지정
Override with Scenario       없음
```

Scenario 선택은 `Iteration 1`에서만 합니다.

```text
Signal Editor Scenario = UT_REQ_{CUTName}_001
Test Sequence Scenario = UT_REQ_{CUTName}_001
```

### Coverage

`Record coverage for system under test`를 사용합니다.
Coverage는 Test File → Test Suite → Test Case 레벨에서 활성화합니다.

---

## 9. MATLAB 시작

프로젝트 루트가 Current Folder라면:

```matlab
addpath('auto');
st_setup;
```

또는 `auto` 폴더를 Current Folder로 열고:

```matlab
st_setup;
```

---

## 10. 권장 실행 순서

처음에는 Excel의 `Enabled`를 이용해 CUT 하나만 TRUE로 두는 것을 권장합니다.

### 1) 경로/Harness 검증

```matlab
R = st_validate_targets;
```

### 2) Harness StopTime

```matlab
st_configure_harnesses
```

### 3) Signal Editor

```matlab
st_configure_signal_editors
```

### 4) Test Assessment

```matlab
st_configure_assessments
```

### 5) Test Manager

기존 `.mldatx`를 새로 만들 경우:

```matlab
cfg.OverwriteTestFile = true;
```

가 `st_config.m`에 설정되어 있어야 합니다.

그 다음:

```matlab
st_create_test_manager
```

각 단계가 정상 동작한 것을 확인한 뒤 전체 실행:

```matlab
st_run_after_harness
```

---

## 11. 모델이 paused / compiled 상태로 남은 경우

v0.3의 `st_force_model_stopped`는 model-function compile로 인해 `paused`처럼 표시되는 경우를 고려합니다.

- `compiled` 또는 `paused`이면 먼저 `feval(..., 'term')`을 시도
- 실제 일반 시뮬레이션 pause이면 `SimulationCommand='stop'`으로 fallback

수동 확인:

```matlab
st_force_model_stopped('TEST_TARGET_MODEL_NAME');
get_param('TEST_TARGET_MODEL_NAME', 'SimulationStatus')
```

결과는:

```text
stopped
```

이어야 합니다.

---

## 12. 결과 파일

각 단계 결과는 `TestManagement.xlsx`의 결과 Sheet에 기록을 시도하고, 별도로 `result` 폴더에 CSV를 남깁니다.

```text
ValidationResult.csv
HarnessConfigResult.csv
SignalEditorResult.csv
AssessmentResult.csv
TestManagerResult.csv
```

`AssessmentResult`에는 다음 정보가 추가됩니다.

- `VerifyMode`
- `VerifyTargetCount`
- `VerifyCount`

예:

```text
VerifyMode = ALL_ASSESSMENT_INPUTS
VerifyTargetCount = 7
VerifyCount = 10
```

다차원 Symbol이 있으면 Target 수보다 실제 verify 줄 수가 많아질 수 있습니다.

---

## 13. 현재 범위 밖

아직 자동화하지 않는 항목:

- Signal Editor 입력 파형/초기값/변경값 결정
- 실제 요구사항 기반 expected value 결정
- Enum/Bus별 expected value 자동 처리
- 추가 Scenario `_002`, `_003` 자동 생성
- 변수/표현식 기반 Assessment Size의 자동 해석
