# 🛰️ WiFi-CSI-Vital-Sign-Monitor

> Non-contact vital sign monitoring and human activity recognition based on WiFi Channel State Information (CSI).

Research notes and demo codes from my first year of postgraduate study in **WiFi sensing**, mainly focusing on **non-contact vital sign monitoring** (respiration & heartbeat) and **human posture/activity recognition**. I hope these resources can provide valuable references for other researchers in this field.

[中文文档](README-zh.md) | [Detailed docs →](docs/)

---

## 📑 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Application Scenarios](#-application-scenarios)
- [Hardware Platform](#-hardware-platform)
- [Algorithm Pipeline](#-algorithm-pipeline)
- [Key Results](#-key-results)
- [WiFi Sensing 101](#-wifi-sensing-101)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Usage Notes](#-usage-notes)

---

## ✨ About

This project leverages **CSI (Channel State Information)** extracted from commercial WiFi signals to sense human vital signs **without any wearable device**.

WiFi signals propagate through indoor environments along multiple paths (reflections from walls, furniture, and the human body). Subtle body-surface movements caused by **respiration** and **heartbeats** modulate the amplitude and phase of CSI in a periodic way. By analyzing these modulations, we can:

- Estimate **respiration rate** and **heartbeat rate**
- Recognize **human activities** and **sleep postures**

The repository is organized along the complete pipeline: **hardware setup → data collection → preprocessing → algorithm modeling → vital sign extraction**, and serves as a reference for researchers entering the WiFi sensing field.

> 📌 This is a **research notes + demo code** repository, **not** a complete product or dataset release.

---

## 🚀 Features

| Module | Description |
| --- | --- |
| 🫁 Respiration Monitoring | Non-contact respiration rate estimation and respiration status classification |
| ❤️ Heartbeat Monitoring | Non-contact heartbeat rate estimation and heartbeat status classification |
| 😴 Sleep Posture Recognition | Recognition of postures such as supine, right-side lying, prone, left-side lying |
| 🔄 Sleep Turnover Detection | Detection of turnover activities during sleep (e.g., S→R, S→L) |
| 🏃 Human Activity Recognition | Classification of common activities: bed, fall, walk, pickup, run, sit down, stand up |
| 📊 Data Visualization | CSI parsing, amplitude curves, pre/post-filtering comparison, PCA-STFT visualization |

> Note: Sleep monitoring tasks are experimental designs; this repository only provides research notes and demo codes, with no data or model weights included.

---

## 🏠 Application Scenarios

Designed for **relatively static postures**, typical scenarios include:

- **Home / elderly care**: sleep monitoring (respiration, heartbeat, sleep posture, sleep stages)
- **Office**: activity sensing in meeting rooms, offices, and corridors
- **In-vehicle**: respiration/heartbeat monitoring and activity recognition
- **Public places**: contactless sensing of human activity states

Compared to vision-based approaches, WiFi sensing is **light-independent and privacy-friendly**; compared to wearables, it requires **no devices attached to the body**, making it more friendly for the elderly and people with limited mobility.

---

## 🛠️ Hardware Platform

### Acquisition Platform

| Item | Description |
| --- | --- |
| NIC | **Intel 5300 NIC** (Network Interface Card, Intel Wi-Fi Link 5300) |
| Toolchain | [Linux 802.11n CSI Tool](https://github.com/dhalperi/linux-80211n-csitool-supplementary) (based on iwlwifi & Linux-2.6) |
| Mode | **Monitor mode** (stable sampling, TX/RX separation) — recommended; AP mode is unstable and not recommended |
| TX/RX setups | 2 desktops with Intel 5300 NICs / desktop + laptop / 2 miniPCs / custom all-in-one with 2 NICs |
| Antennas | Omnidirectional antennas (default); can be distributed or compact |
| Reference params | Channel 64 (HT20), sampling rate ~20 Hz, TX-RX distance ≈1.6 m |

### Ground-Truth Devices

- **MAX30102 pulse oximeter** (MH-ET LIVE MAX30102) + Arduino 1.8.18, using the PBA (Peripheral Beat Amplitude) algorithm to output reference heart rate
- **Fingertip pulse oximeter / respiration belt** for heartbeat and respiration reference
- **Metronome** for controlled respiration experiments

---

## 🔬 Algorithm Pipeline

```
CSI acquisition → .dat parsing → signal-source selection → subcarrier selection
→ fusion → denoising & outlier removal → activity segmentation
→ sliding-window features → model training → vital sign extraction
```

1. **CSI acquisition**: Intel 5300 NIC extracts CSI (30 OFDM subcarriers × TX/RX antenna chains) in monitor mode
2. **Data parsing**: `.dat` files → `read_bf_file` / `get_scale_csi` → complex CSI matrix
3. **Signal source selection**: amplitude / phase / CSI ratio / Doppler processing
4. **Subcarrier filtering**: SNR (Signal-to-Noise Ratio) for periodicity; Variance and MAD (Mean Absolute Deviation) for sensitivity
5. **Fusion**: Maximum-Ratio Combining (MRC-PCA), PCA-VMD (Principal Component Analysis–Variational Mode Decomposition), or weighted/mean averaging of selected subcarriers
6. **Denoising & outlier removal**: Hampel filter (window 10, MAD threshold 3), Savitzky-Golay (SG) filter, Butterworth low-pass (5th order, 8 Hz cutoff @ 20 Hz sampling)
7. **Activity segmentation**: threshold-based / change-point detection / deep learning (CNN-based)
8. **Modeling**: sliding-window samples → **SM-TCNNET** (Spatial Module + Temporal Convolutional Network) & **LSTM** baselines → 4-fold cross-validation
9. **Vital sign extraction**: estimate respiration/heartbeat rate from CSI time-frequency features

**More details → [docs/algorithm_pipeline.md](docs/algorithm_pipeline.md)**

---

## 🎯 Key Results

> Results reported in the paper-based presentation materials (4-fold cross-validation on self-collected dataset with SM-TCNNET).

| Metric | Fold 1 | Fold 2 | Fold 3 | Fold 4 | Average |
| --- | --- | --- | --- | --- | --- |
| Accuracy (%) | 100.00 | 99.82 | 99.89 | 100.00 | 99.93 |
| Precision (%) | 100.00 | 99.84 | 99.85 | 100.00 | 99.93 |
| Recall (%) | 100.00 | 99.82 | 99.81 | 100.00 | 99.91 |
| F1-score (%) | 100.00 | 99.82 | 99.83 | 100.00 | 99.91 |

> ⚠️ Please note: these are **research-stage** results from internal experiments; they should not be treated as claims for any medical or commercial product.

---

## 📚 WiFi Sensing 101

### Why WiFi?

- **Vision-based**: requires LOS, affected by lighting, privacy-invasive
- **Wearable**: requires wearing smartwatches/bands, unfriendly to the elderly/disabled, costly
- **Radar**: low spatial resolution, cannot capture fine-grained motions, costly

WiFi is **everywhere, contactless, low-power, and low-cost** — an ideal source for ubiquitous sensing.

### Why CSI instead of RSS?

RSS (Received Signal Strength) gives only a single coarse-grained strength value, losing multipath information. CSI provides per-subcarrier amplitude & phase responses at **OFDM (Orthogonal Frequency Division Multiplexing)** subcarriers — much finer granularity and more sensitive to tiny perturbations, which is key for breathing/heartbeat sensing.

### Quick Resources

- [Awesome-WiFi-CSI-Sensing](https://github.com/NTUMARS/Awesome-WiFi-CSI-Sensing)
- [Awesome-WiFi-CSI-Research](https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research)
- [Tsinghua IoT: CSI Analysis Example (17.2)](https://iot-book.github.io/zh/17_WiFi感知/S2_CSI分析实例/)
- Zhang Daqing: *6G era, WiFi is no longer just WiFi* (CCF)

---

## 🖥️ Getting Started

### Prerequisites

- Python 3.6
- TensorFlow 1.8 (see `tensorflow18` environment folder)
- numpy, pandas, matplotlib, scikit-learn, scipy

### Quick Start

```bash
# 1. Parse .dat CSI file
python wifilib.py           # see demo/11.py for example

# 2. Preprocess (sliding window, downsampling)
python cross_vali_data_convert_merge.py

# 3. Train SM-TCNNET model
python cross_vali_recurrent_network_wifi_activity.py
```

> ℹ️ The demo code was written for a **TensorFlow 1.8 / Python 3.6** environment (see `tensorflow18` env). Newer environments may require code adaptation.

---

## 📁 Project Structure

```
WiFi-CSI-Vital-Sign-Monitor/
├── README.md                    # Main document (English)
├── README-zh.md                # Chinese version
├── docs/
│   ├── project_overview.md     # Overview (research background, goals, significance)
│   ├── hardware_setup.md        # Hardware setup & data collection
│   └── algorithm_pipeline.md    # Algorithm pipeline
├── notes/                       # Research notes (intro, activity recognition, etc.)
└── demo/                        # Demo codes (CSI parsing, preprocessing, model training)
```

> Note: This is a recommended organization; actual files may differ.

---

## ⚠️ Usage Notes

- 📦 **No dataset included**: this repository only provides research notes and demo code. All data must be collected by yourself — see [docs/hardware_setup.md](docs/hardware_setup.md) for the collection guide.
- 🎓 **For academic research only**: contents are records from my first-year study; not a medical device or commercial product.
- 🐛 **Environment compatibility**: demo code was written for TensorFlow 1.8 / Python 3.6.
- 💬 **Feedback welcome**: please open an [Issue](https://github.com/Mr-ZHJ/WiFi-CSI-Vital-Sign-Monitor/issues) for questions or suggestions.

---

## 🙋 Contributing & License

- Contributions, bug reports and feature requests are welcome via [GitHub Issues](https://github.com/Mr-ZHJ/WiFi-CSI-Vital-Sign-Monitor/issues).
- No license is currently applied to this repository; it is provided for **academic research reference only**.
- If you find this repo helpful, a ⭐ Star is much appreciated!