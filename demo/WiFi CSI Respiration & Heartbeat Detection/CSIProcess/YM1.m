%% YM1.m —— 读取 volunteerD_1 公共活动数据集并解析 CSI（流程第一步·数据集版）
% 功能：与 ReandandParse.m 相同，但适配 volunteerD_1 数据集的 CSI 形状（1 发 3 收 × 30 子载波），
%       输出矩阵为 181 列布局。
%
% 输出矩阵 result_matrix 的列布局（共 181 列）：
%   第 1~90 列   ：幅度（30 子载波 × 3 接收天线，展平）
%   第 91~180 列 ：相位（弧度）
%   第 181 列    ：时间戳 timestamp_low
%
% 注意：
%   1. 下方数据路径为本地外部数据集（volunteerD_1），请根据自己电脑上的存放位置修改
%   2. csi_trace 中可能出现空帧（设备丢包），需先剔除
%
% 依赖：read_bf_file.m、get_scaled_csi.m（Linux 802.11n CSI Tool）
%
close all
clear
clc

%% ---------- 第一步：读取原始 .dat 文件 ----------
str = 'data/volunteerD_1/csi_a1_1.dat';   % volunteerD_1 数据集文件，请按实际路径修改
csi_trace = read_bf_file(str);

% 剔除空帧，防止设备传输过程丢包导致解析出错
csi_trace(all(cellfun(@isempty,csi_trace),2),:) = [];

row = size(csi_trace,1);              % 有效 CSI 帧总数
result_matrix = zeros(row,181);       % 预分配结果矩阵

Fs = 1000;                            % 采样频率（Hz），按实际采集参数修改

%% ---------- 第二步：逐帧计算幅度与相位，存入 result_matrix ----------
for i = 1:row
    % 读取第 i 帧 CSI（结构体形式）
    csi_entry = csi_trace{i};

    % 保存该帧的时间戳到矩阵最后一列
    result_matrix(i,181) = csi_trace{i}.timestamp_low;

    % get_scaled_csi 将原始 CSI 归一化为信道矩阵 H（复数矩阵，1×3×30）
    csi = get_scaled_csi(csi_entry);
    csi1 = squeeze(csi);               % 去掉 singleton 维度，得到 3×30 复数矩阵

    % 提取当前时刻的信号数据包
    current_packet = csi1;

    % 幅度 = |CSI|；相位 = angle(CSI)（弧度制）
    amplitude = abs(current_packet);
    phase = angle(current_packet);

    % 展平后按行存入结果矩阵
    result_matrix(i, 1:90) = reshape(amplitude, 1, []);    % 幅度占 1~90 列
    result_matrix(i, 91:180) = reshape(phase, 1, []);      % 相位占 91~180 列
end

%% ---------- 第三步：可视化 ----------
% 图 1：幅度随时间的变化
figure(1);
plot(result_matrix(:, 1:90));
xlabel('时间');
ylabel('幅度');
title('幅度随时间的变化');
grid on;

% 图 2：相位随时间的变化
figure(2);
plot(result_matrix(:, 91:180));
xlabel('时间');
ylabel('相位 (弧度)');
title('相位随时间的变化');
grid on;

% 图 3：相位解卷绕前后对比（unwrap 消除 ±π 跳变）
phase_wrapped = result_matrix(:, 91:180);    % 原始（缠绕）相位
phase_unwrapped = unwrap(phase_wrapped);     % 解卷绕后的连续相位
figure(3);
subplot(2, 1, 1);
plot(phase_wrapped);
title('Wrapped Phase');
subplot(2, 1, 2);
plot(phase_unwrapped);
title('Unwrapped Phase');
