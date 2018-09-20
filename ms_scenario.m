function [dense_tensor,sparse_tensor] = ms_scenario(tensor,varargin)
% Missing data scenario - random missing & fiber missing.

dim = size(tensor);
ip = inputParser;
ip.addParameter('ms','fiber',@(x)ismember(x,{'random','fiber'}));
ip.addParameter('missing_rate',0.2,@isscalar);
ip.parse(varargin{:});

ms = ip.Results.ms;
ratio = ip.Results.missing_rate;

if strcmp(ms,'random')
    load random_tensor;
    binary_tensor = round(random_tensor+0.5-ratio);
    sparse_tensor = tensor.*binary_tensor;
    dense_tensor = tensor;
elseif strcmp(ms,'fiber')
    load random_matrix;
    binary_tensor = zeros(dim);
    for i1 = 1:dim(1)
        for i2 = 1:dim(2)
            binary_tensor(i1,i2,:) = round(random_matrix(i1,i2)+0.5-ratio);
        end
    end
    sparse_tensor = tensor.*binary_tensor;
    dense_tensor = tensor;
end
end