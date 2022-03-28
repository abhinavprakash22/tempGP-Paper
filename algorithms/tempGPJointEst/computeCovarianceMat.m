function[covMat] = computeCovarianceMat(x1,x2, theta, type)
    distMat = computeSqDistMat(x1, x2, theta);
    if type == "sqExp"
        covMat = exp(-0.5*distMat);
    elseif type == "matern32"
        covMat = (1+sqrt(3*distMat)).*exp(-sqrt(3*distMat));
    elseif type == "matern52"
        covMat = (1+sqrt(5*distMat)+(5*distMat/3)).*exp(-sqrt(5*distMat));
    elseif type == "exp"
        covMat = exp(-sqrt(distMat));
    end
    
    return
end

