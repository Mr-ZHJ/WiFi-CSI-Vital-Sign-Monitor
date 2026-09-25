%% PButterWorthFilter.m —— 相位信号 Butterworth 带通滤波（心跳频段）
% 功能：对去均值后的相位信号做 FFT 频域分析，设计 3~5 Hz 的
%       Butterworth 带通滤波器（心跳谐波频段），提取心跳分量。
%
% 流程：
%   1. 相位信号去均值 → FFT → 绘制幅度谱
%   2. buttord / butter 设计满足指标的模拟带通滤波器
%   3. filter 对相位信号执行滤波并绘图
%
% 输入：res_csi（Hampel 滤波后的相位序列）
% 输出：y（带通滤波后的心跳波形）
%%

% 第一步：去均值 + FFT 频域分析
res_csi2 = res_csi2 - mean(res_csi);            % 去均值（基准校准）
f = fftshift(fft(res_csi2-mean(res_csi2)));     % FFT 并零频居中
size_f = size(f);
w = linspace(-10,10,length(res_csi2));           % 归一化频率轴

ff = f*0.01;   % 幅度缩放（仅用于显示）

% 绘制幅度谱
w = linspace(-10,10,length(ff));
plot(w,abs(ff));

% 第二步：设计 Butterworth 带通滤波器（3~5 Hz，心跳频段）
Fs = 100;                       % 采样频率
wp = [3 5]*2*pi/Fs;             % 通带边界频率（rad/s）：3~5 Hz
ws = [2 6]*2*pi/Fs;             % 阻带边界频率（rad/s）
Rp = 1; Rs = 20;                % 通带波纹 1dB、阻带衰减 20dB

% buttord：计算最小滤波器阶数 N 与自然频率 Wn
[N,Wn] = buttord(wp,ws,Rp,Rs,'s');
% butter：生成模拟带通滤波器系数
[bb,ab] = butter(N,Wn,'s');

% 可选：绘制滤波器频率响应
% W = 0:0.01:2;
% [Hb,wb]=freqs(bb,ab,W);
% plot(wb/pi,20*log10(abs(Hb)),'b');

% 第三步：对相位信号执行滤波
y = filter(bb,ab,res_csi);
% 可选：进一步平滑 / 小波去噪
% y = smooth(y);
% y(:) = wden(y,'heursure','s','one',3,'sym3');

% 绘制滤波后的心跳波形
plot(y);
xlabel('时间/(0.05s)');
ylabel('相位');
