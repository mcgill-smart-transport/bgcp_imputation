function tensor = mat2ten(mat,dim,k)
% Folding a matrix into a tensor.
% 	dim = (n1,n2,...,nd)
% 	k=1,2,...,d

dim0 = [([dim(1:k-1),dim(k+1:length(dim))]),dim(k)];
tensor = permute(reshape(mat',dim0),[1:k-1,length(dim),k:length(dim)-1]);