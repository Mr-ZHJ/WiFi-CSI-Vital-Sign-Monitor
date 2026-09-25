%% PRespirationRate.m —— 基于峰值检测的呼吸率计算（相位版）
% 功能：对滤波去噪后的相位呼吸波形执行峰值检测，计算相邻峰之间的
%       平均间隔，从而估计呼吸频率；滤除幅值过小的伪峰。
%
% 原理：
%   - findpeaks 找出波形局部极大值；
%   - 幅值低于 0.043 的峰视为噪声伪峰，直接跳过不计数；
%   - 相邻有效峰的时间差之和 / 有效峰数量 = 平均呼吸周期，
%     呼吸率 = 60 / 平均周期（次/分钟）。
%
% 输入：res_csi2（滤波后的相位序列）
% 输出：波形图 + 峰值标记（红色方块）
%%

% 输入信号选择（可切换为 res_csi_phase 等）
respiration = res_csi2;
% respiration = res_csi_phase;

% 绘制呼吸波形
plot(respiration'); hold on

% 峰值检测：pks 为峰值、locs 为峰位置
[pks,locs] = findpeaks(respiration);

[x1, x2] = size(pks);
count = 0; sum = 0;

% 累加相邻有效峰之间的距离，跳过低幅值伪峰（阈值 0.043）
for i = 2:x2
    if pks(1,i) < 0.043
        continue;
    end
    count = count + 1;
    sum = sum + locs(1,i) - locs(1,i-1);
end

% 可视化：波形 + 峰值标记
plot(locs,pks,'sr');
