%% AHampelFilterM.m —— 动态场景幅度比 Hampel 滤波
% 功能：对动态场景下的幅度比序列 raw_csi_amplitude 执行 Hampel 滤波
%       剔除异常值，绘制原始曲线并标记异常点（红色方块）。
%
% 输入：raw_csi_amplitude（由 GetAmplitudeRatioM.m 生成的幅度比序列）
% 输出：res_csi_amplitude（滤波后序列）、j（异常点下标）
%%

% 第一组参数：窗口半径 3、阈值 2 倍 MAD（滤波结果）
res_csi_amplitude(:) = hampel(raw_csi_amplitude(:),3,2);
% 第二组参数：窗口半径 4、阈值 3 倍 MAD（标定异常点位置）
[y,j(:),xmedian,xsigma] = hampel(raw_csi_amplitude(:),4,3);

time = 0.01:0.01:40;   % 时间轴：每包 0.01s，共 4000 包

% 绘制原始幅度比曲线
plot(time,raw_csi_amplitude);
hold on

% 标记异常点（红色方块）
plot(time(find(j)),raw_csi_amplitude(1,j),'sr');
hold on

xlabel('时间/s');
ylabel('幅度(dB)');
