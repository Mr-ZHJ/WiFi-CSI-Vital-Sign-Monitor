%% GetAmplitudeRatioM.m —— 动态场景幅度比提取
% 功能：遍历 csi_trace 第 11~1000 帧，计算第 16 号子载波在 RX1/RX2
%       两根接收天线上的幅度比，得到幅度比时间序列并绘图。
%       （动态场景版本：人体存在走动等运动时仍可提取呼吸分量）
%
% 原理：
%   幅度比 = abs(csi(1,1,:)) / abs(csi(1,2,:))
%   两通道幅度相除可抵消发射功率波动、AGC 增益等公共干扰；
%   相比单通道幅度，在动态干扰下鲁棒性更好。
%
% 输入：csi_trace（工作区中已由 read_bf_file 读入的 CSI cell 数组）
% 输出：raw_csi_amplitude（幅度比时间序列）
%%

for i = 11:1000
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);     % 归一化信道矩阵（复数）

    % RX1 / RX2 幅度比（逐子载波）
    amplitude = abs(csi(1,1,:))./abs(csi(1,2,:));

    % 保留第 16 号子载波的幅度比
    raw_csi_amplitude(:,i) = amplitude(16);
end

% 绘制幅度比时间序列
plot(raw_csi_amplitude)
