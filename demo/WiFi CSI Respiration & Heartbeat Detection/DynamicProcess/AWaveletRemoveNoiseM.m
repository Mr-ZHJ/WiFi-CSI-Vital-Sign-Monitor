%% AWaveletRemoveNoiseM.m —— 动态场景幅度比小波去噪
% 功能：对 Hampel 滤波后的动态场景幅度比信号（res_csi_amplitude）
%       执行小波去噪，方案二为最终采用参数并绘制结果。
%
% 两组参数说明：
%   方案一 res_csi_amplitude1：'heursure' 启发式阈值 + 软阈值 's' + sym3 小波 + 2 层分解
%   方案二 res_csi_amplitude2：'sqtwolog' 通用阈值 + 硬阈值 'h' + sym9 小波 + 5 层分解（采用）
%
% 输入：res_csi_amplitude（Hampel 后幅度比序列）、time
% 输出：res_csi_amplitude1、res_csi_amplitude2
%%

% 方案一：heursure + 软阈值 + sym3、2 层分解
res_csi_amplitude1(:) = wden(res_csi_amplitude(:),'heursure','s','one',2,'sym3');

% 方案二：sqtwolog + 硬阈值 + sym9、5 层分解（本场景采用）
res_csi_amplitude2(:) = wden(res_csi_amplitude(:),'sqtwolog','h','one',5,'sym9');

% 三联图对比（可选，取消注释即可）
% subplot(3,1,1);
% plot(time,raw_csi_amplitude(:));
%
% subplot(3,1,2);
% plot(time,res_csi_amplitude1(:));

% subplot(3,1,3);

% 绘制方案二去噪结果
plot(time,res_csi_amplitude2(:));
