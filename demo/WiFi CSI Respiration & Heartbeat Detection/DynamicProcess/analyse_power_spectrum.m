function [pows, freq] = analyse_power_spectrum(X, Fs)
%ANALYSE_POWER_spectrum 计算信号的功率谱（FFT 法）
%   输入：
%       X  —— 待分析信号（行向量）
%       Fs —— 采样频率（Hz）
%   输出：
%       pows —— 功率谱（dB），10*log10(|FFT|^2 / N)
%       freq —— 对应频率轴（Hz），只返回正频率部分
%
%   说明：先对信号做 FFT 并零频居中（fftshift），取正频率半轴，
%         计算功率谱（分贝表示，除以 1800 为经验归一化系数）。
%         可用于确定呼吸/心跳频率对应的谱峰位置。

  % 信号长度
  N = length(X);

  % take FFT and shift it for symmetry
  % FFT 并将零频分量移到谱中心
  amp = fftshift(fft(X));

  % make frequency range
  % 构造频率轴：奇数长度时舍弃最后一个样本，保证对称
  fN = N - mod(N, 2);
  k = -fN/2 : fN/2 - 1;
  T = N / Fs;
  freq = k/T;

  % select the positive domain FFT and range
  % 只保留正频率半轴
  one_idx = fN/2 + 2;
  amp = amp(one_idx:end);
  freq = freq(one_idx:end);

  % return power spectrum
  % 功率谱（dB）：除以 1800 为经验归一化系数
  pows = 10*log10((abs(amp).^2)./1800);
end
