function [ respirationrate ] = GetRespirationRate(x,ts,interval)
%GETRESPIRATIONRATE 从信号中利用峰值检测方法计算呼吸周期
%   输入：
%       x        —— 待测信号（行向量，滤波去噪后的呼吸波形）
%       ts       —— 采样周期（秒/采样点）
%       interval —— 邻域半径（秒），用于过滤邻域内非最大值的伪峰
%   输出：
%       respirationrate —— 平均呼吸周期（秒/次）
%                           呼吸率(bpm) = 60 / respirationrate
%
% 算法流程：
%   1. findpeaks 检测全部局部极大值；
%   2. 在每个峰的 ±interval/ts 邻域内若存在更大的值，
%      则该峰被判定为伪峰并剔除（置 0 / NaN）；
%   3. 统计剩余有效峰之间的平均间隔 × ts，得到平均呼吸周期。
%
% 示例：
%   rr = GetRespirationRate(res_csi_amplitude, 0.05, 0.5);
%   fprintf('呼吸率 = %.1f bpm\n', 60/rr);

%% 第一步：峰值检测
[pks,locs] = findpeaks(x);
count = size(pks,2);

%% 第二步：伪峰剔除（邻域比较法）
% 对每个峰，检查其 ±interval/ts 采样点邻域内是否存在更大的值
for i = 1 : size(pks,2)
    for j = max(1,locs(i)-interval/ts) : min(size(x,2),locs(i)+interval/ts)
        if x(j) > pks(i)
            pks(i) = 0;         % 标记为伪峰
            locs(i) = NaN;
            count = count - 1;
            break;
        end
    end
end

% 可视化：信号波形 + 峰值标记（红方块）
plot(x'); hold on
plot(locs,pks,'sr');xlabel('时间/0.05s');ylabel('幅度');

%% 第三步：计算有效峰之间的平均间隔
% 跳过开头的 NaN 峰，找到第一个有效峰
sum = 0;
for i = 2:size(pks,2)
    if isnan(locs(i))
        continue;
    end
    break;
end

% 从第一个有效峰开始累加相邻有效峰的距离
% 遇到 NaN（伪峰）时用上一个峰位置替代，避免中断累加
for j = i+1:size(pks,2)
    if isnan(locs(j))
        locs(j) = locs(j-1);
        continue;
    end
    sum = sum + locs(j) - locs(j-1);
end

% 平均呼吸周期 = 总间隔 / 有效峰数量 × 采样周期
respirationrate = sum / count * ts;
end
