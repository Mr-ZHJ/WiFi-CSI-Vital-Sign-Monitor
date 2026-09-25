%% GeneralizeDataSample.m —— 生成有人/无人场景的特征样本（人体检测第一步）
% 功能：分别读取"环境内有人"（4_19_mn1.dat）与"环境内无人"（4_19_sno1.dat）
%       两段 CSI 数据，将第 16 号子载波幅度序列按 100 帧（5s）分窗，
%       提取每个窗口协方差矩阵的前两大特征值作为二维特征向量，
%       生成两组特征样本散点图供后续 DBSCAN 聚类（见 DBSCAN_clustering.m）。
%
% 特征原理：
%   - 有人呼吸时，窗口内幅度序列存在规律波动 → 协方差特征值明显较大；
%   - 无人时仅剩环境噪声 → 特征值集中在接近 0 的区域；
%   - 因此协方差特征值可有效区分"有人 / 无人"两种场景。
%   - 绘图时对两个特征分别乘以 1e26 / 1e42 缩放，仅为了将两类样本
%     拉开到可视范围，不影响相对分布。
%
% 输出：DataSample（有人样本，N1×2）、DataSample2（无人样本，N2×2）
%%

clear all; clc;warning('off');
% 以 TestData 数据为例，数据包间隔为 0.05s（约 20Hz）
%% ---------- 环境内有人时的特征样本 ----------
csi_trace = read_bf_file('TestData/4_19_mn1.dat');

% 提取前 1200 帧的第 16 号子载波幅度序列
for i = 1:1200
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);
    csi_size = size(csi);

    amplitude = abs(squeeze(csi(1,1,:)).');

    raw_csi(i) = amplitude(16);
end
window_size = 100;   % 分窗长度：100 帧 = 5 秒

% 滑窗提取协方差特征（步长 = 窗长，无重叠）
for j = 1:100:1101

    for i = 1:100
       tmp(i,:) = raw_csi(j:j+99);      % 取第 j 窗的 100 个样本
    end

    C = cov(tmp);         % 窗内协方差矩阵
    e = eig(C);           % 特征值分解
    sort_e = sort(e);     % 升序排列
    DataSample(floor(j/100)+1,1) = sort_e(100);   % 最大特征值 → 特征 X
    DataSample(floor(j/100)+1,2) = sort_e(99);    % 次大特征值 → 特征 Y
end

%% ---------- 环境内无人时的特征样本 ----------
csi_trace2 = read_bf_file('TestData/4_19_sno1.dat');

raw_csi = [];res_csi = [];

% 提取前 800 帧的第 16 号子载波幅度序列
for i = 1:800
    csi_entry = csi_trace2{i};
    csi = get_scaled_csi(csi_entry);
    csi_size = size(csi);

    amplitude = abs(squeeze(csi(1,1,:)).');

    raw_csi(i) = amplitude(16);
end

% 可选预处理（取消注释可对比滤波对特征分布的影响）
% raw_csi(:) = hampel(raw_csi(:),3,2);
% res_csi = smooth(raw_csi(:));
% res_csi(:) = wden(raw_csi(:),'sqtwolog','h','one',6,'sym2');

% 滑窗提取协方差特征（步长 = 窗长，无重叠）
for j = 1:100:701

    for i = 1:100
       tmp(i,:) = raw_csi(j:j+99);
    end

    C2 = cov(tmp);
    e2 = eig(C2);
    sort_e2 = sort(e2);
    DataSample2(floor(j/100)+1,1) = sort_e2(100);   % 最大特征值
    DataSample2(floor(j/100)+1,2) = sort_e2(99);    % 次大特征值
end

%% ---------- 特征样本散点图 ----------
% 缩放系数 1e26 / 1e42 仅为可视化拉开距离，不影响聚类
plot(DataSample(:,1).*1e26,DataSample(:,2).*1e42,'*');   % 有人样本（蓝色*）
hold on;
plot(DataSample2(:,1).*1e26,DataSample2(:,2).*1e42,'r*'); % 无人样本（红色*）
xlabel('Feature-X');
ylabel('Feature-Y');
