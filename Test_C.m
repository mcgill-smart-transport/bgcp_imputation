clc;
clear;
low_rank = 50;
mape = zeros(5,1);
rmse = zeros(5,1);
for i = 1:5
    ratio = 0.1*i;
    load tensor;
    dim = size(tensor);
    [original_tensor,sparse_tensor] = ms_scenario(tensor,'ms','random','missing_rate',ratio);
    original_tensor1 = zeros(dim(1),9,7,dim(end));
    sparse_tensor1 = zeros(dim(1),9,7,dim(end));
    for i1 = 1:dim(1)
    	for i2 = 1:dim(2)
    		original_tensor1(i1,ceil(i2/7),i2-7*(ceil(i2/7)-1),:) = reshape(original_tensor(i1,i2,:),[dim(end),1]);
    		sparse_tensor1(i1,ceil(i2/7),i2-7*(ceil(i2/7)-1),:) = reshape(sparse_tensor(i1,i2,:),[dim(end),1]);
    	end
    end
    [tensor_hat,model,result] = BGCP_Gibbs(original_tensor1,sparse_tensor1,'CP_rank',low_rank,'maxiter',1000);
    mape(i,1) = result{1};
    rmse(i,1) = result{2};
end