%% DBSCAN_clustering.m —— 基于 DBSCAN 的有人/无人场景聚类（人体检测第二步）
% 功能：对 GeneralizeDataSample.m 生成的特征样本（有人 + 无人）执行
%       DBSCAN（基于密度的空间聚类）聚类，自动区分两类场景，
%       无需预先指定类别数。
%
% DBSCAN 参数：
%   k   = 3     —— 邻域内最少点数（MinPts），少于此数不构成核心点
%   Eps = 2     —— 邻域半径，小于此距离视为邻居
%
% 输入：DataSample、DataSample2（由 GeneralizeDataSample.m 生成）
% 输出：聚类结果可视化（不同颜色 = 不同簇；黑色* = 噪声点/离群点）
%       class 向量记录每个样本的簇编号（<=0 表示噪声点）
%
% 依赖：Statistics and Machine Learning Toolbox（KDTreeSearcher / rangesearch）
%%

close all;
clc;
k = 3;       % DBSCAN 最小邻域点数 MinPts
Eps = 2;     % DBSCAN 邻域半径
data = [DataSample; DataSample2];   % 合并有人/无人两组特征样本

%% 生成模拟数据（可选，取消注释可用合成数据测试聚类效果）
% n = 200;
% a = linspace(0,8*pi,n/2);
% u = [5*cos(a)+5 10*cos(a)+5]'+1*rand(n,1);
% v = [5*sin(a)+5 10*sin(a)+5]'+1*rand(n,1);
% mu1 = [20 20];
% S1 = [10 0;0 10];
% data1 = mvnrnd(mu1,S1,100);
% data = [u v;data1];
%
% image = imread('data.png');
% image = image(:,:,1);
% [x,y]=find(image == 0);
% data=[x,y];

%% ---------- 准备变量，绘制原始输入点 ----------
[m,n] = size(data);
data=[(1:m)',data];       % 第 1 列附加样本编号，第 2~3 列为特征
n = n + 1;
type = zeros(1,m);
cluster_No = 1;           % 当前簇编号（从 1 开始）
visited = zeros(m,1);     % 访问标记：1 = 已访问
class = zeros(1,m)-2;     % 簇标签：初始化为 -2（未分类），<=0 含噪声

% 绘制原始输入散点
plot(data(:,2),data(:,3),'k.');
grid on
xlabel('x');ylabel('y');
title('原始输入点');
hold on;

%% ---------- DBSCAN 主循环 ----------
% 先构建 KD 树加速邻域查询（样本量大时比暴力搜索快得多）
Kdtree = KDTreeSearcher(data(:,2:3));

for i = 1:m
    % 抽取一个未访问点
    if visited(i)==0
        % 标为访问
        visited(i) = 1;
        point_now = data(i,:);
        % rangesearch：查询 Eps 半径内的全部邻居下标
        Idx_range = rangesearch(Kdtree, point_now(2:3), Eps);
        index = Idx_range{1};
        % 邻居数 > MinPts → 该点为核心点，扩展一个新簇
        if length(index) > k
            class(i) = cluster_No;
            % 不断将邻域内的未访问点并入当前簇（密度可达链式扩展）
            while index
                if visited(index(1)) == 0
                    visited(index(1)) = 1;
                    if class(index(1)) <= 0
                        class(index(1)) = cluster_No;
                    end
                    % 以新并入的点为中心继续扩展邻域
                    point_now = data(index(1),:);
                    Idx_range = rangesearch(Kdtree, point_now(2:3), Eps);
                    index_temp = Idx_range{1};
                    index(1) = [];
                    % 新点也满足核心点条件（邻居数 > MinPts）才继续扩展
                    if length(index_temp) > k
                        index = [index, index_temp];
                    end
                else
                    index(1) = [];
                end
            end
            cluster_No = cluster_No + 1;   % 当前簇扩展完毕，开始下一个簇
        end
    end
end

%% ---------- 可视化聚类结果 ----------
figure;
% 每个簇用随机颜色绘制
for i = 1: cluster_No
    color = [rand(),rand(),rand()];
    data_class = data(find(class==i),:);
    plot(data_class(:,2),data_class(:,3),'.','Color',color,'MarkerFaceColor',color);
    hold on
end
% 噪声点（未被归入任何簇的离群点）用黑色*标记
data_class = data(find(class<=0),:);
plot(data_class(:,2),data_class(:,3),'k*');
hold on
grid on
xlabel('x');ylabel('y');
title('DBscan聚类结果');
