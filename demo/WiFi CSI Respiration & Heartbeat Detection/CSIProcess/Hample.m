%% Hample.m —— 降噪第一步：Hampel 滤波剔除异常值
% 功能：对 result_matrix 中 90 个子载波通道的幅度数据逐列执行 Hampel 滤波，
%       识别并替换脉冲型异常值（如采集过程中的突发噪声）。
%
% 输入：result_matrix（由 ReandandParse.m / YM1.m 生成，第 1~90 列为幅度）
% 输出：更新后的 result_matrix（第 1~90 列被替换为滤波结果）
%
% Hampel 原理：以滑动窗口内数据的中位数为中心，偏离超过 num_dev 倍
%              MAD（Median Absolute Deviation，中位数绝对偏差）的样本
%              被视为异常值并用窗口中位数替换。
%
% 可调参数：window_size（窗口大小）、num_dev（判定阈值，单位为 MAD 的倍数）
%           —— window_size 越大滤波越强，但会抹平真实呼吸波峰；
%           —— num_dev 越小越灵敏，容易误杀正常峰值。
%
% 注意：本脚本直接修改工作区中的 result_matrix，请在同一 MATLAB 会话中
%       先运行 ReandandParse.m（或 YM1.m）后再运行本脚本。
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

%% ---------- Hampel 滤波 ----------
% 设定 Hampel 滤波器参数
window_size = 5;   % 滑动窗口大小（单侧），可根据需要调整
num_dev = 2;       % 异常值判定阈值：偏离中位数超过 2 倍 MAD 视为异常

% 对每一个子载波通道分别处理
for k = 1:90
    % hampel(x, k, nsigma)：k 为窗口半径，nsigma 为 MAD 倍数阈值
    filtered_data = hampel(amplitude_data(:, k), window_size, num_dev);

    % 滤波结果写回 result_matrix 对应列
    result_matrix(:, k) = filtered_data;
end

%% ---------- 可视化：滤波后数据 ----------
subplot(2, 1, 2);                      % 选中第 2 个子图
plot(result_matrix(:, 1:90));
xlabel('时间');
ylabel('幅度');
title('幅度随时间的变化（Hampel）');
hold off
