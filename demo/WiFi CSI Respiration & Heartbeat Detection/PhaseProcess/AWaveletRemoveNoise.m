%% AWaveletRemoveNoise.m —— 幅度比信号小波去噪（两种方案对比）
% 功能：对 Hampel 滤波后的幅度比信号（res_csi_amplitude）分别应用两组
%       小波去噪参数，并在三个子图中对比原始信号与两种去噪结果。
%
% 两组参数说明：
%   方案一 res_csi_amplitude1：'heursure' 启发式阈值 + 软阈值 's' + sym3 小波 + 2 层分解
%   方案二 res_csi_amplitude2：'sqtwolog' 通用阈值 + 硬阈值 'h' + sym7 小波 + 8 层分解
%
% 输入：res_csi_amplitude（Hampel 后幅度比）、raw_csi_amplitude（原始）、time
% 输出：res_csi_amplitude1、res_csi_amplitude2
%%

% 方案一：heursure 启发式阈值 + 软阈值 + sym3 小波、2 层分解
res_csi_amplitude1(:) = wden(res_csi_amplitude(:),'heursure','s','one',2,'sym3');

% 方案二：sqtwolog 通用阈值 + 硬阈值 + sym7 小波、8 层分解
res_csi_amplitude2(:) = wden(res_csi_amplitude(:),'sqtwolog','h','one',8,'sym7');

% 三联图对比（均取同一时间轴）
subplot(3,1,1);
plot(time,raw_csi_amplitude(:));         % 原始信号（Hampel 前）

subplot(3,1,2);
plot(time,res_csi_amplitude1(:));        % 方案一去噪结果

subplot(3,1,3);
plot(time,res_csi_amplitude2(:));        % 方案二去噪结果
