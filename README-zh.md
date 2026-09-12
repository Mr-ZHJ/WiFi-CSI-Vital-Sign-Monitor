# 🛰️ WiFi-CSI-Vital-Sign-Monitor

> 基于 WiFi 信道状态信息（CSI）的非接触睡眠生命体征监测与人体姿态识别
> 研究生一年级 WiFi 感知方向研究笔记 + Demo 代码

本仓库整理了我研究生一年级在 WiFi 感知方向的研究笔记与 Demo 代码，主要聚焦**非接触生命体征监测**（呼吸、心跳）与**人体姿态识别**。全部内容来自实际学习与实验过程，希望能为同领域研究者提供有价值的参考。

- 🔗 仓库主页：https://github.com/Mr-ZHJ/WiFi-CSI-Vital-Sign-Monitor
- 📄 英文/双语版见 [README.md](README.md)
- 📁 详细文档位于 [docs/](docs/) 目录

---

## 目录

1. [项目简介](#项目简介)
2. [核心功能](#核心功能)
3. [应用场景](#应用场景)
4. [硬件平台](#硬件平台)
5. [算法流水线](#算法流水线)
6. [WiFi 感知入门背景](#wifi-感知入门背景)
7. [使用注意事项](#使用注意事项)
8. [仓库结构](#仓库结构)

---

## 项目简介

本项目基于 **WiFi CSI（Channel State Information，信道状态信息）** 实现对人体生命体征的非接触感知。

WiFi 信号在室内传播时，会经过墙壁、家具、人体等多径反射，形成丰富的多径信息。人体呼吸、心跳等微小的体表运动会对 CSI 的**幅度**与**相位**产生规律性调制，通过分析这些调制，即可在**无需佩戴任何设备**的条件下估计呼吸频率、心跳频率，并识别人体活动与睡眠姿态。

仓库按“**硬件搭建 → 数据采集 → 预处理 → 算法建模 → 生命体征提取**”的完整链路组织研究笔记与 Demo 代码，可作为 WiFi 感知方向入门与复现的参考资料。

---

## 核心功能

| 功能模块 | 说明 |
| --- | --- |
| 🫁 呼吸监测 | 非接触呼吸频率估计与呼吸状态分类 |
| ❤️ 心跳监测 | 非接触心跳频率估计与心跳状态分类 |
| 😴 睡眠姿态识别 | 仰卧、右侧卧、俯卧、左侧卧等睡眠姿态识别 |
| 🔄 睡眠周转活动识别 | 睡眠过程中翻身等周转活动的识别 |
| 🏃 人体活动识别 | 卧床、摔倒、步行、拾取、跑步、坐下、站立等常见活动分类 |
| 📊 数据可视化 | CSI 数据解析、幅值曲线、滤波前后对比、PCA-STFT 可视化 |

> 注：睡眠监测相关任务属于实验设计内容，仓库仅提供研究笔记与 Demo 代码，不包含数据与模型权重文件。

---

## 应用场景

本项目适用于**相对静止姿态**下的非接触感知，典型场景包括：

- **居家环境**：睡眠监测（呼吸、心跳、睡眠姿态、睡眠阶段）及其他场景
- **办公环境**：会议室、办公室、走廊过道内的人体活动感知
- **车内识别**：车内人员的呼吸、心跳监测与活动识别
- **公共场所**：人员活动状态的无线感知

相比视觉方案，WiFi 感知**不依赖光线、不侵犯隐私**；相比可穿戴设备，**无需佩戴、对老年人与体弱者更友好**。

---

## 硬件平台

### 采集平台

- **网卡**：Intel 5300 NIC（Network Interface Card，Intel Wi-Fi Link 5300 无线网卡）
- **工具链**：[Linux 802.11n CSI Tool](https://github.com/dhalperi/linux-80211n-csitool-supplementary)（基于 iwlwifi 与 Linux-2.6 的 CSI 提取工具）
- **模式选择**：
  - Monitor 模式：可稳定采样，支持收发分离，为推荐模式
  - AP 模式：采样频率受限、采样不稳定，不建议使用
- **典型收发组合**：
  - 2 台装有 Intel 5300 网卡的台式机
  - 1 台台式机 + 1 台笔记本
  - 2 台 miniPC（体积小巧，方便携带）
  - 自制一体机（集成 2 张网卡，单机完成收发）
- **天线**：全向天线为主，可分散布置（如将多个接收天线放置于身体不同位置）或紧凑放置
- **参数参考**：信道 64（HT20 带宽）、采样频率约 20 Hz，收发距离约 1.6 m

### 真值标定设备

- **MAX30102 脉搏血氧传感器**（MH-ET LIVE MAX30102 套件）＋ Arduino 1.8.18，通过 PBA（Peripheral Beat Amplitude）算法输出参考心率
- **指压式血氧仪 / 呼吸带传感器**：作为心跳与呼吸频率的参考真值
- **节拍器**：用于控制呼吸频率实验节奏并校验估计结果

---

## 算法流水线

```
CSI 采集 → dat 解析 → 信号源选择 → 子载波筛选 → 子载波融合
        → 降噪与异常值剔除 → 活动分割 → 滑动窗口特征 → 模型训练 → 生命体征提取
```

1. **CSI 采集**：Intel 5300 NIC 在 Monitor 模式下提取 CSI（30 个 OFDM 子载波 × 收发天线对）
2. **数据解析**：`.dat` 原始文件经 `read_bf_file` / `get_scale_csi` 解析为复数 CSI 矩阵
3. **信号源选择**：幅度 / 相位 / CSI 商 / 多普勒频移处理
4. **子载波筛选**：基于 **SNR（Signal-to-Noise Ratio，信噪比）** 衡量周期性；基于**方差（Variance）** 与 **MAD（Mean Absolute Deviation，平均绝对偏差）** 衡量敏感性
5. **子载波融合**：**MRC-PCA（最大比合并，Maximum Ratio Combining）**、**PCA-VMD（主成分分析-变分模态分解）** 等融合方法；也可选取统计特征靠前的子载波进行加权平均 / 取平均
6. **降噪与异常值剔除**：
   - **Hampel 滤波器**：窗口大小 10，MAD 阈值 3，用于剔除异常值
   - **Savitzky-Golay（SG）滤波器**：平滑信号
   - **Butterworth 低通滤波器**：去除高频噪声（实验脚本：5 阶，截止频率 8 Hz，采样 20 Hz）
7. **活动探测与分割**：基于阈值、基于变点检测、基于深度学习（CNN）等方法
8. **模型训练**：滑动窗口构造样本 → **SM-TCNNET**（空间特征提取模块 + 时序卷积网络）与 **LSTM** 基线 → K 折交叉验证（K=4）
9. **生命体征提取**：从 CSI 时频特征中估计呼吸 / 心跳频率

详细说明见 [docs/algorithm_pipeline.md](docs/algorithm_pipeline.md)。

---

## WiFi 感知入门背景

### 为什么选择 WiFi？

- **视觉方案**：依赖视距（LOS）、易受光照影响、隐私侵害严重
- **可穿戴方案**：需要佩戴设备（智能手表/手环等），对老年人或身体不便者不友好，且成本较高
- **雷达方案**：空间分辨率较低，难以捕捉细粒度动作，成本偏高

WiFi 信号**无处不在、非接触、低功耗、低成本**，是普适感知的理想载体。

### 为什么用 CSI？

传统 **RSS（Received Signal Strength，接收信号强度）** 只能提供单个粗粒度强度值，丢失了多径信息。而 **CSI** 提供每个 **OFDM（Orthogonal Frequency Division Multiplexing，正交频分复用）** 子载波上的幅度与相位响应，粒度更细、对微小扰动更敏感，适合呼吸、心跳等微动感知。

### 入门资源

- [Awesome-WiFi-CSI-Sensing（论文/资源合集）](https://github.com/NTUMARS/Awesome-WiFi-CSI-Sensing)
- [Awesome-WiFi-CSI-Research](https://github.com/wuzhiguocarter/Awesome-WiFi-CSI-Research)
- [清华大学《物联网前沿实践》17.2 CSI 分析实例](https://iot-book.github.io/zh/17_WiFi感知/S2_CSI分析实例/)
- 张大庆：《6G 时代，Wi-Fi 不再是 Wi-Fi》[中国计算机学会](https://www.ccf.org.cn/Focus/2022-11-27/779805.shtml)
- B 站 UP 主：WiFi-CSI 爱好者

---

## 使用注意事项

- 📦 **本仓库不包含数据集**：仅提供研究笔记与 Demo 代码，所有数据需自行采集（可参考 [docs/hardware_setup.md](docs/hardware_setup.md) 的采集流程）
- 🎓 **仅用于学术研究参考**：内容为研究生一年级学习期间的研究记录，不构成商业产品
- 🐛 **环境兼容性**：Demo 代码基于 TensorFlow 1.8 / Python 3.6 编写，新环境可能需要适配
- 💬 **欢迎交流**：如有问题或建议，欢迎提交 [Issue](https://github.com/Mr-ZHJ/WiFi-CSI-Vital-Sign-Monitor/issues)

---

## 仓库结构

```
WiFi-CSI-Vital-Sign-Monitor/
├── README.md                 # 项目主文档（中英双语）
├── README-zh.md              # 中文版文档
├── docs/
│   ├── project_overview.md   # 项目概述（研究背景、目标、意义）
│   ├── hardware_setup.md     # 硬件搭建与数据采集
│   └── algorithm_pipeline.md # 算法流水线详解
├── notes/                    # 研究笔记（WiFi 感知入门、活动识别方法调研等）
└── demo/                     # Demo 代码（CSI 解析、预处理、模型训练）
```

> 注：以上目录结构为推荐组织方式，实际文件分布以仓库为准。

---

## 交流与贡献

- 欢迎通过 [GitHub Issues](https://github.com/Mr-ZHJ/WiFi-CSI-Vital-Sign-Monitor/issues) 提出建议、指出错误或交流 WiFi 感知相关技术。
- 如果您觉得本仓库有帮助，欢迎 Star ⭐ 支持。