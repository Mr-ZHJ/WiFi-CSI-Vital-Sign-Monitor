# 硬件搭建与数据采集

> 本文档介绍基于 **Intel 5300 NIC** 与 **Linux 802.11n CSI Tool** 的 WiFi CSI 采集环境搭建、天线布局、真值标定设备与数据采集要点，供复现实验参考。

---

## 1. 设备清单

### 1.1 采集平台

| 设备 | 说明 |
| --- | --- |
| Intel 5300 NIC（Network Interface Card，Intel Wi-Fi Link 5300 无线网卡）× 2 | 接收端（必需）；发送端（收发分离模式必需） |
| Linux 主机 × 2（或 1 台主机 + 1 台笔记本 / 2 台 miniPC） | 运行采集工具链；miniPC 体积小巧，便于携带 |
| 可选：自制一体机 | 集成 2 张 Intel 5300 网卡，一台完成收发 |
| 家用路由器（TP-LINK 等） | 可作发送端的简化方案（配合 CSI Tool 注入发包） |
| 天线（全向天线） | 每张网卡 1 根天线（Intel 5300 支持 3 天线），推荐全向天线 |
| 网线、USB 转串口线等 | 连接与调试 |

### 1.2 软件环境

- 操作系统：Ubuntu（接收端实验记录使用 **Ubuntu 14.04**）
- CSI 提取工具：[linux-80211n-csitool](https://github.com/dhalperi/linux-80211n-csitool) 与 [linux-80211n-csitool-supplementary](https://github.com/dhalperi/linux-80211n-csitool-supplementary)
- 固件：`iwlwifi-5000-2.ucode.sigcomm2010`（SigComm 2010 版 5000 系列固件）
- 依赖：libnl-dev、libssl-dev、libpcap-dev、iw、build-essential、ncurses-dev 等

### 1.3 真值标定设备

| 设备 | 用途 |
| --- | --- |
| MAX30102 脉搏血氧传感器（MH-ET LIVE MAX30102 套件） | 心率真值（PBA 算法） |
| Arduino 开发板 + Arduino IDE 1.8.18 | 读取并记录 MAX30102 数据 |
| 指压式血氧仪 | 心率/血氧参考真值 |
| 呼吸带传感器 | 呼吸频率参考真值 |
| 节拍器 | 控制呼吸频率（实验对照） |

---

## 2. 采集模式选择

| 模式 | 说明 | 结论 |
| --- | --- | --- |
| AP 模式 | 将网卡配置为接入点，采集 CSI | 采样频率受限、采样不稳定，不推荐 |
| **Monitor 模式** | 将网卡配置为监听模式，收发分离 | **推荐**，可稳定采样，支持两机或多机协同 |

Monitor 模式常见收发组合：

- 2 台装有 Intel 5300 网卡的台式机（一收一发）
- 1 台台式机 + 1 台笔记本
- 2 台 miniPC
- 自制一体机（集成 2 张网卡）

---

## 3. 天线布局与部署

### 3.1 天线选择

- 推荐**全向天线**；若需要增强定向覆盖可选用定向天线。

### 3.2 布置方式

| 方式 | 说明 | 适用场景 |
| --- | --- | --- |
| 紧凑布置 | 收发天线距离较近 | 常规实验 |
| **分散布置** | 接收天线分布于被测身体的不同位置 | 睡眠监测（推荐） |

睡眠监测场景参考布置：

- **3 根接收天线**：分别放置在**肩膀、腰部、脚边**；
- **2 根接收天线**：**对角布置**在床的两侧。

### 3.3 距离与位置要点

- 实验记录中收发距离约 **1.6 m**，座椅高度约 **45 cm**（以坐姿实验为例）；
- 天线尽量正对被测者，避免大幅遮挡；
- 固定天线使用**三角支架 + 泡沫/塑料**垫，避免晃动带来的额外噪声。

---

## 4. 真值标定设备说明

### 4.1 MAX30102 心率真值（PBA 算法）

- 硬件：MH-ET LIVE MAX30102 套件 + Arduino 1.8.18（包含 `Example5_HeartRate` 示例工程）
- 原理：MAX30102 采集指端光电容积（PPG）信号，通过 **PBA（Peripheral Beat Amplitude）算法**实时计算 BPM（每分钟心跳次数，beats per minute）
- 接线（参考 Example5_HeartRate）：
  - VIN → 5V（或 3.3V）
  - GND → GND
  - SDA → A4（I2C 数据线）
  - SCL → A5（I2C 时钟线）
  - INT → 不接
- 使用方法：将手指按压在传感器上保持稳定压力，串口（115200）输出 IR / BPM / Avg BPM

### 4.2 呼吸真值

- **节拍器**：控制被测者按指定节奏呼吸，用于验证呼吸频率估计的准确性；
- **呼吸带传感器**：记录呼吸波形与频率，作为参考真值。

### 4.3 其他器材

- 指压式血氧仪（心率对照）
- WiFi 信号延迟线（3 条 × 3 m，用于信号通路延展与硬件测试）
- 床 / 床垫（睡眠监测实验）
- 可选：2.5G / 5G 小吸盘天线（3 个，用于扩展频段与布局）

---

## 5. 部署步骤（Linux 环境）

> 以下命令来自实际调试记录（`执行代码.txt` / `接收发送.txt`），完整复现请以官方 [linux-80211n-csitool](https://dhalperi.github.io/linux-80211n-csitool/) 文档为准。

### 5.1 环境准备

```bash
sudo apt-get update
sudo apt-get -y install git-core kernel-package fakeroot build-essential ncurses-dev
sudo apt-get -y install libnl-dev libssl-dev
sudo apt-get -y install iw
sudo apt-get install libpcap-dev
```

### 5.2 编译安装 CSI 内核补丁

```bash
cd ~
tar -xvf intel-5300-csi-github-master.tar.gz
cd intel-5300-csi-github-master
make oldconfig          # 一路回车
make menuconfig         # 在弹出的窗口选择 Save 再 Exit（务必 save 一次）
make -j4                # 编译内核（约 0.5~1 小时）
sudo make install modules_install
sudo make install
sudo make install modules_install   # 再次安装（保险）
sudo mkinitramfs -o /boot/initrd.img-`cat include/config/kernel.release` `cat include/config/kernel.release`
make headers_install
sudo mkdir /usr/src/linux-headers-`cat include/config/kernel.release`
sudo cp -rf usr/include /usr/src/linux-headers-`cat include/config/kernel.release`/include
```

修改 GRUB 启动项并更新：

```bash
cd /etc/default
sudo vi grub        # 修改 GRUB_HIDDEN_TIMEOUT=0
sudo update-grub
```

### 5.3 安装 CSI 工具与固件

```bash
cd ~
git clone https://github.com/dhalperi/linux-80211n-csitool-supplementary.git

# 备份原有固件并启用 SigComm2010 固件
for file in /lib/firmware/iwlwifi-5000-*.ucode; do sudo mv $file $file.orig; done
sudo cp linux-80211n-csitool-supplementary/firmware/iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/
sudo ln -s iwlwifi-5000-2.ucode.sigcomm2010 /lib/firmware/iwlwifi-5000-2.ucode

# 安装发包工具（lorcon-old）
git clone https://github.com/dhalperi/lorcon-old.git
cd lorcon-old
./configure
make
sudo make install
```

### 5.4 发送端（发包注入）

```bash
cd ~/linux-80211n-csitool-supplementary/injection/
make
iwconfig
sudo bash ./inject.sh wlan0 64 HT20
echo 0x1c113 | sudo tee `sudo find /sys -name monitor_tx_rate`
sudo ./random_packets 1000000000 100 1 1000
```

其中 `random_packets` 参数可根据采样频率调整（如 20 Hz 采样使用 `6000 100 1 50000`）。

### 5.5 接收端（抓取 CSI）

```bash
cd ~/linux-80211n-csitool-supplementary/netlink/
make
sudo bash ./monitor.sh wlan0 64 HT20
sudo ./log_to_file temp   # 建议文件名后缀改为 .dat
```

`splix` 的 `monitor.sh` 会完成：卸载并重载 `iwlwifi`（`connector_log=0x1`）、停止网络管理器、设置 monitor 模式、指定信道（默认 64 HT20）。

---

## 6. 数据采集要点

### 6.1 参数参考

| 参数 | 参考值（实验记录） |
| --- | --- |
| 信道 / 带宽 | 64 / HT20 |
| 采样频率 | 约 20 Hz |
| 收发距离 | 约 1.6 m |
| 发包参数 | `random_packets 6000 100 1 50000`（20 Hz 场景） |

### 6.2 数据文件

- 原始数据保存为 `.dat` 文件（例如 `20231114csi.dat`、`xue01.dat`、`20243901seat.dat` 等），内部为 CSI 二进制帧（含时间戳、RSSI、AGC、CSI 矩阵等）。
- 后续处理使用 `read_bf_file` / `get_scale_csi` 解析（见 [algorithm_pipeline.md](algorithm_pipeline.md)）。

### 6.3 采集记录示例（2024.03.09）

- 采集时间：2024.03.09 16:30
- 环境设置：接收发送间隔 1.6 m；座位高度 45 cm
- 采集姿态：坐、躺、站
- 采样频率：20 Hz
- 参数：`sudo ./random_packets 6000 100 1 50000`
- 备注：实验直接于接收端操作时，数据收尾包存在一定波动（参考 `volunteerD_1/introduction.txt`）

---

## 7. 常见问题与提示

1. **固件问题**：若 `iwlwifi` 无法加载，确认固件替换与软链已正确配置（见 5.3）。
2. **信道一致性**：发送端与接收端信道、带宽必须一致（64 / HT20）。
3. **数据波动**：接收端直连操作时，收尾数据包会存在波动，建议预留过渡段并后处理切除。
4. **权限**：采集命令均需 `sudo` 执行。
5. **数据保存**：建议将 `log_to_file` 输出文件统一命名为 `.dat` 后缀，便于后续解析脚本识别。

---

## 8. 声明

- 本仓库**不包含数据集**，本文档仅用于指导自行搭建与采集；
- 相关工具均为开源项目（linux-80211n-csitool 等），使用请遵循其许可证；
- 仅用于学术研究参考，欢迎 Issue 交流。