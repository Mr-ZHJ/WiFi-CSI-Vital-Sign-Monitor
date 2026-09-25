%% StaticAmplitudeProcess.m —— 静止状态幅度处理完整流程（Demo）
% 功能：演示静止状态下基于 CSI 幅度比（Amplitude Ratio）的呼吸检测全流程：
%       幅度比提取 → Hampel 滤波 → 小波去噪 → 功率谱分析（估计呼吸频率）
%
% 信号选择说明：
%   幅度比 = abs(csi(1,1,:)) / abs(csi(1,2,:))
%   即同一发送天线到两根接收天线（RX1/RX2）的幅度之比，可抑制两个通道
%   共有的噪声（如 AGC 增益波动），比单通道幅度对呼吸更敏感。
%   此处选取第 16 号子载波（实验中该子载波对呼吸最敏感）。
%
% 数据说明：TestData/4_19_mn1.dat（包间隔 0.05s，约 20Hz）
% 依赖：read_bf_file.m、get_scaled_csi.m、analyse_power_spectrum.m（DynamicProcess 目录）
%%

%% ---------- 第一步：读取 csi_trace 并提取幅度比 ----------
clc; clear all; warning('off');
csi_trace = read_bf_file('TestData/4_19_mn1.dat');   % 读取原始 CSI 数据

% 逐帧提取第 16 号子载波在 RX1/RX2 上的幅度比
for i = 1:1200
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);                 % 归一化信道矩阵（复数）

    % 幅度比：RX1 幅度 / RX2 幅度（逐子载波）
    amplitude = abs(csi(1,1,:))./abs(csi(1,2,:));

    % 只保留第 16 号子载波的幅度比序列
    raw_csi_amplitude(:,i) = amplitude(16);
end

% 查看原始幅度比波形
figure(1);
plot(raw_csi_amplitude);

%% ---------- 第二步：对幅度比进行 Hampel 滤波（异常值剔除） ----------
% hampel(x, k, nsigma)：k=3 为窗口半径，nsigma=2 为 MAD 倍数阈值
res_csi_amplitude(:) = hampel(raw_csi_amplitude(:),3,2);
% 第二组参数（k=4, nsigma=3）用于标定异常点位置 j（供可视化用）
[y,j(:),xmedian,xsigma] = hampel(raw_csi_amplitude(:),4,3);

time = 0.05:0.05:60;   % 时间轴：每包 0.05s，共 1200 包
figure(2);
plot(time,raw_csi_amplitude);
hold on

%% ---------- 第三步：对幅度比做小波变换去噪 ----------
% wden：'sqtwolog'（通用阈值）、's'（软阈值）、'one'（第一层噪声估计）、5 层 sym7 小波
res_csi_amplitude(:) = wden(res_csi_amplitude(:),'sqtwolog','s','one',5,'sym7');
% 备选方案：'db4' 小波基
% res_csi_amplitude(:) = wden(res_csi_amplitude(:),'sqtwolog','s','one',5,'db4');

figure(3);
plot(time,res_csi_amplitude(:));
xlabel('时间');
ylabel('幅度');

%% ---------- 第四步：功率谱分析（估计呼吸频率） ----------
% 对去噪后的幅度比信号做 FFT 功率谱，呼吸频率对应谱峰位置
[pows,freq] = analyse_power_spectrum(raw_csi_amplitude,20);   % Fs = 20 Hz
figure(5);
plot(freq,pows);
axis([0.75,1.75,-30,-23]);   % 关注 0.75~1.75 Hz 频段内的谱峰
xlabel('频率');
title('平均功率谱');

%% ----------（可选）与真值对比 ----------
% 读取手机陀螺仪采集的真值数据（mn1.csv 第 5 列），与 WiFi 感知结果叠加对比
% data = readmatrix('TestData/mn1.csv');
% GyroX = data(:, 5);            % 陀螺仪 X 轴数据（胸带随呼吸起伏）
% time2 = 5.88:0.08:80.6;        % 手机采样间隔约 0.08s
%
% figure(4);
% plot(time,(res_csi_amplitude));
% hold on;
% plot(time2,GyroX'*0.3+0.4);   % *0.3+0.4 仅作幅度缩放对齐显示）
% xlabel('时间(1s)');
% ylabel('幅度');
% legend('WiFi感知','真实数据');
