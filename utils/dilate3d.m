function out = dilate3d(in,r)

[R,C,S] = size(in);
% 生成球形结构元
[se,n,rx,ry,rz] = strel3d(r);

out = false(R,C,S);
for i = 1+rx:R-rx
    for j = 1+ry:C-ry
        for k = 1+rz:S-rz
            if in(i,j,k) == 1                
                for idx = 1:n
                    out(i+se(idx,1),j+se(idx,2),k+se(idx,3)) = 1;
                end
            end
        end
    end
end

end