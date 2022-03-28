%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    MIT License
%  
%    Copyright (c) 2020 Abhinav Prakash
%  
%    Permission is hereby granted, free of charge, to any person obtaining a copy
%    of this software and associated documentation files (the "Software"), to deal
%    in the Software without restriction, including without limitation the rights
%    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%    copies of the Software, and to permit persons to whom the Software is
%    furnished to do so, subject to the following conditions:
%  
%    The above copyright notice and this permission notice shall be included in all
%    copies or substantial portions of the Software.
%  
%    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%    SOFTWARE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   AUTHOR: ABHINAV PRAKASH
%   DESCRIPTION:
%   Main construtor for class temporalGP
%   INPUTS:
%       X: Input variable matrix
%       y: Response vector 
%       options: A data structure with at most following fields
%           1. thinningNumber: An integer specifying the thinning number.
%           By default, thinning number is computed internally.
%           2. standardize: A boolean specifying whether to standardize the
%           data; true by default.
%            
%             
%   OUTPUT: A data structure with the following elements
%       estimatedParams: A 'struct' with the estimates of the hyperparameters
%       thinningNumber: Estimated value of thinning number
%       stdX: Standardized input data matrix
%       stdStats: A 'struct' with values of location and scale used for data standardization
%       y: Response vector
%       objVal: Optimized value of negative loglikelihood
%       objGrad: A vector with gradient value at the optimal
%       objGradNorm: Norm of objGrad
%       exitflag: Exit flag from the optimization routine. See documentation of 'fminunc' for details.
%   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[obj] = fitTempGP(X,y,options)
    default_options = struct();
    default_options.standardize = true;
    default_options.thinningNumber = [];
    default_options.covFn = "sqExp";
    default_names = fieldnames(default_options);
    if exist('options','var')
        option_names = fieldnames(options);
        for field = 1:numel(default_names)
            if ~ismember(default_names{field},option_names)
                options.(default_names{field}) = default_options.(default_names{field});
            end
        end   
    else
        options = default_options;
    end
    obj = temporalGP(X,y);
    if ~isempty(options.thinningNumber) 
        obj.thinningNumber = options.thinningNumber;
    end
    if options.standardize
        obj.standardize = true;
        [obj.stdX, obj.stdStat] = utils.standardizeData(obj.trainX,"self");
    end
    obj.params.type = options.covFn;
    obj = estimateHyperparameters(obj);
    return
end
