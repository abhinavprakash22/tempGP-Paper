function [out] = EstimateParameters(y, x, t, covType)
    ncov = size(x,2);
    sigma_f = std(y)/sqrt(2);
    sigma_n = sigma_f;
    sigma_g = sigma_f;
    theta = std(x);
    phi = 15;;
    beta = mean(y);
    par0 = [theta,sigma_f,sigma_n,beta,sigma_g,phi];
    obj = @(par)computeGPloglik(y,x,t,struct('theta',par(1:ncov),...
        'sigma_f',par(ncov+1),'sigma_n',par(ncov+2),'beta',par(ncov+3),'type',covType(1)),...
        struct('sigma_g',par(ncov+4),'phi',par(ncov+5),'type',covType(2)));
    options = optimoptions('fminunc','Display','iter','SpecifyObjectiveGradient',true);
    [sol, fval, exitflag] =  fminunc(obj,par0,options);
    params.theta = abs(sol(1:ncov));
    params.sigma_f = abs(sol(ncov+1));
    params.sigma_n = abs(sol(ncov+2));
    params.beta = sol(ncov+3);
    params.sigma_g = abs(sol(ncov+4));
    params.phi = abs(sol(ncov+5));
    params.type = covType;
    out.params = params;
    out.fval = -fval;
    [~, grval] = obj(sol);
    out.grval = grval;
    out.exitflag = exitflag; 
    return
%     if exitflag ~= 1
%         while exitflag ~= 1
%             fprintf('Optimization stoppped because of exit flag %d \n',exitflag);
%             fprintf('Current Value of solution: \n');
%             fprintf('%8.6f ',sol);
%             fprintf('\nCurrent objective: %8.6f ',fval);
%             fprintf('\nRerunning optimization with the obtained solution as initial value. \n');
%             par0 = sol;
%             [sol, fval, exitflag] =  fminunc(obj,par0,options);
%         end
%     end   
end
