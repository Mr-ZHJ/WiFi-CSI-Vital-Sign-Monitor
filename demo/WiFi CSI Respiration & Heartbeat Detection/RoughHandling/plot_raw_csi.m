%% plot_raw_csi.m —— 原始 CSI 波形绘制（RoughHandling 初步处理）
% 功能：读取 CSI 原始 .dat 文件（TestData/4_19_mn1.dat），提取发送天线1→
%       接收天线1链路的幅度，绘制第 16 号子载波随时间的变化曲线。
%
% 用途：
%   - 快速检查采集数据质量（是否有丢包、异常跳变）
%   - 肉眼观察呼吸引起的周期性波动，为后续滤波参数选择提供依据
%
% 数据说明：包间隔 0.05s（约 20Hz），共读取前 1200 帧（60 秒）
%%

% 以 TestData 数据为例，数据包间隔为 0.05s,频率 20HZ
% 代码功能是读取一个名为"sample2.dat"的文件，该文件包含WiFi信道状态信息（CSI）的数据。
% 然后，它从数据中提取幅度信息，并将每个时间点的幅度数据存储在矩阵`raw_csi`中。
% 最后，它使用`plot`函数绘制`raw_csi`矩阵的第16行，表示幅度随时间的变化情况
clear all;
clc;
warning('off');

csi_trace = read_bf_file('TestData/4_19_mn1.dat');

% 提取前 1200 帧的幅度（发送天线1→接收天线1链路的 30 个子载波）
for i = 1:1200
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);    % 归一化信道矩阵（复数，1×3×30）
    csi_size = size(csi);

    % squeeze 后取该链路 30 个子载波的幅度
    amplitude = abs(squeeze(csi(1,1,:)).');

    raw_csi(:,i) = amplitude;           % raw_csi：30 子载波 × 1200 帧
end

% 绘制第 16 号子载波的幅度曲线（该子载波对呼吸最敏感）
plot(raw_csi(16,:)');
ylabel('幅度');
xlabel('时间（0.05s）');
title('静止状态原始CSI信号');
