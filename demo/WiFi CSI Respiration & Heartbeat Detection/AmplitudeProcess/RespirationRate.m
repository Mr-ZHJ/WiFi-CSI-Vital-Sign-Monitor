%% RespirationRate.m —— 基于峰值检测的呼吸率计算
% 功能：对滤波去噪后的呼吸波形执行峰值检测（findpeaks），计算相邻
%       呼吸峰之间的平均间隔，从而得到呼吸频率（次/分钟）。
%
% 原理：
%   - findpeaks 找出波形中所有局部极大值及其位置；
%   - 相邻两峰的时间差即为一个呼吸周期 T（单位：采样点数）；
%   - 呼吸率 = 60 / (平均周期 × 采样周期)（次/分钟）。
%
% 输入：呼吸波形信号（示例中为变量 d，可为滤波后的幅度序列
%       raw_csi_amplitude / res_csi_amplitude，或陀螺仪真值 GyroX）
% 输出：波形图 + 峰值位置标记（红方块）；呼吸率（注释中计算）
%%

%呼吸数据进行处理，找到数据中的峰值，计算峰值之间的距离，并绘制数据的图形和峰值的位置
% 以下为可选的输入信号（取消注释即可切换）：
% data = readmatrix('TestData/mn1.csv');   % 读取手机陀螺仪真值
% GyroX = data(:, 5);                      % 陀螺仪 X 轴（呼吸起伏）
% respiration = GyroX;
% respiration = raw_csi_amplitude;         % 方案A：原始幅度比信号
% respiration = res_csi_amplitude;          % 方案B：Hampel+小波去噪后的信号
respiration = d;                           % 方案C：当前工作区变量 d

% 峰值检测：pks 为峰值幅度，locs 为峰位置（采样点下标）
[pks,locs] = findpeaks(respiration);

[x1, x2] = size(pks);
count = 0; sum = 0;

% 累加相邻峰值之间的距离（即每个呼吸周期的采样点数）
for i = 2:x1
    count = count + 1;
    sum = sum + locs(i) - locs(i-1);
end

% 呼吸率计算（次/分钟）：
%   平均周期 = sum/count（采样点数），乘以采样周期 0.01s 得到秒数，
%   呼吸率 = 60 / 平均周期(秒)
% respirationrate = 60/(sum / count) ;
% disp(respirationrate);

% 可视化：呼吸波形 + 峰值标记
plot(respiration'); hold on
plot(locs,pks,'sr');
xlabel('时间/(0.01s)');
ylabel('幅度');
