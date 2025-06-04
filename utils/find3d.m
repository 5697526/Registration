function [x,y,z] = find3d(in)

[M,N,~] = size(in);

idx = find(in);

z = ceil(idx/M/N);
idx = idx-(z-1)*M*N;
y = ceil(idx/M);
x = idx-(y-1)*M;

end