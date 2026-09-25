%% PWaveletRemoveNoise.m —— 相位信号小波去噪（两种方案对比）
% 功能：对 Hampel 滤波后的相位信号（res_csi）分别应用两组小波去噪
%       参数，取方案二结果再做 smooth 平滑并绘制。
%
% 两组参数说明：
%   方案一 res_csi1：'heursure' 启发式阈值 + 软阈值 's' + sym3 小波 + 3 层分解
%   方案二 res_csi2：'sqtwolog' 通用阈值 + 硬阈值 'h' + 'mln' 分层噪声估计 + sym9 小波 + 8 层分解
%
% 输入：res_csi（Hampel 后相位序列）、time
% 输出：res_csi1、res_csi2（去噪结果）
%%

% 方案一：heursure + 软阈值 + sym3、3 层分解
res_csi1(:) = wden(res_csi(:),'heursure','s','one',3,'sym3');

% 方案二：sqtwolog + 硬阈值 + mln 分层噪声估计 + sym9、8 层分解
res_csi2(:) = wden(res_csi(:),'sqtwolog','h','mln',8,'sym9');

% 三联图对比（可选，取消注释即可）
% subplot(3,1,1);
% plot(time,raw_csi);
%
% subplot(3,1,2);
% plot(time,res_csi1);
%
% subplot(3,1,3);

% 方案二结果再做滑动平均平滑后绘制
plot(time,smooth(res_csi2));
