clc;
clear;
low_rank = 50;
mape = zeros(5,1);
rmse = zeros(5,1);
for i = 1:5
    ratio = 0.1*i;
    load tensor;
    dim = size(tensor);
    [dense_tensor,sparse_tensor] = ms_scenario(tensor,'ms','random','missing_rate',ratio);
    dense_matrix = ten2mat(dense_tensor,dim,1);
    sparse_matrix = ten2mat(sparse_tensor,dim,1);
    [tensor_hat,model,result] = BGCP_Gibbs(dense_matrix,sparse_matrix,'CP_rank',low_rank,'maxiter',1000);
    mape(i,1) = result{1};
    rmse(i,1) = result{2};
end