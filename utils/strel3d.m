function [se,n,rx,ry,rz] = strel3d(r)

% 判断用户输入半径
if length(r)<2
    rx = r;
    ry = r;
    rz = r;
elseif length(r)>2
    rx = r(1);
    ry = r(2);
    rz = r(3);
else
    rx = r(1);
    ry = r(1);
    rz = r(2);
end

% 生成球形二值图 并获得目标索引
[x,y,z] = meshgrid(-rx:rx,-ry:ry,-rz:rz);
[x,y,z] = find3d(sqrt(x.^2+y.^2+z.^2)<(rx+ry+rz)/2.5); % 注意这里的判定方式
se = [x-rx-1,y-ry-1,z-rz-1];

n = size(se,1);

end