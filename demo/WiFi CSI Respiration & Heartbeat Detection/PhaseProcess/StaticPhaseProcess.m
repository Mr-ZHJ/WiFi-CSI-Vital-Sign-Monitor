%% StaticPhaseProcess.m —— 静止状态相位处理完整流程（Demo）
% 功能：演示静止状态下基于 CSI 相位差的呼吸检测流程：
%       相位差提取 → Hampel 滤波 → 小波去噪 → 平滑
%
% 信号选择说明：
%   相位差 = angle( csi(1,1,16) - csi(1,2,16) )
%   即第 16 号子载波在两根接收天线（RX1/RX2）上复数 CSI 之差的相位。
%   相位对胸部起伏造成的路径长度变化更敏感，且两通道作差可抵消
%   收发端的公共相位偏移（如载波频偏、采样时偏）。
%
% 数据说明：TestData/4_19_sn1.dat（包间隔 0.05s，约 20Hz）
% 依赖：read_bf_file.m、get_scaled_csi.m
%%

%% ---------- 第一步：读取数据并提取相位差序列 ----------
warning('off');
csi_trace = read_bf_file('TestData/4_19_sn1.dat');   % 读取原始 CSI 数据

% 逐帧提取第 16 号子载波的 RX1-RX2 相位差
for i = 1:1800
    csi_entry = csi_trace{i};
    csi = get_scaled_csi(csi_entry);      % 归一化信道矩阵（复数，1×3×30）

    csi_size = size(csi);

    % 两接收天线复数 CSI 作差后取相位，抑制公共相位偏移
    phase = angle(csi(1,1,16)-csi(1,2,16));

    raw_csi_phase(:,i) = phase;          % 相位差时间序列（1800 帧）
end

time = 0.05:0.05:90;   % 时间轴：每包 0.05s，共 1800 包（90s）

%% ---------- 第二步：Hampel 滤波（异常值剔除） ----------
% hampel(x, k, nsigma)：k=3 为窗口半径，nsigma=2 为 MAD 倍数阈值
res_csi_phase(:) = hampel(raw_csi_phase(:),3,2);
% 第二组参数（k=4, nsigma=3）：j 返回被判为异常值的样本下标
[y,j(:),xmedian,xsigma] = hampel(raw_csi_phase(:),4,3);

% 可选可视化：原始相位曲线 + 异常点标记
% plot(time,raw_csi);
% hold on
% plot(time(find(j)),raw_csi(1,j),'sr');
% hold on
% xlabel('时间/s');
% ylabel('相位');

%% ---------- 第三步：小波变换去噪 ----------
% wden：'sqtwolog'（通用阈值）、'h'（硬阈值）、'mln'（分层噪声估计）、5 层 sym7 小波
res_csi_phase(:) = wden(res_csi_phase(:),'sqtwolog','h','mln',5,'sym7');

% 去噪后再做一次 Hampel 平滑并绘图
plot(hampel(res_csi_phase,3,2));
