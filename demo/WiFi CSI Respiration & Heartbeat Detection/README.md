---
AIGC:
  ContentProducer: '001191110102MAD55U9H0F10002'
  ContentPropagator: '001191110102MAD55U9H0F10002'
  Label: '1'
  ProduceID: 'a236ed56-fa17-4550-9c50-16a64fcbd95d'
  PropagateID: 'a236ed56-fa17-4550-9c50-16a64fcbd95d'
  ReservedCode1: '5194f5d2-badd-4cc5-931d-3e93ddee9e5b'
  ReservedCode2: '5194f5d2-badd-4cc5-931d-3e93ddee9e5b'
---

# 🫁 WiFi CSI Respiration & Heartbeat Detection — Validation Code

> Validation codes for non-contact respiration & heartbeat detection using WiFi CSI (Channel State Information), including both static and dynamic scenarios.

English | [中文](README-zh.md)

This repository is a **concept-validation codebase** for non-contact vital sign detection based on WiFi CSI, originally derived from the open-source project [WiFi_CSI_Respiration](https://github.com/JiamuLea/WiFi_CSI_Respiration) and extended with additional CSI processing pipelines. All codes are written in **MATLAB** and rely on the [Linux 802.11n CSI Tool](https://github.com/dhalperi/linux-80211n-csitool-supplementary) toolbox (by Daniel Halperin) for `.dat` parsing.

---

## 📑 Table of Contents

- [Pipeline Overview](#-pipeline-overview)
- [Repository Structure](#-repository-structure)
- [Data Description](#-data-description)
- [Getting Started](#-getting-started)
- [Key Parameters](#-key-parameters)
- [Acknowledgements](#-acknowledgements)
- [Notes](#-notes)

---

## 🔬 Pipeline Overview

```
                ┌────────────────────────────────────────────────┐
                │              .dat (raw CSI file)                │
                └───────────────────────┬────────────────────────┘
                                        │  read_bf_file / get_scaled_csi
                                        ▼
                ┌────────────────────────────────────────────────┐
                │        RoughHandling: parse & visualize CSI    │
                └───────────────────────┬────────────────────────┘
                                        ▼
                ┌────────────────────────────────────────────────┐
                │   HumanDetection: presence detection (DBSCAN)  │
                └──────────────┬───────────────────┬─────────────┘
                               │                   │
                    (person present)         (motion detected)
                               ▼                   ▼
        ┌───────────────────────────┐   ┌───────────────────────────┐
        │ Static: AmplitudeProcess  │   │ Dynamic: DynamicProcess     │
        │        PhaseProcess       │   │ (amplitude-ratio & phase-  │
        │  → respiration rate       │   │  difference based)         │
        │  → heartbeat rate         │   │  → respiration / heartbeat │
        └───────────────────────────┘   └───────────────────────────┘
```

Processing chain for each branch (taking amplitude as an example):

```
raw CSI → Hampel filter (outlier removal) → Butterworth / wavelet denoising
       → segmentation → peak detection / power spectrum → respiration/heartbeat rate
```

---

## 📁 Repository Structure

| Folder | Description |
| --- | --- |
| `CSIProcess/` | **(Extended)** End-to-end CSI processing pipeline: read & parse `.dat` → build amplitude/phase matrix → Hampel outlier removal → low-pass filtering → DWT denoising |
| `RoughHandling/` | Initial processing: read CSI, convert to matrix, plot raw CSI waveforms |
| `HumanDetection/` | Detect whether a person is present using **DBSCAN clustering** on covariance-eigenvalue feature vectors (windowed CSI) |
| `AmplitudeProcess/` | Amplitude-based respiration extraction for **static** subjects |
| `PhaseProcess/` | Phase-based respiration extraction for **static** subjects |
| `DynamicProcess/` | Respiration & heartbeat extraction under **dynamic (moving)** conditions |
| `data/` | Collected CSI data samples (`.dat`) |
| `TestData/` | Test data, including ground-truth respiration curves collected by a **phone gyroscope** (`.csv`) |
| *(root)* | Original CSI Tool MATLAB toolbox (`read_bf_file.m`, `get_scaled_csi.m`, SNR/BER utilities, etc.) |

### File-by-file details

**`CSIProcess/`** (custom validation pipeline)

| File | Step |
| --- | --- |
| `ReandandParse.m` | Read `.dat` → parse into `result_matrix` (amplitude + phase + timestamp), with visualization |
| `YM1.m` | Same as above, adapted for the `volunteerD_1` public dataset (1×3×30 CSI shape) |
| `Hample.m` | Denoising step 1: Hampel filter for outlier removal (window 5, 2σ) |
| `DT.m` | Denoising step 2: Butterworth IIR low-pass (Fc=10 Hz, order 25, Fs=30 Hz) |
| `XB.m` | Denoising step 3: discrete wavelet transform (DWT) denoising (`sym4`, heursure) |

**`AmplitudeProcess/`** (static, amplitude branch)

| File | Step |
| --- | --- |
| `StaticAmplitudeProcess.m` | Full demo: amplitude-ratio extraction → Hampel → wavelet → power spectrum |
| `HampelFilter.m` | Hampel outlier removal on all 30 subcarriers |
| `ButterWorthFilter.m` | Butterworth band-pass design (0.3–0.6 Hz respiration band) + filtering |
| `WaveletRemoveNoise.m` | Two wavelet denoising variants (`sym3`/`sym7`) comparison |
| `Segment.m` | Variance-based activity segmentation (boundary detection) |
| `RespirationRate.m` | Peak detection → respiration rate calculation |

**`PhaseProcess/`** (static, phase branch)

| File | Step |
| --- | --- |
| `StaticPhaseProcess.m` | Full demo: phase extraction → Hampel → wavelet |
| `GetAmplitudeRatio.m` | Extract per-subcarrier amplitude ratio between two RX antennas |
| `AHampelFilter.m` / `PHampelFilter.m` | Hampel filtering for amplitude / phase |
| `AWaveletRemoveNoise.m` / `PWaveletRemoveNoise.m` | Wavelet denoising for amplitude / phase |
| `PButterWorthFilter.m` | Butterworth band-pass for phase (3–5 Hz heartbeat band) |
| `PRespirationRate.m` | Peak detection → respiration rate from phase signal |

**`DynamicProcess/`** (dynamic scenarios)

| File | Step |
| --- | --- |
| `GetAmplitudeRatioM.m` | Amplitude ratio extraction (dynamic data) |
| `PhaseDifference.m` | Sliding-window phase difference (0.5 s window) to suppress motion blur |
| `AHampelFilterM.m` / `PHampelFilterM.m` | Hampel filtering (amplitude / phase, dynamic) |
| `AWaveletRemoveNoiseM.m` / `PWaveletRemoveNoiseM.m` | Wavelet denoising (dynamic) |
| `PButterWorthFilterM.m` | Butterworth filtering (dynamic phase) |
| `GetRespirationRate.m` | **Function**: peak-detection-based respiration rate |
| `GetHeartRate.m` | **Function**: power-spectrum-based heartbeat rate (1–1.6 Hz band) |
| `analyse_power_spectrum.m` | **Function**: FFT-based power spectrum analysis |
| `PRespirationRateM.m` | Respiration rate from phase-difference signal |

**`HumanDetection/`**

| File | Step |
| --- | --- |
| `GeneralizeDataSample.m` | Windowed covariance eigenvalue features (person-present vs. empty room) |
| `DBSCAN_clustering.m` | DBSCAN clustering to separate occupied / empty environments |

---

## 📊 Data Description

- Raw CSI is collected with **Intel 5300 NIC** in monitor mode (see the main repo's [hardware docs](../docs/hardware_setup.md)).
- Typical packet interval: **0.05 s (≈20 Hz sampling)**.
- `TestData/*.csv` contains ground-truth respiration curves recorded by a **phone gyroscope** strapped to the subject's chest, used for accuracy comparison.
- File naming examples: `4_19_mn1.dat` (motion + noise), `4_19_sn1.dat` (static + noise), `4_19_sno1.dat` (static + no person).

---

## 🖥️ Getting Started

### Prerequisites

- MATLAB R2016b or newer (requires `findpeaks`, `wden`, `designfilt`, DBSCAN uses Statistics Toolbox `KDTreeSearcher`)

### Run

1. Clone the repository and open MATLAB at the **repository root** (all scripts use paths relative to the root).
2. Run any pipeline script, e.g.:

```matlab
% Full static-phase pipeline demo
run('PhaseProcess/StaticPhaseProcess.m')

% Custom end-to-end pipeline (parse → hampel → lowpass → wavelet)
run('CSIProcess/ReandandParse.m')
run('CSIProcess/Hample.m')
run('CSIProcess/DT.m')
run('CSIProcess/XB.m')
```

> Note: most scripts are **interactive code segments** rather than encapsulated functions — variables (e.g., `result_matrix`, `res_csi`) are shared across steps in the MATLAB workspace. Run them **in order** within one session.

---

## ⚙️ Key Parameters

| Parameter | Value | Meaning |
| --- | --- | --- |
| Packet interval | 0.05 s | CSI sampling period (≈20 Hz) |
| Subcarriers used | 30 (index 16 highlighted) | Intel 5300 provides 30 OFDM subcarriers; No.16 is often most sensitive |
| Hampel window / threshold | 3–5 / 2–3 (MAD σ) | Outlier removal strength |
| Butterworth (static amplitude) | 0.3–0.6 Hz band | Typical adult respiration band |
| Butterworth (static phase) | 3–5 Hz band | Heartbeat band |
| Heartbeat search band | 1–1.6 Hz | Used in `GetHeartRate.m` power-spectrum search |
| Wavelet | `sym3`/`sym4`/`sym7`/`sym9`, level 2–8 | DWT denoising basis |

---

## 🙏 Acknowledgements

- **WiFi_CSI_Respiration** (original concept-validation project): [JiamuLea/WiFi_CSI_Respiration](https://github.com/JiamuLea/WiFi_CSI_Respiration)
- **Linux 802.11n CSI Tool** (`.dat` parsing & scaling): Daniel Halperin, University of Washington — (c) 2008-2011, [linux-80211n-csitool-supplementary](https://github.com/dhalperi/linux-80211n-csitool-supplementary)

---

## ⚠️ Notes

- This codebase is for **academic research and concept validation only**; it is not a medical device.
- The `data/` and `TestData/` folders contain example data (~15 MB). Remove them from your fork if you do not need them.
- Scripts in this repository were debugged on Windows with pre-compiled `read_bfee.mexw64`; on other platforms, recompile `read_bfee.c` with MATLAB's `mex` utility.
- Welcome to open an Issue for questions or corrections.