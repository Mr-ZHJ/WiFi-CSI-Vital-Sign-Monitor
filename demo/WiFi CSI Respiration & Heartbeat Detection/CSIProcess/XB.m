%% XB.m —— 降噪第三步：离散小波变换（DWT）去噪
% 功能：对 result_matrix 中 90 个子载波通道的幅度数据执行小波阈值去噪，
%       在保留呼吸/心跳等低频突变特征的同时进一步抑制宽带噪声。
%
% 输入：result_matrix（建议先经过 Hample.m + DT.m 两步处理）
% 输出：更新后的 result_matrix（第 1~90 列为小波去噪后的幅度）
%
% 设计说明：
%   - 小波基：'sym4'（Symlets 4，近似对称，适合呼吸等平滑周期信号）
%   - 阈值策略：'heursure'（启发式阈值，兼顾软/硬阈值的适用性）
%   - 阈值模式：'s'（软阈值，去噪后信号更平滑）
%   - 噪声估计：'one'（按第一层小波系数估计噪声水平）
%   - 分解层数：level = min(10, wmaxlev(...))，不超过信号长度允许的最大层数
%
% 注意：需要在 MATLAB 中安装 Wavelet Toolbox（wden / wmaxlev 函数）。
%       请在同一 MATLAB 会话中先运行前序脚本后再运行本脚本。
%%

% 取出幅度数据（90 列：30 子载波 × 3 接收天线）
amplitude_data = result_matrix(:, 1:90);

%% ---------- 可视化：原始数据 ----------
figure;
subplot(2, 1, 1);                       % 2×1 子图布局，选中第 1 个子图
plot(amplitude_data);
xlabel('时间');
ylabel('幅度');
title('幅度随时间的变化（原始）');
hold on

%% ---------- 小波去噪 ----------
% 初始化去噪后的数据矩阵
filtered_data = zeros(size(amplitude_data));

% 对每个子载波通道的幅度数据分别应用小波去噪
for i = 1:90
    % wmaxlev：根据信号长度与小波基计算最大可用的分解层数
    maxLevel = wmaxlev(size(amplitude_data, 1), 'sym4');
    % 实际层数取 min(10, maxLevel)，避免过度分解
    level = min(10, maxLevel);

    % wden 一维小波去噪：
    %   'heursure' —— 启发式阈值选择
    %   's'        —— 软阈值
    %   'one'      —— 使用第一层系数估计噪声标准差
    %   level      —— 分解层数
    %   'sym4'     —— 小波基
    filtered_data(:, i) = wden(amplitude_data(:, i), 'heursure', 's', 'one', level, 'sym4');
end

% 去噪结果写回 result_matrix
result_matrix(:, 1:90) = filtered_data;

%% ---------- 可视化：去噪后数据 ----------
subplot(2, 1, 2);                       % 选中第 2 个子图
plot(result_matrix(:, 1:90));
xlabel('时间');
ylabel('幅度');
title('幅度随时间的变化（DWT）');
hold off
