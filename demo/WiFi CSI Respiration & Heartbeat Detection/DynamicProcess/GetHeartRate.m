function [ heartrate ] = GetHeartRate( x,fs )
%GetHeartRate 从信号中计算心跳频率（功率谱分析 + 峰值检测 + 平均聚类）
%   输入：
%       x  —— 待测信号（行向量，滤波去噪后的呼吸/心跳混合波形）
%       fs —— 采样频率（Hz）
%   输出：
%       heartrate —— 心跳频率
%                     心率 = heartrate * 60
%
% 算法流程：
%   1. analyse_power_spectrum 计算信号功率谱；
%   2. findpeaks 找出功率谱全部谱峰；
%   3. 只保留频率落在 [1, 1.6] Hz（60~96 bpm）且功率 > 4 的谱峰；
%   4. 对有效谱峰频率取平均，得到心跳频率。
%   说明：正常成人心率约 60~100 bpm（1~1.67 Hz），本函数搜索
%         1~1.6 Hz 频段内的功率谱峰作为心跳分量。
%
% 示例：
%   hr = GetHeartRate(res_csi_amplitude, 20);      % fs = 20 Hz
%   fprintf('心率 = %.1f bpm\n', hr*60);

%% 第一步：功率谱分析
[pows,freq] = analyse_power_spectrum(x,fs);
[pks,locs] = findpeaks(pows);

% 定位搜索频段边界：左边界 = 第一个 >= 1Hz 的频率点，右边界 = 第一个 >= 1.6Hz
for i = 1:size(freq,2)
    if freq(i) >= 1
        left = i;
        break;
    end
end
for i = 1:size(freq,2)
    if freq(i) >= 1.6
        right = i;
        break;
    end
end

%% 第二步：累加有效谱峰（1~1.6 Hz 且功率 > 4）
sum = 0;count = 0;
for i = 1:size(locs,2)
    if locs(i) > left && locs(i) < right && pks(i) > 4
        sum = sum + freq(locs(i));
        count = count + 1;
    end
end

% 有效谱峰频率的均值即心跳频率
heartrate = sum / count;
end
