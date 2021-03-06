% Using the p = 1 files
% file1_name = ‘100_1.000000_100000_SM1_NC_Jan_13.dat’;
% file2_name = ‘500_1_50000_NC_104.dat’; % 2nd, N = 500 
% file3_name = ‘1000_1.000000_80000_SM1_NC_Jan_13.dat’; % 3rd N = 1000
% file4_name = ‘5000_1.000000_60000_SM1_NC_Jan_14.dat’; % 4th, N = 5000
% file5_name = ‘10000_1_30000_NC_105.dat’; % 5th, N = 10000
% file6_name = ‘50000_1.000000_5000_SM1_NC_Jan_28.dat’; % 6th, N = 50000
% file7_name = ‘100000_1.000000_1000_SM1_NC_Jan_28.dat’; % 7th, N = 100,000

%Declaring Constants here
N_1 = 100; N_2 = 500; N_3 = 1000; N_4 = 5000; N_5 = 10000; N_6 = 50000; N_7 = 100000;
%N_1 = 100; N_2 = 500; N_3 = 1000; N_4 = 5000; N_5 = 10000; N_6 = 100000; 
SYS_SIZE_ARRAY = [N_1; N_2; N_3; N_4; N_5; N_6; N_7]; %N_7]; %want to ensure that each file is matched with the corresponding system size!!!!
X_CRIT = 0.5;             % constant value in the theoretical tanh function
delimiter_char = ' ';   % delimiting character to distinguish columns in the imported data.

file1 = importdata(file1_name, delimiter_char);    % N_1 = 100
file2 = importdata(file2_name, delimiter_char);    % N_2 = 500
file3 = importdata(file3_name, delimiter_char);    % N_3 = 1000
file4 = importdata(file4_name, delimiter_char);    % N_4 = 5000
file5 = importdata(file5_name, delimiter_char);    % N_5 = 10000
file6 = importdata(file6_name, delimiter_char);    % N_6 = 50000
file7 = importdata(file7_name, delimiter_char);    % N_7 = 100000

%fh_a = [f1h, f2h, f3h, f4h, f5h, f6h, f7h, f8h];

question = 'For a conventional data set (x goes from 0 to 1), press 1. For a non-conventional data set (e.g. x = 0.25 to 0.75), press 0.\n';
answer = input(question);

% these remaining questions are asked by default
    question = 'What is the delta_x value?\n';
    delta_x = input(question);
    question = 'What is the top value (e.g. x = 0.75)?\n';
    top_num = input(question);
    question = 'What is the bottom value (e.g. x = 0.25)?\n';
    bottom_num = input(question);
    
    if (answer == 1)   % conventional data set 
    NUM_OF_X_INTERVALS = 1 + ((top_num - bottom_num)/(delta_x));
    end
    if (answer == 0)   % non-conventional data set
    NUM_OF_X_INTERVALS = ((top_num - bottom_num)/(delta_x));
    end
    
    question = 'What is the lower limit on lambda?\n';
    lower_lambda = input(question);
    
    question = 'What is the upper limit on lambda?\n';
    upper_lambda = input(question);
    
    question = 'What is the lower limit on nu?\n';
    lower_nu = input(question);
    
    question = 'What is the upper limit on nu?\n';
    upper_nu = input(question);
    
    question = 'What is the number of indices?\n';
    NUM_OF_INDICES = input(question);
    
    question = 'What is the graph tick mark increment value (e.g. 100)?\n';
    TICK_INCREMENT = input(question);
    
    question = 'What is our starting index (1 to include N = 100, 2 to exclude N = 100)\n';
    filestart_index = input(question);
    
    question = 'What is our ending index (e.g., 7 would mean going all the way to N = 100000)';
    fileend_index = input(question);
    
    question = 'Will we be analyzing Joe data (press 1) or Tom Data? (press 0)\n';  % Joe = 1, Tom = 0. 
    person_answer = input(question);

question = 'Are we doing the Integer format (1) or the doing the decimal format (0) for exit probability?\n';
num_answer = input(question);

