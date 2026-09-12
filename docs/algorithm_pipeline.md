# 算法流水线详解

> 本文档分步解析从 **CSI（Channel State Information，信道状态信息）采集**到**生命体征提取**的完整算法流程，整理用到的滤波器、模型与评价指标。内容基于本仓库实际代码与实验记录整理，未涉及的数据/结论不予补充。

---

## 0. 流水线总览

```
① CSI 采集
② 数据解析（.dat → CSI 矩阵）
③ 信号源选择（幅度 / 相位 / CSI 商 / 多普勒）
④ 子载波筛选（SNR / 方差 / MAD）与融合（MRC-PCA / PCA-VMD）
⑤ 异常值剔除与降噪（Hampel / Savitzky-Golay / Butterworth）
⑥ 活动探测与分割（阈值 / 变点检测 / CNN）
⑦ 滑动窗口特征构造
⑧ 模型训练（SM-TCNNET / LSTM，K 折交叉验证）
⑨ 生命体征提取（呼吸 / 心跳估计与分类）
```

---

## 1. CSI 采集

- 平台：Intel 5300 NIC + Linux 802.11n CSI Tool（Monitor 模式）
- 输出：每个数据包一个 CSI 帧，包含时间戳（`timestamp_low`）、收发天线数（Nrx / Ntx）、RSSI、噪声（noise）、AGC 以及 **30 个 OFDM 子载波**的复数信道响应
- 典型采样频率：约 20 Hz；原始数据以 `.dat` 二进制文件保存

参考代码：`wifilib.py`（读取 .dat）、11.py（解析示例）。

---

## 2. 数据解析

### 2.1 二进制帧读取（`read_bf_file`）

`read_bf_file(filename)` 读取 `.dat` 文件：

1. 按“字段长度 + 字段内容”的结构循环读取 CSI 帧；
2. 仅保留 `code == 187` 的 CSI 记录（跳过其他信息）；
3. 解析出时间戳、bfee_count、Nrx / Ntx、三路 RSSI、noise、AGC、antenna_sel、perm 天线映射等元数据；
4. 用 `parse_csi` 从 payload 解出复数 CSI 矩阵。

### 2.2 CSI 复数矩阵（`parse_csi` / `get_scale_csi`）

- 输出形状：**(Ntx, Nrx, 30)**，即（发送天线，接收天线，子载波）；
- `get_scale_csi` 基于 RSSI 与噪声（热噪声 + 量化误差）计算缩放因子，把原始 CSI 归一化到功率尺度；
- Demo 校验：`11.py` 中示例数据形状为 **(2, 3, 30)**（2 发 3 收 30 子载波），并剔除形状不符的异常帧。

### 2.3 信号源选择

CSI 包含丰富的信号源，可针对任务选取：

| 信号源 | 说明 |
| --- | --- |
| 幅度（Amplitude） | 各子载波幅值，对体表微动敏感，本仓库主要使用 |
| 相位（Phase） | 各子载波相位，需先做相位校准 |
| CSI 商（CSI Ratio） | 取双天线/子载波间的比值，可抑制部分噪声 |
| 多普勒频移处理 | 面向运动感知的频域特征 |

---

## 3. 子载波筛选与融合

### 3.1 子载波选择依据

对 30 个子载波（或各天线对）进行筛选，保留对目标任务敏感的子载波：

- **周期性**：基于信噪比（**SNR，Signal-to-Noise Ratio**）衡量子载波周期是否明显（呼吸/心跳具有周期分量）；
- **敏感性**：基于方差（Variance）、**MAD（Mean Absolute Deviation，平均绝对偏差）** 衡量子载波对人体活动的敏感性。

### 3.2 子载波选择后的融合

| 方法 | 说明 |
| --- | --- |
| 基于最大比组合（**MRC-PCA**） | 结合最大比合并与主成分分析（PCA）融合多子载波 |
| 主成分分析-变分模态分解（**PCA-VMD**） | PCA 降维后使用变分模态分解（VMD）分离呼吸/心跳等模态分量 |
| 统计特征筛选 | 选取统计特征靠前的子载波，再做加权平均或取平均 |

> 说明：MRC-PCA 与 PCA-VMD 属于研究中的方案设计；本仓库记录其思路与实现框架，具体参数请以实验记录为准。

---

## 4. 异常值剔除与降噪

### 4.1 Hampel 滤波器（异常值剔除）

- **窗口大小**：10（示例配置）；
- **判定阈值**：**MAD（Median Absolute Deviation，中位绝对偏差）阈值 3**；
- 作用：对滑动窗口内的数据做鲁棒性统计，将偏离中值超过 `k × MAD` 的样本视为异常值并替换，从而抑制脉冲噪声与个别跳变。

