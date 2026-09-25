%% HampelFilter.m —— 对全部 30 个子载波执行 Hampel 滤波并标记异常点
% 功能：读取 CSI 数据（data/4_14_1.dat 第 2001~5000 帧），将幅度转换为 dB，
%       对 30 个子载波逐行执行 Hampel 滤波，并绘制原始曲线与异常点位置。
%
% 说明：
%   - 幅度取 dB：db(abs(...))，压缩动态范围便于观察波动
%   - hampel(x, k, nsigma)：k 为窗口半径，nsigma 为 MAD 倍数阈值
%   - 返回值 j 记录被判为异常值的样本下标，图中以红色方块 'sr' 标出
%   - 本脚本中存在两套参数（k=3,σ=2 滤波 / k=4,σ=3 标定异常点），用于
%     对比不同窗口与阈值下的滤波效果
%%

%读取CSI数据，进行滤波处理，并绘制原始数据和滤波后峰值的图形
clc;clear all;warning('off');
csi_trace = read_bf_file('data/4_14_1.dat');

% 提取第 2001~5000 帧（共 3000 帧），转换为 dB 幅度
for i = 2001:5000
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);

    % squeeze(csi(1,1,:))：取发送天线1→接收天线1链路的 30 个子载波
    amplitude = db(abs(squeeze(csi(1,1,:)).'));
    raw_csi(:,i-2000) = amplitude;          % raw_csi：30×3000（子载波×时间）
end

% 对 30 个子载波逐一 Hampel 滤波
for i = 1:30
    % 第一组参数：窗口半径 3、阈值 2 倍 MAD（滤波）
    res_csi(i,:) = hampel(raw_csi(i,:),3,2);
    % 第二组参数：窗口半径 4、阈值 3 倍 MAD（仅用于标出异常点下标 j）
    [y,j(i,:),xmedian,xsigma] = hampel(raw_csi(i,:),4,3);
end

time = 0.01:0.01:30;   % 时间轴：每包 0.01s，共 3000 包

% 绘制原始曲线
plot(time,raw_csi);
hold on
% 在各子载波曲线上标记被 Hampel 判为异常的样本点（红色方块）
for i = 1:30
    plot(time(find(j(i,:))),raw_csi(i,j(i,:)),'sr');
    hold on
end
xlabel('时间/s');
ylabel('幅度(dB)');