lambda = linspace(lower_lambda,upper_lambda,NUM_OF_INDICES);      % lambda ranges from 0 -> 5, we are divvying it into 1000 (NUM_OF_INDICES) sections
nu = linspace(lower_nu,upper_nu,NUM_OF_INDICES);              % nu ranges from 0 -> 5, we are divvying it into 1000 (NUM_OF_INDICES) sections
x_array = linspace(bottom_num,top_num,NUM_OF_X_INTERVALS);      % make sure that we are evaluating the simulation and theoretical functions at the same x-value.
lambda_index = 0;   % index to go through the array of lambda values..
nu_index = 0;       % index to go through the array of nu values
x_index = 0;        % index to go through the x-values (for the E(x,L) data.
lambda_value = 0.0;  %specific value of lambda at a particular index
nu_value = 0.0;      % specific value of nu at a particular index

E_simulation = 0.0;            % value of E(x,L) as generated by my/Tom's simulation.
E_theory = 0.0;             %value of the Exit probability predicted by tanh function
tanh_component = 0;          % component of the tanh value calculation being initialized to zero.

error_max = 10000.0;       % default maximum error value. each value which is less than the existing value of error_max overwrites it.
best_lambda = 0.0;
best_nu = 0.0;    %these two variables will be stored into memory whenever I find a lambda-nu pair that does well with all of the seven datasets.
              %   That is, it has the lowest cumulative error for all seven files.

% Variables which will be used for the heatmap applications
error_sum = 0;
lambda_nu_error_sum = 0;
M_error = zeros(NUM_OF_INDICES);   % Create the Matrix which holds the cumulative error across all files (for heatmap applications), initialize it

%******************************************************
% The General Data Analysis Loop
for lambda_index=1:NUM_OF_INDICES                    %BEGIN LAMBDA_LOOP
    lambda_value = lambda(lambda_index);   % grab the instantaneous value of lambda.
        for nu_index=1:NUM_OF_INDICES            %BEGIN NU_LOOP
            nu_value = nu(nu_index);           % grab the instantaneous value of nu.
                lambda_nu_error_sum = 0;    %At this point, we have a dedicated lambda, nu pair, so I will reinitialize lambda_nu_error_sum.
                for file_index=filestart_index:fileend_index        % BEGIN_FILE_LOOP (loop through the seven different files
                    error_sum = 0;           %error sum depends on one file (particular N-value) alone, so it should be reinitialized for every new file
                        for x_index=1:NUM_OF_X_INTERVALS   % BEGIN Go from 0 to 1
                            %sort out what simulation value to grab here
                            if file_index == 1
                               if person_answer == 1
                                   E_simulation = file1(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file1(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file1(x_index,3)/file1(x_index,2);
                                    end
                               end
                            end
                            if file_index == 2
                                if person_answer == 1
                                   E_simulation = file2(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file2(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file2(x_index,3)/file2(x_index,2);
                                    end
                               end
                            end
                            if file_index == 3
                               if person_answer == 1
                                   E_simulation = file3(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file3(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file3(x_index,3)/file3(x_index,2);
                                    end
                               end
                            end
                            if file_index == 4
                               if person_answer == 1
                                   E_simulation = file4(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file4(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file4(x_index,3)/file4(x_index,2);
                                    end
                               end
                            end
                            if file_index == 5
                               if person_answer == 1
                                   E_simulation = file5(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file5(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file5(x_index,3)/file5(x_index,2);
                                    end
                               end
                            end
                            if file_index == 6
                               if person_answer == 1
                                   E_simulation = file6(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file6(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file6(x_index,3)/file6(x_index,2);
                                    end
                               end
                            end
                            if file_index == 7
                               if person_answer == 1
                                   E_simulation = file7(x_index,2);
                               end
                               if person_answer == 0
                                    E_simulation = file7(x_index,2);
                                    if num_answer == 1
                                        E_simulation = file7(x_index,3)/file7(x_index,2);
                                    end
                               end
                            end
                            
                                x_value = x_array(x_index);      %grab an instantaneous value of x                     
                                tanh_1 = (lambda_value/X_CRIT)*(x_value - X_CRIT);
                                tanh_2 = SYS_SIZE_ARRAY(file_index);
                                tanh_component = tanh(tanh_1*((tanh_2)^(nu_value^(-1))));   % compute the tanh( ) function evaluation (in several steps)
                                E_theory = X_CRIT*(1+tanh_component);  
                                error_sum = error_sum + [E_simulation - E_theory]*[E_simulation - E_theory]; 
								% find difference between data and theory, add it to the error (for a particular file/system size)
                       
                        end                        %END GO FROM 0 to 1
                    lambda_nu_error_sum = lambda_nu_error_sum + error_sum;   % increment cumulative error (boosted by each new file/system size)
                end                          %END FILE_LOOP
                    if lambda_nu_error_sum < error_max
                        error_max = lambda_nu_error_sum;
                        best_lambda = lambda_value;             % determine best new exponents
                        best_nu = nu_value;
                    end 
                % Assign cumulative error to lambda-nu pair, store in the error matrix
                M_error(lambda_index,nu_index) = lambda_nu_error_sum;
            end                            %END NU_LOOP
          %  fprintf('M_error of %f    %f lambda value %f  nu_value %f    is %f and the stored error value is %f\n',lambda_index, nu_index,lambda_value,nu_value, lambda_nu_error_sum, M_error(lambda_index,nu_index));
end                                       %END LAMBDA_LOOP

% all pairs tried, now report the best lambda, nu values
fprintf('The best lambda is %f and the best nu is %f with a cumulative error of error_max = %f\n\n', best_lambda,best_nu,error_max);%

M_error_inv = M_error.^(-1); % invert the error matrix, so now it is a best fit matrix
figure;                      % create figure object   
mesh(M_error_inv)            % create the heatmap (actually a 3d surface)

% set up the axes’ properties
xlabel('\nu')
set(gca, 'XLim', [0 NUM_OF_INDICES])
set(gca, 'XTick', [0:TICK_INCREMENT:NUM_OF_INDICES])
set(gca,'XTickLabel',[lower_nu:((upper_nu - lower_nu)*TICK_INCREMENT/NUM_OF_INDICES):upper_nu]) % x is nu

ylabel('\lambda')
set(gca, 'YLim', [0 NUM_OF_INDICES])
set(gca, 'YTick', [0:TICK_INCREMENT:NUM_OF_INDICES])
set(gca,'YTickLabel',[lower_lambda:((upper_lambda - lower_lambda)*TICK_INCREMENT/NUM_OF_INDICES):upper_lambda])  %y is lambda

zlabel('Error(\nu,\lambda)')


% Data File listings
% Tom's P = 1 Data Runs delta_x = 0.01, integer format 
% file1_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_a.dat';   %   1st, N = 100
% file2_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_b.dat';   %   2nd, N = 500
% file3_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_c.dat';   %   3rd  N = 1000
% file4_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_d.dat';  %    4th, N = 5000
% file5_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_e.dat';  %   5th, N = 10000
% file6_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_f.dat';  %    6th, N = 50000
% file7_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=1_Runs\june13_g.dat'; %  7th, N = 100,000

%  Tom's P = 0.5 Data Runs  delta_x = 0.001, decimal format 
%  file1_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_a.dat'   %   1st, N = 100
%  file2_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_b.dat';   %   2nd, N = 500
%  file3_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_c.dat';   %   3rd  N = 1000
%  file4_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_d.dat';  %    4th, N = 5000
%  file5_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_e.dat';  %   5th, N = 10000
%  file6_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_f.dat';  %    6th, N = 50000
%  file7_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.5_Runs\dec15_g.dat'; %  7th, N = 100,000

% % Tom's P = 0.1 Data Runs   delta_x = 0.01, decimal format 
% file1_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_a.dat';   %   1st, N = 100
% file2_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_b.dat';   %   2nd, N = 500
% file3_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_c.dat';   %   3rd  N = 1000
% file4_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_d.dat';  %    4th, N = 5000
% file5_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_e.dat';  %   5th, N = 10000
% file6_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_f.dat';  %    6th, N = 50000
% file7_name = 'C:\Users\Joey\Desktop\HONORS_THESIS\SZNAJD_MODEL\TOM_EXIT_PROBABILITY\TOM_P=0.1_Runs\nov13_g.dat'; %  7th, N = 100,000

% Joseph's Data Runs
% P = 0  need more data
%file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.000000_5000_SM1_NC_Feb_ 2.dat';
%file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0_2000_NC.dat';   %   
%file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.000000_3000_SM1_NC_Feb_2.dat'; 3rd  N = 1000
%file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\100_0.000000_5000_SM1_NC_Feb_ 2.dat';  %    4th, N = 5000
%file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\100_0.000000_5000_SM1_NC_Feb_ 2.dat';  %   5th, N = 10000
%file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\100_0.000000_5000_SM1_NC_Feb_ 2.dat';  %    6th, N = 50000
%file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100_0.000000_5000_SM1_NC_Feb_ 2.dat'; %  7th, N = 100,000

% P = 0.001
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.001000_100000_SM1_NC_Jan_13.dat'
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0.001_5000_NC_1209.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.001_4000_NC_1209.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_0.001_1000_NC_1224.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_0.001_1000_NC_1224.dat';  %   5th, N = 10000
% %file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_??????0.001_300_NC_1_1_15.dat'; %  7th, N = 100,000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_0.001_300_NC_1_1_15.dat'; %  7th, N = 100,000

% P = 0.005    
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.005000_100000_SM1_NC_Jan_13.dat'
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0.005_5000_NC_1209.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.005_4000_NC_1209.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_0.005_5000_NC_1130.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_0.005_4000_NC_1130.dat';  %   5th, N = 10000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_0.005_1000_NC_1227.dat';  %    6th, N = 50000
% file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_0.005_800_NC_1227.dat'; %  7th, N = 100,000

% P = 0.01 
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.010000_100000_SM1_NC_Jan_13.dat'
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0.010000_80000_SM1_NC_Jan_13.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.01_6000_NC_1209.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_0.010000_10000_SM1_NC_Jan_28.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_0.01_4000_NC_1130.dat';  %   5th, N = 10000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_0.01_1000_NC_1227.dat';  %    6th, N = 50000
% file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_0.01_1000_NC_1227.dat'; %  7th, N = 100,000

% P = 0.05
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.050000_100000_SM1_NC_Jan_16.dat'
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0.050000_80000_SM1_NC_Jan_13.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.050000_80000_SM1_NC_Jan_13.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_0.050000_30000_SM1_NC_Jan_19.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_0.05_6000_NC_1130.dat';  %   5th, N = 10000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_0.05_10000_NC_1128.dat';  %    6th, N = 50000
% file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_0.050000_700_SM1_NC_Jan_28.dat'; %  7th, N = 100,000

% P = 0.1
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.100000_100000_SM1_NC_Jan_13.dat';
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0.100000_80000_SM1_NC_Jan_13.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.100000_80000_SM1_NC_Jan_13.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_0.100000_60000_SM1_NC_Jan_14.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_0.1_6000_NC_1130.dat';  %   5th, N = 10000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_0.100000_2000_SM1_NC_Jan_28.dat';  %    6th, N = 50000
% file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_0.100000_700_SM1_NC_Jan_28.dat'; %  7th, N = 100,000

% P = 0.5
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_0.500000_100000_SM1_NC_Jan_13.dat'
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_0.500000_80000_SM1_NC_Jan_13.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_0.500000_80000_SM1_NC_Jan_13.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_0.500000_60000_SM1_NC_Jan_14.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_0.5_10000_NC_1130.dat';  %   5th, N = 10000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_0.500000_2000_SM1_NC_Jan_28.dat';  %    6th, N = 50000
% file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_0.500000_1000_SM1_NC_Jan_28.dat'; %  7th, N = 100,000

% P = 1
% file1_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100_Runs\100_1.000000_100000_SM1_NC_Jan_13.dat'
% file2_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=500_Runs\500_1_50000_NC_104.dat';   %   2nd, N = 500 (NIY)
% file3_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=1000_Runs\1000_1.000000_80000_SM1_NC_Jan_13.dat';   %   3rd  N = 1000
% file4_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=5000_Runs\5000_1.000000_60000_SM1_NC_Jan_14.dat';  %    4th, N = 5000
% file5_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=10000_Runs\10000_1_30000_NC_105.dat';  %   5th, N = 10000
% file6_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=50000_Runs\50000_1.000000_5000_SM1_NC_Jan_28.dat';  %    6th, N = 50000
% file7_name = 'D:\HONORS_THESIS\SZNAJD_MODEL\JOEY_EXIT_PROBABILITY\N=100000_Runs\100000_1.000000_1000_SM1_NC_Jan_28.dat'; %  7th, N = 100,000