### 4.2 Savitzky-Golay（SG）滤波器

- 全称：Savitzky-Golay 滤波器（多项式最小二乘平滑滤波）；
- 作用：在保持信号形状（峰/谷）的前提下平滑信号，适合后续峰值检测。

### 4.3 Butterworth 低通滤波器

- **阶数**：5 阶；
- **截止频率**：8 Hz；
- **采样率**：20 Hz（Nyquist 频率 10 Hz）；
- 实现：`scipy.signal.butter(order, cutoff/nyq, btype='low')` + `filtfilt(..., method='gust')`（零相位滤波，避免相位失真）；
- 作用：去除高频噪声，保留呼吸（约 0.1~0.5 Hz）与心跳（约 1~2 Hz）所在低频带，其**线性相位响应**保证了信号时间信息不丢失。

参考代码（`11.py` 片段）：

```python
fs = 20          # 采样率
cutoff = 8       # 截止频率
order = 5        # 阶数
nyq = 0.5 * fs
normal_cutoff = cutoff / nyq
b, a = signal.butter(order, normal_cutoff, btype='low', analog=False)
filtered_csi_amp = signal.filtfilt(b, a, csi_amp, method="gust")
```

---

## 5. 活动探测与分割

将连续 CSI 流切分为“有活动 / 无活动”片段，供后续建模使用，可选方法：

| 方法 | 说明 |
| --- | --- |
| 基于阈值的活动分割 | 根据幅值/能量阈值判断活动起止 |
| 基于变点检测的活动分割 | 检测统计特征突变点作为活动边界 |
| 基于 CNN 的活动分割 | 用深度学习模型（如 DeepSeg 思路）学习分割边界 |

---

## 6. 滑动窗口特征构造

### 6.1 窗口参数（Demo 代码 `cross_vali_data_convert_merge.py`）

| 参数 | 值 | 说明 |
| --- | --- | --- |
| window_size | 250（生成 500/250 两个版本） | 每个样本的时间步长度 |
| slide_size | 100 | 相邻窗口的滑动步长 |
| threshold | 60 | 窗口标签投票阈值（%） |
| 特征维度 | 90 | 幅度特征：30 子载波 × 3 接收天线 |

### 6.2 输入数据格式

公开活动数据集（`input_*.csv` / `annotation_*.csv`）中：

- 第 1 列：时间戳；
- 第 2 ~ 91 列：（30 子载波 × 3 天线）幅度；
- 第 92 ~ 181 列：（30 子载波 × 3 天线）相位；
- 注释文件为每帧对应的活动标签（bed、fall、walk、pickup、run、sitdown、standup 等）。

Demo 预处理仅使用**幅度特征**（取 2~91 列），并按滑动窗口组织为 `(样本, 时间步, 90)` 的张量。

### 6.3 标签构造

- 标签共 **8 类**（one-hot）：No Activity、Bed（卧床）、Fall（摔倒）、Walk（步行）、Pickup（拾取）、Run（跑步）、Sit Down（坐下）、Stand Up（站立）；
- 窗口标签按**多数投票**：窗口内占比 > threshold（60%）的类别作为该窗口标签；
- 训练时将 “No Activity” 列剔除，最终分类数为 **7 类**。

### 6.4 内存优化

为控制内存开销，代码对样本行做**隔行抽取（每 2 行取 1 行）**，将窗口内时间步由 250 压缩为 **125**，作为 TCN 的 `n_steps`。

---

## 7. 模型训练

### 7.1 网络结构：SM-TCNNET（空间模块 + TCN）

Demo 主程序（`cross_vali_recurrent_network_wifi_activity.py`）由两部分组成：

**① 空间特征提取模块（spatial_module）**

对输入序列执行多组：

```
1D Conv（kernel=3, padding=same, ReLU）→ BatchNormalization → MaxPooling1D(2) → Dropout
```

提取空间特征，突出关键子载波/通道信息。

**② TCN（Temporal Convolutional Network，时序卷积网络）模块**

- 前置 1D 卷积层；
- 多个**残差模块（residual block）**，每个模块：
  - 1D 卷积（kernel=3，**空洞卷积 dilation_rate = 2^(i-1)** 指数扩张）→ Dropout → 1×1 卷积；
  - 与输入经 1×1 卷积投影后**残差相加（shortcut）**；
- 最后接 GlobalAveragePooling1D 与全连接输出层。

### 7.2 超参数（Demo）

| 参数 | 值 |
| --- | --- |
| n_input | 90（30 子载波 × 3 天线） |
| n_steps（window_size） | 125 |
| n_hidden | 200 |
| n_classes | 7 |
| learning_rate | 0.0001 |
| training_iters | 200 |
| batch_size | 30 |
| dropout_rate | 0.2 |
| K 折交叉验证 | 4 折 |
| 优化器 | Adam |
| 损失 | Softmax 交叉熵 |

