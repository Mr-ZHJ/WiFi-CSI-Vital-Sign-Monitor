%% GetAmplitudeRatio.m —— 提取两接收天线间的幅度比序列
% 功能：遍历 csi_trace 第 1001~5000 帧，计算第 16 号子载波在
%       RX1/RX2 两根接收天线上的幅度比，得到幅度比时间序列并绘图。
%
% 原理：
%   幅度比 = abs(csi(1,1,:)) / abs(csi(1,2,:))
%   两通道幅度相除可抵消发射功率波动、AGC 增益变化等公共干扰，
%   突出人体呼吸引起的差异化扰动。
%
% 输入：csi_trace（工作区中已由 read_bf_file 读入的 CSI cell 数组）
% 输出：raw_csi_amplitude（幅度比时间序列，4000×1）
%%

for i = 1001:5000
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);    % 归一化信道矩阵（复数）

    % RX1 / RX2 幅度比（逐子载波）
    amplitude = abs(csi(1,1,:))./abs(csi(1,2,:));

    % 保留第 16 号子载波的幅度比（实验中对呼吸最敏感）
    raw_csi_amplitude(:,i-1000) = amplitude(16);
end

% 绘制幅度比时间序列
plot(raw_csi_amplitude)
