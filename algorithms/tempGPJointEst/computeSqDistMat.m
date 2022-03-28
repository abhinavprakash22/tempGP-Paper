function[distMat] = computeSqDistMat(x1,x2,theta)
    nrows = size(x1,1);
    ncols = size(x2,1);
    ncov = size(x1,2);
    distMat = zeros(nrows,ncols);
    if nargin > 2
        if ncov > 1
            for i = 1:ncov
                distMat = distMat + (((x1(:,i) - (x2(:,i)')).^2)/(theta(i)^2));
            end
        else
            distMat =  ((x1 - (x2')).^2)/(theta^2);
        end
    elseif nargin == 2
        if ncov > 1
            for i = 1:ncov
                distMat = distMat + ((x1(:,i) - (x2(:,i)')).^2);
            end
        else
            distMat =  ((x1 - (x2')).^2);
        end
    else
        error('function requires at least two inputs.\n')
    end
end