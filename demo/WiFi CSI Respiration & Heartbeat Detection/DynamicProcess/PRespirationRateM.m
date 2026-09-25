%% PRespirationRateM.m —— 动态场景相位差信号呼吸率计算
% 功能：对滑动窗口相位差分信号（res_phasedifference，由 PhaseDifference.m
%       生成）执行峰值检测，滤除低幅值伪峰后计算呼吸周期。
%
% 原理：
%   - 相位差分可抑制运动基线漂移，保留呼吸变化率；
%   - findpeaks 找局部极大值，幅值 < 0.043 的峰视为噪声伪峰跳过；
%   - 相邻有效峰间隔均值 = 平均呼吸周期，呼吸率 = 60 / 周期。
%
% 输入：res_phasedifference（相位差分序列）
% 输出：波形图 + 峰值标记（红色方块）
%%

% 输入信号选择
respiration = res_phasedifference;

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
