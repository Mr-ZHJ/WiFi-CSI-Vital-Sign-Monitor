%% Segment.m —— 基于累积方差的呼吸信号活动段分割
% 功能：读取 CSI 数据，对第 16 号子载波幅度序列计算累积方差，
%       依据方差跳变检测"有人呼吸 / 无活动（环境噪声）"的边界点，
%       并在方差曲线上标出各段边界。
%
% 原理：
%   - 呼吸会引起幅度规律波动，有人时累积方差明显大于无人时段；
%   - 逐点计算 varvalue(j) = var(x(1:j))，当区间 [i,j] 内方差极差
%     （max-min）超过阈值时，认定 j 为一个活动段边界，并从 j 重新起算；
%   - 阈值按 j 所处区间分段设置（1~400 / 400~600 / >600），补偿
%     累积方差随样本数增长而增大的趋势。
%
% 输入：TestData/4_19_mn2.dat
% 输出：bounds（N×2 边界矩阵，第 1/2 列为段起点/终点下标）
%%

%读取CSI数据，计算方差，并根据一些条件判断在图形上标记出方差超过阈值的子序列的边界位置
clear all;
clc;
warning('off');
csi_trace = read_bf_file('TestData/4_19_mn2.dat');

% 提取第 1~1200 帧的幅度（发送天线1→接收天线1链路）
for i = 1:1200
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);
    csi_size = size(csi);

    amplitude = abs(squeeze(csi(1,1,:)).');

    raw_csi(:,i) = amplitude;     % raw_csi：30 子载波 × 1200 帧
end

%% ---------- 累积方差计算 ----------
bounds = [];     % 边界矩阵：每行为 [段起点, 段终点]
count = 0;       % 已检测到的边界数量
i = 1;           % 当前段的起点下标

% 逐点计算累积方差 varvalue(j) = var(raw_csi(16, 1:j))
for j = 1:1200
    varvalue(j) = var(raw_csi(16,1:j));
end

newvarvalue = [];

%% ---------- 分段阈值检测边界 ----------
% 阈值随样本数分三段递减，以抵消累积方差随 j 增大的自然增长趋势
for j = 1:1200
    % 区间一：j < 400，方差极差阈值 1.5
    if j < 400
        if max(varvalue(i:j)) - min(varvalue(i:j)) > 1.5
            count = count + 1;
            bounds(count,1) = i;     % 记录段起点
            bounds(count,2) = j;     % 记录段终点（边界）
            i = j;                   % 从边界处重新起算下一段
        end
    end

    % 区间二：400 <= j < 600，阈值 0.5
    if j > 400 && j <600
        if max(varvalue(i:j)) - min(varvalue(i:j)) > 0.5
            count = count + 1;
            bounds(count,1) = i;
            bounds(count,2) = j;
            i = j;
        end
    end

    % 区间三：j > 600，阈值 0.3
    if j > 600
        if max(varvalue(i:j)) - min(varvalue(i:j)) > 0.3
            count = count + 1;
            bounds(count,1) = i;
            bounds(count,2) = j;
            i = j;
        end
    end

end

%% ---------- 可视化 ----------
% 绘制累积方差曲线
plot(varvalue);ylim=get(gca,'Ylim');hold on;

% 在每个边界点处画竖线，标出活动段分界
for i = 1:count
    plot([bounds(i,2),bounds(i,2)],ylim);hold on;
end