### 7.3 基线模型：LSTM

- 参考：Yousefi et al.（2017，IEEE Communication Magazine）基于 LSTM 的 WiFi 行为识别；
- 本仓库同时保留了 LSTM 训练输出（`output_lstm.txt`）作为对照。

### 7.4 训练与评估流程

1. 按类别导入并打乱数据（相同随机种子）；
2. 对每个类别做 **K 折滚动**，逐折分离训练集/验证集；
3. 使用 Mini-batch（batch=30）迭代训练，记录损失与准确率曲线；
4. 每折绘制**混淆矩阵**，累计所有折的混淆矩阵；
5. 计算并保存 Accuracy（准确率）、Precision（精确率）、Recall（召回率）、F1-score 与学习曲线图。

---

## 8. 生命体征提取

在完成活动分割/剔除无效段后，对静止段信号提取呼吸与心跳：

| 任务 | 实现思路 |
| --- | --- |
| 呼吸频率估计 | 子载波融合后的低频分量 → 滤波 → 频谱峰值/峰值检测（结合 PCA-VMD 分离呼吸分量） |
| 心跳频率估计 | 在更高频带（约 0.8~2 Hz）估计心跳周期 |
| 呼吸 / 心跳分类 | 将估计结果与真值（MAX30102、呼吸带、节拍器）比较，做正常/异常分类 |

> 说明：本仓库记录上述研究思路与相关参考实现（如 WiFi_CSI_Respiration、WiFi-CSI-MiningTool），实际模块代码与具体参数请以仓库 Demo 与实验记录为准。

---

## 9. 评价指标

| 指标 | 全称 | 含义 |
| --- | --- | --- |
| Accuracy | 准确率 | 正确分类样本占比，(TP+TN)/(TP+TN+FP+FN) |
| Precision | 精确率 | TP/(TP+FP)，被预测为正类的样本中真实为正类的比例 |
| Recall | 召回率 | TP/(TP+FN)，真实正类中被正确预测的比例 |
| F1-score | F1 值 | Precision 与 Recall 的调和平均 |
| Confusion Matrix | 混淆矩阵 | 各真实类别 × 各预测类别的分类统计 |

---

## 10. 结果参考

> 以下数据来自仓库内论文汇报 PPT（基于自建数据集的 SM-TCNNET 四折交叉验证）与 Demo 训练输出，仅供参考与复现对照。

### 10.1 自建数据集

| Metrics | Fold 1 | Fold 2 | Fold 3 | Fold 4 | Average |
| --- | --- | --- | --- | --- | --- |
| Accuracy (%) | 100.00 | 99.82 | 99.89 | 100.00 | 99.93 |
| Precision (%) | 100.00 | 99.84 | 99.85 | 100.00 | 99.93 |
| Recall (%) | 100.00 | 99.82 | 99.81 | 100.00 | 99.91 |
| F1-score (%) | 100.00 | 99.82 | 99.83 | 100.00 | 99.91 |

### 10.2 公共数据集对比

| Study | Method（Year） | Accuracy (%) | Precision (%) | Recall (%) | F1 (%) |
| --- | --- | --- | --- | --- | --- |
| Yousefi et al. [34] | LSTM（2017） | 90.05 | — | — | — |
| Chen et al. [35] | ABLSTM（2018） | 97.30 | — | — | — |
| Yadav et al. [36] | CSITime（2022） | 98.00 | 99.16 | 98.87 | 99.01 |
| Salehinejad et al. [37] | LiteHAR（2022） | 93.00 | — | — | — |
| Proposed | SM-TCNNET | 99.80 | 99.81 | 99.80 | 99.80 |

### 10.3 Demo 训练日志

```
acc= 99.495, pre= 99.514, re= 99.495, f1= 99.495
acc= 98.990, pre= 99.055, re= 98.990, f1= 98.987
acc= 99.495, pre= 99.512, re= 99.495, f1= 99.495
acc= 100.000, pre= 100.000, re= 100.000, f1= 100.000
```

---

## 11. 环境依赖

- Python 3.6 + TensorFlow 1.8（Demo 以 `tensorflow18` conda 环境运行）
- numpy、pandas、matplotlib、scikit-learn、scipy

---

## 12. 免责与说明

- 本仓库**不包含数据集**，仅提供研究笔记与 Demo 代码，数据需自行采集（采集方法见 [hardware_setup.md](hardware_setup.md)）；
- 全部内容**仅用于学术研究参考**，不构成医疗产品与结论；
- 欢迎 Issue 交流。