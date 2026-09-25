%% PHampelFilter.m —— 对相位差序列执行 Hampel 滤波
% 功能：读取 CSI 数据（data/4_14_1.dat 第 1001~5000 帧），提取第 16 号
%       子载波在 RX1/RX2 上的相位差，执行 Hampel 滤波并标记异常点。
%
% 信号说明：
%   相位差 = angle( csi(1,1,16) - csi(1,2,16) )
%   两接收天线复数 CSI 作差取相位，可抵消公共相位偏移
%   （载波频偏、采样时偏），保留呼吸引起的路径差变化。
%
% 输入：data/4_14_1.dat
% 输出：res_csi（滤波后相位序列）、j（异常点下标）
%%

clc;clear all;warning('off');
csi_trace = read_bf_file('data/4_14_1.dat');

% 提取第 1001~5000 帧（共 4000 帧）的相位差
for i = 1001:5000
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);    % 归一化信道矩阵（复数）

    csi_size = size(csi);

    % 两接收天线复数 CSI 作差后取相位
    phase = angle(csi(1,1,16)-csi(1,2,16));

    raw_csi(:,i-1000) = phase;         % 相位差时间序列
end

time = [0.01:0.01:40];   % 时间轴：每包 0.01s，共 4000 包

% 第一组参数：窗口半径 3、阈值 2 倍 MAD（滤波结果）
res_csi(:) = hampel(raw_csi(:),3,2);
% 第二组参数：窗口半径 4、阈值 3 倍 MAD（标定异常点位置）
[y,j(:),xmedian,xsigma] = hampel(raw_csi(:),4,3);

% 绘制原始相位差曲线
plot(time,raw_csi);
hold on

% 标记异常点（红色方块）
plot(time(find(j)),raw_csi(1,j),'sr');
hold on

xlabel('时间/s');
ylabel('相位');
