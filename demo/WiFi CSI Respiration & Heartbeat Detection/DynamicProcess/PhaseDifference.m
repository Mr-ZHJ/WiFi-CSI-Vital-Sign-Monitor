%% PhaseDifference.m —— 滑动窗口相位差分（动态场景运动抑制）
% 功能：对滤波后的相位序列 res_csi2 做固定间隔差分，抑制人体运动
%       引起的低频大幅漂移，突出呼吸等周期性微动分量。
%
% 原理：
%   - 人体走动等大动作会使相位产生缓慢、大幅的基线漂移；
%   - 呼吸为周期 ~2-5s 的稳定小幅波动；
%   - 以 0.5s（10 个采样点）为间隔做差分 res_csi2(i+10) - res_csi2(i)，
%     可削弱慢变基线漂移，保留呼吸变化率信息。
%
% 输入：res_csi2（滤波后的相位序列）
% 输出：phase_difference（差分后的相位序列）
%%

window_length = 0.5;              % 滑动差分的时间间隔为 0.5s
window_size = window_length / 0.05; % 对应采样点数：0.5s / 0.05s = 10 个点

phase_difference = [];

% 逐点计算固定间隔差分（i 从 1 到 990，保证 i+10 不越界）
for i = 1:990
    phase_difference(i) = res_csi2(i + 10) - res_csi2(i);
end

% 绘制相位差分序列
plot(phase_difference)
