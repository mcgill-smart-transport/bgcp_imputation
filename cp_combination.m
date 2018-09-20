function tensor = cp_combination(factor_mat,dim)
% This is a function for the CP combination over factor matrices.

d = length(dim);
factor_mat = flipud(factor_mat);
if d == 2
    tensor = factor_mat{2}*factor_mat{1}';
elseif d == 3
    mat = kr(factor_mat{1},factor_mat{2});
    tensor = mat2ten(factor_mat{d}*mat',dim,1);
else
    mat = kr(factor_mat{1},factor_mat{2});
    for k = 3:d-1
        mat = kr(mat,factor_mat{k});
    end
    tensor = mat2ten(factor_mat{d}*mat',dim,1);
end
end