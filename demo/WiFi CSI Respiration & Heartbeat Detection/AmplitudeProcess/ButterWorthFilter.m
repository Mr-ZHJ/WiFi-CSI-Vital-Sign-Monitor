%% ButterWorthFilter.m —— Butterworth 带通滤波器设计与应用（呼吸频段）
% 功能：对去均值后的 CSI 幅度信号做 FFT 频域分析，设计 0.3~0.6 Hz 的
%       Butterworth 带通滤波器（成人呼吸典型频段），滤出呼吸分量。
%
% 流程：
%   1. 对第 16 号子载波幅度去均值，FFT 观察频谱（幅度谱）
%   2. buttord 计算满足指标的最低滤波器阶数（通带波纹 1dB，阻带衰减 20dB）
%   3. butter 生成模拟带通滤波器系数
%   4. freqs 绘制滤波器频率响应
%   5. filter 对信号执行滤波并绘制结果
%
% 输入：res_csi2（Hampel + 小波去噪后的 CSI 幅度，行=时间）
% 输出：y（滤波后的呼吸波形）
%
% 说明：wp/ws 为通带/阻带边界频率（rad/s），Fs=20 Hz 为采样频率；
%       此处用模拟滤波器（'s'）设计后直接 filter，属验证性写法。
%%

% 第一步：信号去均值 + FFT 频域分析
res_csi2 = res_csi2(16,:) - mean(res_csi2(16,:));   % 去均值，消除直流分量
f = fftshift(fft(res_csi2));                        % FFT 并将零频移到中心
size_f = size(f);
w = linspace(-10,10,length(res_csi2));              % 归一化频率轴

ff = f*100;   % 幅度缩放（仅用于显示）

% 绘制幅度谱
w = linspace(-10,10,length(ff));
plot(w,abs(ff));

% 第二步：设计 Butterworth 带通滤波器（呼吸频段 0.3~0.6 Hz）
Fs = 20;                            % 采样频率
wp = [0.3 0.6]*2*pi/Fs;             % 通带边界频率（rad/s）：0.3~0.6 Hz
ws = [0.05 0.8]*2*pi/Fs;            % 阻带边界频率（rad/s）
Rp = 1; Rs = 20;                    % 通带最大波纹 1dB、阻带最小衰减 20dB

% buttord：计算满足指标的最小滤波器阶数 N 与自然频率 Wn
[N,Wn] = buttord(wp,ws,Rp,Rs,'s');
% butter：生成 N 阶模拟带通滤波器系数
[bb,ab] = butter(N,Wn,'s');

% 第三步：绘制滤波器频率响应
W = 0:0.01:2;
[Hb,wb]=freqs(bb,ab,W);
plot(wb/pi,20*log10(abs(Hb)),'b');

% 第四步：对信号执行滤波
y = filter(bb,ab,res_csi);
plot(y');
xlabel('时间/(0.05s)');
ylabel('幅度');
