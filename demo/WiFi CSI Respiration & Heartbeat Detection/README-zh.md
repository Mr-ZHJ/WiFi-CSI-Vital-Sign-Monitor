# 🫁 WiFi CSI 呼吸与心跳检测 — 验证代码

> 基于 WiFi CSI（Channel State Information，信道状态信息）的非接触呼吸与心跳检测验证代码，覆盖静止与动态两种场景。

[English](README.md) | 中文

本仓库是一套基于 WiFi CSI 的**非接触生命体征检测概念验证代码库**，源自开源项目 [WiFi_CSI_Respiration](https://github.com/JiamuLea/WiFi_CSI_Respiration)，并在其基础上扩展了额外的 CSI 处理流程。全部代码使用 **MATLAB** 编写，依赖 [Linux 802.11n CSI Tool](https://github.com/dhalperi/linux-80211n-csitool-supplementary) 工具箱（作者 Daniel Halperin）完成 `.dat` 原始文件解析。

---

## 📑 目录

- [流程总览](#-流程总览)
- [仓库结构](#-仓库结构)
- [数据说明](#-数据说明)
- [快速开始](#-快速开始)
- [关键参数](#-关键参数)
- [致谢](#-致谢)
- [注意事项](#-注意事项)

---

## 🔬 流程总览

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

流程说明：读取 `.dat` 原始 CSI → 初步解析与可视化 → DBSCAN 人体存在检测 → 根据场景分流：

- **静止场景**：幅度处理（`AmplitudeProcess`）或相位处理（`PhaseProcess`）→ 提取呼吸率与心跳率
- **动态场景**：`DynamicProcess` 基于幅度比与相位差分提取呼吸、心跳

每条分支的处理链（以幅度为例）：

```
原始 CSI → Hampel 滤波（异常值剔除） → Butterworth / 小波去噪
        → 活动段分割 → 峰值检测 / 功率谱分析 → 呼吸率 / 心跳率
```

---

## 📁 仓库结构

| 目录 | 说明 |
| --- | --- |
| `CSIProcess/` | **（扩展）** 端到端 CSI 处理流程：读取解析 `.dat` → 构建幅度/相位矩阵 → Hampel 异常值剔除 → 低通滤波 → DWT 小波去噪 |
| `RoughHandling/` | 初步处理：读取 CSI、转换为矩阵、绘制原始 CSI 波形 |
| `HumanDetection/` | 基于窗口协方差特征向量使用 **DBSCAN 聚类**检测环境中是否有人 |
| `AmplitudeProcess/` | **静止**场景下基于幅度的呼吸提取 |
| `PhaseProcess/` | **静止**场景下基于相位的呼吸提取 |
| `DynamicProcess/` | **动态（运动）**场景下的呼吸与心跳提取 |
| `data/` | 采集的 CSI 数据样本（`.dat`） |
| `TestData/` | 测试数据，含**手机陀螺仪**采集的呼吸真值曲线（`.csv`） |
| *（根目录）* | CSI Tool 原始 MATLAB 工具箱（`read_bf_file.m`、`get_scaled_csi.m`、SNR/BER 工具函数等） |

### 逐文件说明

**`CSIProcess/`**（自定义验证流程）

| 文件 | 步骤 |
| --- | --- |
| `ReandandParse.m` | 读取 `.dat` → 解析为 `result_matrix`（幅度 + 相位 + 时间戳），并可视化 |
| `YM1.m` | 同上，适配 `volunteerD_1` 公共数据集（1×3×30 的 CSI 形状） |
| `Hample.m` | 降噪第一步：Hampel 滤波剔除异常值（窗口 5，2σ） |
| `DT.m` | 降噪第二步：Butterworth IIR 低通（截止 10 Hz，25 阶，Fs=30 Hz） |
| `XB.m` | 降噪第三步：离散小波变换（DWT）去噪（`sym4`，heursure 阈值） |

**`AmplitudeProcess/`**（静止场景，幅度分支）

| 文件 | 步骤 |
| --- | --- |
| `StaticAmplitudeProcess.m` | 完整 Demo：幅度比提取 → Hampel → 小波 → 功率谱 |
| `HampelFilter.m` | 对全部 30 个子载波执行 Hampel 异常值剔除 |
| `ButterWorthFilter.m` | Butterworth 带通设计（0.3–0.6 Hz 呼吸频段）+ 滤波 |
| `WaveletRemoveNoise.m` | 两种小波去噪方案对比（`sym3`/`sym7`） |
| `Segment.m` | 基于方差的活动段分割（边界检测） |
| `RespirationRate.m` | 峰值检测 → 呼吸率计算 |

**`PhaseProcess/`**（静止场景，相位分支）

| 文件 | 步骤 |
| --- | --- |
| `StaticPhaseProcess.m` | 完整 Demo：相位提取 → Hampel → 小波 |
| `GetAmplitudeRatio.m` | 提取两接收天线间逐子载波幅度比 |
| `AHampelFilter.m` / `PHampelFilter.m` | 幅度 / 相位的 Hampel 滤波 |
| `AWaveletRemoveNoise.m` / `PWaveletRemoveNoise.m` | 幅度 / 相位的小波去噪 |
| `PButterWorthFilter.m` | 相位 Butterworth 带通（3–5 Hz 心跳频段） |
| `PRespirationRate.m` | 相位信号峰值检测 → 呼吸率 |

**`DynamicProcess/`**（动态场景）

| 文件 | 步骤 |
| --- | --- |
| `GetAmplitudeRatioM.m` | 动态数据的幅度比提取 |
| `PhaseDifference.m` | 滑动窗口相位差分（0.5 s 窗口），抑制运动模糊 |
| `AHampelFilterM.m` / `PHampelFilterM.m` | 幅度 / 相位的 Hampel 滤波（动态） |
| `AWaveletRemoveNoiseM.m` / `PWaveletRemoveNoiseM.m` | 小波去噪（动态） |
| `PButterWorthFilterM.m` | Butterworth 滤波（动态相位） |
| `GetRespirationRate.m` | **函数**：基于峰值检测的呼吸率计算 |
| `GetHeartRate.m` | **函数**：基于功率谱的心跳率计算（搜索 1–1.6 Hz 频段） |
| `analyse_power_spectrum.m` | **函数**：基于 FFT 的功率谱分析 |
| `PRespirationRateM.m` | 由相位差分信号计算呼吸率 |

**`HumanDetection/`**

| 文件 | 步骤 |
| --- | --- |
| `GeneralizeDataSample.m` | 窗口协方差特征提取（有人 vs. 无人场景） |
| `DBSCAN_clustering.m` | DBSCAN 聚类，区分有人 / 无人环境 |

---

## 📊 数据说明

- 原始 CSI 由 **Intel 5300 NIC** 在 Monitor 模式下采集（采集方法见主仓库的[硬件搭建文档](../docs/hardware_setup.md)）。
- 典型包间隔：**0.05 s（约 20 Hz 采样）**。
- `TestData/*.csv` 为**手机陀螺仪**绑在被测者胸部采集的呼吸真值曲线，用于精度对比。
- 文件命名示例：`4_19_mn1.dat`（运动 + 有人）、`4_19_sn1.dat`（静止 + 有人）、`4_19_sno1.dat`（静止 + 无人）。

---

## 🖥️ 快速开始

### 环境要求

- MATLAB R2016b 及以上（需 `findpeaks`、`wden`、`designfilt`；DBSCAN 需 Statistics Toolbox 的 `KDTreeSearcher`）

### 运行

1. 克隆仓库，在**仓库根目录**打开 MATLAB（所有脚本均使用相对根目录的路径）。
2. 运行任一流程脚本，例如：

```matlab
% 静止场景相位处理完整 Demo
run('PhaseProcess/StaticPhaseProcess.m')

% 自定义端到端流程（解析 → hampel → 低通 → 小波）
run('CSIProcess/ReandandParse.m')
run('CSIProcess/Hample.m')
run('CSIProcess/DT.m')
run('CSIProcess/XB.m')
```

> 注意：大多数脚本是**交互式代码片段**而非封装函数——变量（如 `result_matrix`、`res_csi`）在各步骤间通过 MATLAB 工作区共享，请在**同一会话中按顺序**运行。

---

## ⚙️ 关键参数

| 参数 | 取值 | 含义 |
| --- | --- | --- |
| 包间隔 | 0.05 s | CSI 采样周期（约 20 Hz） |
| 子载波 | 30 个（重点关注第 16 号） | Intel 5300 提供 30 个 OFDM 子载波；第 16 号对呼吸最敏感 |
| Hampel 窗口 / 阈值 | 3–5 / 2–3（MAD 倍数） | 异常值剔除强度 |
| Butterworth（静止幅度） | 0.3–0.6 Hz 带通 | 成人典型呼吸频段 |
| Butterworth（静止相位） | 3–5 Hz 带通 | 心跳频段 |
| 心跳搜索频段 | 1–1.6 Hz | `GetHeartRate.m` 功率谱搜索范围 |
| 小波基 | `sym3`/`sym4`/`sym7`/`sym9`，2–8 层 | DWT 去噪基函数 |

---

## 🙏 致谢

- **WiFi_CSI_Respiration**（原概念验证项目）：[JiamuLea/WiFi_CSI_Respiration](https://github.com/JiamuLea/WiFi_CSI_Respiration)
- **Linux 802.11n CSI Tool**（`.dat` 解析与归一化）：Daniel Halperin，University of Washington — (c) 2008-2011，[linux-80211n-csitool-supplementary](https://github.com/dhalperi/linux-80211n-csitool-supplementary)

---

## ⚠️ 注意事项

- 本代码库**仅用于学术研究与概念验证**，不构成医疗设备。
- `data/` 与 `TestData/` 文件夹含示例数据（约 15 MB），如不需要可在你的分支中删除。
- 仓库脚本在 Windows 上使用预编译的 `read_bfee.mexw64` 调试；其他平台请用 MATLAB 的 `mex` 工具重新编译 `read_bfee.c`。
- 欢迎提交 Issue 交流问题或指正。