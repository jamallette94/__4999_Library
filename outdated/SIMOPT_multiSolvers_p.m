%                    SimOpt WRAPPER CODE MULTISOLVERS
%
%   ************************************************************* 
%   ***             Written by Anna Dong, Nellie Wu           ***
%   ***                       Mar 12, 2016                    ***
%   *************************************************************
%
% INPUT
%        problemnumber
%              Problem function number   
%        solverArray
%              Solver function numbers (as an array)
%        problemseed
%              Index of the substreams to use (integer >= 1)
%              See problem code for more information.
%        solverseed
%              Input seed(s) for solver, if required. 
%              Should equal NaN otherwise. 
%        logfilename
%              Character string indicating path to a log file (if
%              required)
%              Should equal NaN otherwise
%        budget: vector of budgets
%        plotopt: option to plot or not, default = 1, yes
%
% OUTPUT
%        Plot: x-axis: budget, 
%               y-axis: objective value, legend for each problem
%        FMatrix: length(problemArray) X length(budget)
%

function FMatrix = SIMOPT_multiSolvers_p(problemnumber, solverArray, problemseed, solverseed, budgetV, logfilename, plotopt)
%initialize
FMatrix=zeros(length(solverArray),length(budgetV));
FVarMatrix=zeros(length(solverArray),length(budgetV));

%input
reps = 30;
repsAlg = 30;
CILevel = 0.95;
ProblemStrV0 = char(importdata(strcat(pwd, '/index/ProblemNumber.csv')));
SolverStrV0 = char(importdata(strcat(pwd, '/index/SolverNumber.csv')));

%
solvernameV = repmat('', length(solverArray), size(SolverStrV0,2));
problemname = strtrim(ProblemStrV0(problemnumber,:));
problemstructhandle=str2func(strcat(problemname, 'Structure'));
problemhandle = str2func(problemname);

    for i=1:length(solverArray)
        %initialize
        FMatrix2 = zeros(repsAlg,length(budgetV));
        
        solvernameV(i,:) = SolverStrV0(solverArray(i),:);
        solvername = strtrim(solvernameV(i,:));
        solverstructhandle=str2func(strcat(solvername, 'Structure'));
        [NumSolverSeeds, NumStartingSols] = solverstructhandle();
        solverhandle=str2func(solvername);
        parfor j=1:repsAlg  %do 30 replications for each algo on the problem
            [minmax, ~, ~, ~, ~, ~, ~, x0, ~, ~, ~] = problemstructhandle(NumStartingSols, problemseed);
            [~, soln, ~, ~, ~, ~, ~, ~, ~, ~] = ...
            solverhandle(x0, problemname, problemseed, solverseed, budgetV, logfilename, minmax);
            seed1=unidrnd(10000,1,1);           
            for k=1:size(soln,1)
            	[fn, ~, ~, ~, ~, ~, ~, ~] = problemhandle(soln(k,:), reps, seed1);
                FMatrix2(j,k) = fn;
            end
        end
        FMatrix(i,:) = mean(FMatrix2);
        FVarMatrix(i,:) = var(FMatrix2);
        FnSEM = sqrt(FVarMatrix(i,:)/repsAlg);
        EWidth = norminv(1-(1-CILevel)/2,0,1)*FnSEM;
        if plotopt == 1
            rng('shuffle');
            errorbar(budgetV,FMatrix(i,:),EWidth,'-o', 'Color',rand(1,3));
            hold on
        end
            
        
%         [minmax, ~, ~, ~, ~, ~, ~, x0, ~, ~, ~] = problemstructhandle(NumStartingSols, problemseed);
%         [~, soln, ~, ~, ~, ~, ~, ~, ~, ~] = ...
%             solverhandle(x0, problemname, problemseed, solverseed, budgetV, logfilename, minmax);
%         seed1=unidrnd(10000,1,1);
%         for k=1:size(soln,1)
%             [fn, FnVar, ~, ~, ~, ~, ~, ~] = problemhandle(soln(k,:), reps, seed1);
%             FMatrix(i,k) = fn;
%             FVarMatrix(i,k) = FnVar;
%         end
%         FnSEM = sqrt(FVarMatrix(i,:)/reps);
%         EWidth = norminv(1-(1-CILevel)/2,0,1)*FnSEM;
%         if plotopt == 1
%             rng('shuffle');
%             errorbar(budgetV,FMatrix(i,:),EWidth,'-o', 'Color',rand(1,3));
%             hold on
%         end

    end
    if plotopt == 1
        legend(solvernameV);
        xlabel('Budget'); ylabel('Objective value');
        title(['Problem: ',problemname]);
    end
    
end

