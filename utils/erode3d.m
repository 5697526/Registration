function out = erode3d(in,r)
% 生成球形结构元
[R,C,S] = size(in);
[se,n,rx,ry,rz] = strel3d(r);

out = false(R,C,S);
for i = 1+rx:R-rx
    for j = 1+ry:C-ry
        for k = 1+rz:S-rz
            out(i,j,k) = 1;
            for idx = 1:n
                if in(i+se(idx,1),j+se(idx,2),k+se(idx,3))<1
                    out(i,j,k) = 0;
                    break;                    
                end
            end                                   
        end
    end
end

end