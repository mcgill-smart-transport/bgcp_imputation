function mat = ten2mat(tensor,dim,k)
% This is a function for tensor unfolding.
% 	dim = (n1,n2,...,nd)
% 	k=1,2,...,d

mat = reshape(permute(tensor,[k,1:k-1,k+1:length(dim)]),dim(k),[]);
end