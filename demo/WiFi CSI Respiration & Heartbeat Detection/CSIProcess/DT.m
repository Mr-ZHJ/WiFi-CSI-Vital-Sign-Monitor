%% DT.m —— 降噪第二步：低通滤波器处理
% 功能：设计 Butterworth IIR 低通滤波器，对 result_matrix 中 90 个子载波
%       通道的幅度数据逐一滤波，去除高频噪声。
%
% 输入：result_matrix（建议先经过 Hample.m 异常值剔除）
% 输出：更新后的 result_matrix（第 1~90 列为低通滤波后的幅度）
%
% 设计说明：
%   - 截止频率 Fc = 10 Hz：保留呼吸（0.1~0.5 Hz）与心跳（1~2 Hz）所在低频带，
%     滤除高频环境噪声；要求 Fc 必须小于奈奎斯特频率（Fs/2 = 15 Hz）
%   - 滤波器阶数 order = 25：阶数越高滚降越陡，但相位延迟与数值稳定性变差
%   - filtfilt 为零相位滤波（前向+后向），不会引入相位失真
%
% 可调参数：Fc（截止频率）、order（阶数）、Fs（采样频率）
%
% 注意：请在同一 MATLAB 会话中先运行 ReandandParse.m → Hample.m 后再运行本脚本。
%%

% 取出幅度数据（90 列：30 子载波 × 3 接收天线）
amplitude_data = result_matrix(:, 1:90);

%% ---------- 可视化：原始数据 ----------
figure;
subplot(2, 1, 1);                       % 2×1 子图布局，选中第 1 个子图
plot(amplitude_data);
xlabel('时间');
ylabel('幅度');
title('幅度随时间的变化（原始）');
hold on

%% ---------- 设计低通滤波器 ----------
Fc = 10;       % 截止频率（Hz），根据实际情况调整，但必须小于 Fs/2 = 15 Hz
order = 25;    % 滤波器阶数，可根据需要调整
Fs = 30;      % 采样频率（Hz），按实际采集参数设置

% designfilt：设计 Butterworth IIR 低通滤波器
lowpass_filter = designfilt('lowpassiir', ...
    'FilterOrder', order, ...
    'HalfPowerFrequency', Fc, ...
    'SampleRate', Fs, ...
    'DesignMethod', 'butter');

%% ---------- 逐子载波滤波 ----------
filtered_data = zeros(size(amplitude_data));
for i = 1:90
    % filtfilt：零相位数字滤波（前向+后向滤波，消除相位延迟）
    filtered_data(:, i) = filtfilt(lowpass_filter, amplitude_data(:, i));
end

% 滤波结果写回 result_matrix
result_matrix(:, 1:90) = filtered_data;

%% ---------- 可视化：滤波后数据 ----------
subplot(2, 1, 2);                       % 选中第 2 个子图
plot(result_matrix(:, 1:90));
xlabel('时间');
ylabel('幅度');
title('幅度随时间的变化（lowpass）');
hold off
