%% WaveletRemoveNoise.m —— 两种小波去噪方案对比
% 功能：对 Hampel 滤波后的 30 个子载波幅度数据（res_csi）分别应用两组
%       小波去噪参数，并在三个子图中对比原始信号与两种去噪结果。
%
% 两组参数说明：
%   方案一 res_csi1：'heursure' 启发式阈值 + 软阈值 's' + sym3 小波 + 2 层分解
%                   —— 阈值较保守，保留更多细节
%   方案二 res_csi2：'sqtwolog' 通用阈值 + 硬阈值 'h' + sym7 小波 + 8 层分解
%                   —— 去噪更强，波形更平滑
%
% 输入：res_csi（Hampel 滤波后的幅度矩阵，30×时间）、raw_csi（原始幅度）
% 输出：res_csi1、res_csi2（两种去噪结果）
%%

% 方案一：heursure 启发式阈值 + 软阈值 + sym3 小波、2 层分解
for i = 1:30
    res_csi1(i,:) = wden(res_csi(i,:),'heursure','s','one',2,'sym3');
end

% 方案二：sqtwolog 通用阈值 + 硬阈值 + sym7 小波、8 层分解
for i = 1:30
    res_csi2(i,:) = wden(res_csi(i,:),'sqtwolog','h','one',8,'sym7');
end

% 绘制方案一结果
plot(time,res_csi1(:));
xlabel('时间(s)');
ylabel('幅度');

% 三联图对比：原始 / 方案一 / 方案二（均取第 16 号子载波）
subplot(3,1,1);
plot(time,raw_csi(16,:));        % 原始信号（Hampel 前）

subplot(3,1,2);
plot(time,res_csi1(16,:));       % 方案一去噪结果

subplot(3,1,3);
plot(time,res_csi2(16,:));       % 方案二去噪结果
