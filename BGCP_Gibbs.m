function [tensor_hat,factor_mat,final_result] = BGCP_Gibbs(dense_tensor,sparse_tensor,varargin)
% Bayesian Gaussian CP decomposition (BGCP) using Gibbs sampling.

	dim = size(sparse_tensor);
	d = length(dim);
	position = find(sparse_tensor~=0);
	pos = find(dense_tensor>0 & sparse_tensor==0);
	binary_tensor = zeros(dim);
	binary_tensor(position) = 1;

	ip = inputParser;
	ip.addParamValue('CP_rank',30,@isscalar);
	ip.addParamValue('maxiter',1000,@isscalar);
	ip.parse(varargin{:});

	r = ip.Results.CP_rank;
	maxiter = ip.Results.maxiter;

	U = cell(d,1);
	for k = 1:d
		U{k} = 0.1*randn(dim(k),r);
	end

	beta0 = 1;
	nu0 = r;
	mu0 = zeros(r,1);
	tau_epsilon = 1;
	a0 = 1;
	b0 = 1;
	W0 = eye(r);

	%% Test Gibbs samplers for BGCP model.
	rmse = zeros(maxiter,1);
	fprintf('\n------Bayesian Gaussian CP decomposition using Gibbs sampling------\n');
	for iter = 1:maxiter
		for k = 1:d
			% Sample hyper-parameters \Lambda^{(k)} and \mu^{(k)}.
			U_bar = mean(U{k},1)';
			var_mu0 = (dim(k)*U_bar+beta0*mu0)./(dim(k)+beta0);
			var_nu = dim(k)+nu0;
			var_W = inv(inv(W0)+dim(k)*cov(U{k})+dim(k)*beta0/(dim(k)+beta0)*(U_bar-mu0)*(U_bar-mu0)');
			var_W = (var_W+var_W')./2;
			var_Lambda0 = wishrnd(var_W,var_nu);
			var_mu0 = mvnrnd(var_mu0,inv((dim(k)+beta0)*var_Lambda0))';

			% Sample factor matrice U^{(k)}.
			var1 = khatrirao_fast(U{[1:k-1,k+1:d]},'r')';
			var2 = kr(var1,var1);
			var3 = reshape(var2*(ten2mat(binary_tensor,dim,k)'),[r,r,dim(k)]);
			var4 = tau_epsilon*var1*ten2mat(sparse_tensor,dim,k)'+ones(r,dim(k)).*(var_Lambda0*var_mu0);
			for i = 1:dim(k)
				var_Lambda1 = tau_epsilon*var3(:,:,i)+var_Lambda0;
				inv_var_Lambda1 = inv((var_Lambda1+var_Lambda1')./2);
				var_mu = inv_var_Lambda1*var4(:,i);
				U{k}(i,:) = mvnrnd(var_mu,inv_var_Lambda1);
			end
		end

		% Compute the estimated tensor.
		tensor_hat = cp_combination(U,dim);
		rmse(iter,1) = sqrt(sum((dense_tensor(pos)-tensor_hat(pos)).^2)./length(pos));

		% Sample precision \tau_{\epsilon}.
		var_a = a0+0.5*length(position);
		error = sparse_tensor-tensor_hat;
		var_b = b0+0.5*sum(error(position).^2);
		tau_epsilon = gamrnd(var_a,1./var_b);

		% Print the results.
	    fprintf('iteration = %g, RMSE = %g km/h.\n',iter,rmse(iter));
    	% set(gcf,'Units','Normalized','OuterPosition',[0,0,1,1]);
    	% for k = 1:d
     %    	subplot(1,d+3,k);imagesc(U{k});colormap hot;colorbar;
    	% end
    	% subplot(1,d+3,d+1:d+3);plot(rmse(1:iter));
    	% ylim([3.0,5.7]);xlabel('iteration');ylabel('RMSE (km/h)');
    	% drawnow;
    end

    %% Average factor matrices over additional iterations.
	fprintf('\n------Final Result of Bayesian Gaussian CP decomposition------\n');
	factor_mat = cell(d,1);
	for k = 1:d
		factor_mat{k} = zeros(dim(k),r);
	end
	tensor_hat0 = zeros(dim);
	iters = 500;
	for iter = 1:iters
		for k = 1:d
			% Sample hyper-parameters \Lambda^{(k)} and \mu^{(k)}.
			U_bar = mean(U{k},1)';
			var_mu0 = (dim(k)*U_bar+beta0*mu0)./(dim(k)+beta0);
			var_nu = dim(k)+nu0;
			var_W = inv(inv(W0)+dim(k)*cov(U{k})+dim(k)*beta0/(dim(k)+beta0)*(U_bar-mu0)*(U_bar-mu0)');
			var_W = (var_W+var_W')./2;
			var_Lambda0 = wishrnd(var_W,var_nu);
			var_mu0 = mvnrnd(var_mu0,inv((dim(k)+beta0)*var_Lambda0))';

			% Sample factor matrice U^{(k)}.
			var1 = khatrirao_fast(U{[1:k-1,k+1:d]},'r')';
			var2 = kr(var1,var1);
			var3 = reshape(var2*(ten2mat(binary_tensor,dim,k)'),[r,r,dim(k)]);
			var4 = tau_epsilon*var1*ten2mat(sparse_tensor,dim,k)'+ones(r,dim(k)).*(var_Lambda0*var_mu0);
			for i = 1:dim(k)
				var_Lambda1 = tau_epsilon*var3(:,:,i)+var_Lambda0;
				inv_var_Lambda1 = inv((var_Lambda1+var_Lambda1')./2);
				var_mu = inv_var_Lambda1*var4(:,i);
				U{k}(i,:) = mvnrnd(var_mu,inv_var_Lambda1);
			end
			factor_mat{k} = factor_mat{k}+U{k};
		end

		% Compute an estimated tensor.
		tensor_hat = cp_combination(U,dim);
		tensor_hat0 = tensor_hat0+tensor_hat;

		% Sample precision \tau_{\epsilon}.
		var_a = a0+0.5*length(position);
		error = sparse_tensor-tensor_hat;
		var_b = b0+0.5*sum(error(position).^2);
		tau_epsilon = gamrnd(var_a,1./var_b);
	end
	for k = 1:d
		factor_mat{k} = factor_mat{k}./iters;
	end

	tensor_hat = tensor_hat0/iters;
	final_result = cell(2,1);
    FinalMAPE = sum(abs(dense_tensor(pos)-tensor_hat(pos))./dense_tensor(pos))./length(pos);
    final_result{1} = FinalMAPE;
	FinalRMSE = sqrt(sum((dense_tensor(pos)-tensor_hat(pos)).^2)./length(pos));
	final_result{2} = FinalRMSE;

	% Print the results.
    fprintf('Final RMSE = %g km/h, MAPE = %g\n',FinalRMSE,FinalMAPE);
end