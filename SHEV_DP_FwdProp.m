tic
%% Non Loop Section
%-- Load drive cycle 
drvCycle.time_s = [];           % Time Vector - 1 Hz(required)
drvCycle.spd_mph = [];          % Speed Vector
drvCycle.grade_pct = [];        % Road Grade Vector
numCycle = 3;
choice = 1;                     % Choice 1: To load from txt file
                                % Choice 2: To load from Google Drive
                                % Traces

if ~isempty(drvCycle)
    switch choice
        case 1
            test = table2array(readtable('ec3_eec_col.txt','HeaderLines', 2));
            for i = 1:numCycle
                if i == 1
                    drvCycle.time_s = test(:,1); %[test(:,1);(test(:,1) + test(end,1) + 1)];
                    drvCycle.spd_mph = test(:,2); %[test(:,2);test(:,2)];
                else
                    drvCycle.time_s = [drvCycle.time_s;
                                       drvCycle.time_s(end) + test(:,1) + 1];
                               %((i-1)*(test(end,1) + 1)) + test(:,1)]; %test(:,1) + test(end,1); %[test(:,1);(test(:,1) + test(end,1) + 1)];
                    drvCycle.spd_mph = [drvCycle.spd_mph;
                               test(:,2)]; %[test(:,2);test(:,2)];
                end
            end
        case 2
            pathName = '/Users/amankalia/Documents/MATLAB/DocResWork/Simulation_Models/PreDrive_DP_Optimization/RouteSelectorApp/Google_Drive_Traces';
            fileName = 'Nov252019125539.mat';
            load(strcat(pathName,'/',fileName));
            eval(['tempLoad =',fileName(1:end-4),';'])
            for i = 1:numCycle
                if i == 1
                    drvCycle.time_s = tempLoad.time_s; 
                    drvCycle.spd_mph = tempLoad.spd_mph; 
                else
                    drvCycle.time_s = [drvCycle.time_s;
                                       drvCycle.time_s(end) + tempLoad.time_s + 1];
                               %((i-1)*tempLoad.time_s(end,1)) + tempLoad.time_s + 1]; %test(:,1) + test(end,1); %[test(:,1);(test(:,1) + test(end,1) + 1)];
                    drvCycle.spd_mph = [drvCycle.spd_mph;
                               tempLoad.spd_mph]; %[test(:,2);test(:,2)];
                end
            end
    end           
    N = length(drvCycle.time_s);   %Time Step
end
clear test                      % Remove unwanted variables
%-- SHEV State Vector
SOC_Max = 1.0;
SOC_Min = 0.1;
SOC_Begin = 0.9;
SOC_Final = 0.1;
%SOC_Avail = SOC_Max - SOC_Final;        % For range calculation
SOC_Range = [];                         % Initializing SOC_range vector as an empty vector

%SOC_Min:0.00002:SOC_Max;
%M = length(SOC_Range);

%-- Vehicle Parameters
VehMass = 1852 + 160;     %Vehicle + Driver
rl_a = 23;
rl_b = 0.1;
rl_c = 0.005;
L_aux = 520;        % Auxiliary load due to electronics [W]

for ii = 1:N
    if ii == 1
        L_drv(ii,1) = 0;
        acc_drv(ii,1) = 0;
    else    % Power = mass * acc * velocity [W]
        acc_drv(ii,1) = (((drvCycle.spd_mph(ii) - drvCycle.spd_mph(ii-1))*0.447)/(drvCycle.time_s(ii) - drvCycle.time_s(ii-1)));
        L_drv(ii,1) = VehMass * acc_drv(ii,1) * abs((drvCycle.spd_mph(ii))*0.447); % - drvCycle.spd_mph(ii-1)
    end
    L_load(ii,1) = ((((rl_c * (drvCycle.spd_mph(ii))^2)) + (rl_b * drvCycle.spd_mph(ii)) + (rl_a)) * 4.448) * (drvCycle.spd_mph(ii) * 0.447);
    L_total(ii,1) = calcMotElecPwr((L_drv(ii) + L_load(ii)),drvCycle.spd_mph(ii));
end
    
%-- Adaptive DP
% 1. Adjust power demand - Negative power demand values imply
% braking/stoppage. For ease of calculation, any power value below or equal
% to zero will be treated as a zero.

%L_total(L_total <= 0) = 0;   
L_total = L_total + L_aux;

% 2. Total Energy Demand Associated with Drive Cycle and Distance
% Accmulated
for j = 1:N
    if j == 1
        E_dem_total(j,1) = 0;
        DistTrvld_m(j,1) = 0;
    else
        E_dem_total(j,1) = E_dem_total(j-1,1) + (L_total(j,1)/3600);        % Wh
        DistTrvld_m(j,1) = DistTrvld_m(j-1,1) + ...
            abs((drvCycle.spd_mph(j-1)) * 0.44704);   % meters
    end
end

% 3. Delta Power - Calculate change in power demand between steps to
% determine discharge and charge scenarios. This helps compute feasible SOC
% limits.

delPwr_W = zeros(size(L_total));    % First element is zero by default.
for i = 2:N
    delPwr_W(i,1) = L_total(i,1) - L_total(i-1,1);
end

% 4. Initialize minimum and maximum SOC values - For each time instance, a
% min and max SOC value can be obtained based on drive cycle data as well
% as power and energy limits.

X_lim = zeros([N 2]);       % X represents state (SOC) here. First column
                            % is min value and second is max value.
                            
X_lim(N,1) = SOC_Final;     % Initializing limits at final time equal to 
X_lim(N,2) = SOC_Final;     % the final SOC value.

X_PRCSN = 0.00002;           % Precision for the SOC. 0.0001 corresponds to 
                            % 0.01% SOC change.

% 5. Initialize additional variables and parameters

L_xN = 0;
%Y_x = zeros([N M]);             % Cost-to-go
%U_x = zeros([N M 2]);           % Control candidates
%Y_x_opt = zeros([N 1]);         % Optimal Cost-to-go Path
%U_x_opt = zeros([N 2]);         % Optimal Control candidates
X_opt = zeros([N 1]);           % State (SOC)
P_gen_opt = zeros([N 1]);
P_batt_opt = zeros([N 1]);
P_regen_opt = zeros([N 1]);
P_fuel_opt = zeros([N 1]);
E_batt = 18900;                 % Wh
P_gen_max = -15000; %-11500;             % W
P_batt_dchg_max = 208000;       % W
P_batt_ch_max = -102000;        % W
P_regen_max = -15000;           % W
P_regen_LUT = [0 0;
               2.6 0;
               5.2 -1250;
               7.8 -3000;
               10.4 -5500;
               13 -8000;
               15.6 -10250;
               18.2 -12500;
               20.8 -13750;
               23.4 -14000;
               26 -14500;
               28.6 -15000;
               31.2 -15000;
               33.8 -15000;
               38 -15000];    % Regen power Lookup Table    
% eta_eng = 0.36;                 % get the correct value based on the BSFC map
eta_genmot = 0.86;              % mean value obtained based on the Bosch ICD
%% Loop section - DP Forward Propagation
X_opt(1,1) = SOC_Begin;
l = 2;
minFsblRng = 250000;      % meters
while(l <= N)
    P_regen_avail = interp1(P_regen_LUT(:,1),P_regen_LUT(:,2),(drvCycle.spd_mph(l,1)*0.447),'linear');
    if L_total(l) > 0                                                    % Discharging condition
        % Step 1: Determine SOC Limits
        X_lim(l,2) = X_opt(l-1,1) -...
            ((L_total(l) + P_gen_max)/(E_batt * 3600));                     % Max feasible SOC
        X_lim(l,1) = X_opt(l-1,1) -...
            ((L_total(l))/(E_batt * 3600));                                 % Min feasible SOC
        
        % NOTE: Here Max feasible SOC corresponds to with generator and Min is
        % without generator. Because of Forward Propagation.
        
        % Step 2a: Form SOC Query Range and form delta SOC vector  
        X_range(:,1) = X_lim(l,1):X_PRCSN:X_lim(l,2);
        len_x_rng = length(X_range);
        % deltaSOC = X_range - X_opt(l+1,1);
    
        % Step 2b: Determine feasible SOC values based on range estimation
        ECvector_Wh_m(:,1) = ((X_opt(1,1) - X_range(:,1)) * E_batt)/...
            (DistTrvld_m(l,1) - DistTrvld_m(1,1));
       % EC_Wh_m(l,1) = ((X_opt(l,1) - X_opt(end,1)) * E_batt)...
       %     /(DistTrvld_m(end,1) - DistTrvld_m(l,1));
       
        % Step 3a: Compute control candidate values corresponding to all
        % delta SOC
        for k = 1:len_x_rng
            % ---
            if ECvector_Wh_m(k,1) > 0
                estRngVec_m(k,1) = ((X_range(k,1) - SOC_Min) * E_batt)/ECvector_Wh_m(k,1);
                fsblRngVec(k,1) = estRngVec_m(k,1) - (DistTrvld_m(end,1) - DistTrvld_m(l,1));
            else 
                estRngVec_m(k,1) = Inf;
                fsblRngVec(k,1) = estRngVec_m(k,1) - (DistTrvld_m(end,1) - DistTrvld_m(l,1));
            end
            % ---
            P_gen(k) = P_gen_max *...
                ((X_range(k) - X_range(1))/(X_range(end) - X_range(1)));
            if P_gen(k) ~= 0
                [engEff,~] = calcEngEff(abs(P_gen(k)/eta_genmot));
                P_fuel(k) = (P_gen(k)/eta_genmot) * (1/engEff);
            else
                P_fuel(k) = 0;
            end
            % ---
            if fsblRngVec(k,1) > minFsblRng
                P_batt(k) = L_total(l) + P_gen(k);
            else
                P_batt(k) = Inf;        % Maximum penalty added for infeasibility
            end
            P_regen(k) = 0;
        end
        
        % Step 3b: If all solution values result in infinity
        if isinf(P_batt)
            P_batt(end) = L_total(l) + P_gen(end);
        end
        
        % Step 4: Calculate Cost-to-go for each possible path.
        Y_x = (P_batt + abs(P_fuel))/3600;
        
        % Step 5: Determine optimal path as per cost function.
        opt_idx = find(Y_x == min(Y_x));
        
        % Step 6: Assign optimal SOC value and repeat.
        P_gen_opt(l,1) = P_gen(opt_idx);
        P_fuel_opt(l,1) = abs(P_fuel(opt_idx));
        P_batt_opt(l,1) = P_batt(opt_idx);
        P_regen_opt(l,1) = P_regen(opt_idx);
        X_opt(l,1) = X_range(opt_idx);
        
        %clear P_gen P_fuel P_batt P_regen
        
    elseif L_total(l) <= 0                                                  % Regen-braking condition
        % Step 1: Determine SOC Limits
        if L_total(l) > P_regen_avail
            L_final = L_total(l);
            X_lim(l,2) = X_opt(l-1,1) -...
                ((L_final + P_gen_max)/(E_batt * 3600));                        % Max feasible SOC
            X_lim(l,1) = X_opt(l-1,1) -...
                ((L_final)/(E_batt * 3600));                                    % Min feasible SOC  
        else
            L_final = P_regen_avail;
            X_lim(l,2) = X_opt(l-1,1) -...
                ((L_final + P_gen_max)/(E_batt * 3600));                        % Max feasible SOC
            X_lim(l,1) = X_opt(l-1,1) -...
                ((L_final)/(E_batt * 3600));                                    % Min feasible SOC   
        end
        
        % Step 2a: Form SOC Query Range and form delta SOC vector
        X_range(:,1) = X_lim(l,1):X_PRCSN:X_lim(l,2);
        len_x_rng = length(X_range);
        
        % ----    
        % Step 2b: Determine feasible SOC values based on range estimation
        ECvector_Wh_m(:,1) = ((X_opt(1,1) - X_range(:,1)) * E_batt)/...
            (DistTrvld_m(l,1) - DistTrvld_m(1,1));
        
        % Step 3a: Compute control candidate values corresponding to all
        % delta SOC
        for k = 1:len_x_rng
            % ---
            if ECvector_Wh_m(k,1) > 0
                estRngVec_m(k,1) = ((X_range(k,1) - SOC_Min) * E_batt)/ECvector_Wh_m(k,1);
                fsblRngVec(k,1) = estRngVec_m(k,1) - (DistTrvld_m(end,1) - DistTrvld_m(l,1));
            else 
                estRngVec_m(k,1) = Inf;
                fsblRngVec(k,1) = estRngVec_m(k,1) - (DistTrvld_m(end,1) - DistTrvld_m(l,1));
            end
            % ---
            P_gen(k) = P_gen_max *...
                ((X_range(k) - X_range(1))/(X_range(end) - X_range(1)));
            if P_gen(k) ~= 0
                [engEff,~] = calcEngEff(abs(P_gen(k)/eta_genmot));
                P_fuel(k) = (P_gen(k)/eta_genmot) * (1/engEff);
            else
                P_fuel(k) = 0;
            end
            P_regen(k) = L_final;
            % ---
            if fsblRngVec(k,1) > minFsblRng
                P_batt(k) = P_regen(k) + P_gen(k);
            else
                P_batt(k) = Inf;        % Maximum penalty added for infeasibility
            end
                 
        end
        
        % Step 3b: If all solution values result in infinity
        if isinf(P_batt)
            P_batt(end) = L_total(l) + P_gen(end);
        end
        
        % Step 4: Calculate Cost-to-go for each possible path.
        Y_x = (P_batt + abs(P_fuel))/3600;
        
        % Step 5: Determine optimal path as per cost function.
        opt_idx = find(Y_x == min(Y_x));
        
        % Step 6: Assign optimal SOC value and repeat.
        P_gen_opt(l,1) = P_gen(opt_idx);
        P_fuel_opt(l,1) = abs(P_fuel(opt_idx));
        P_batt_opt(l,1) = P_batt(opt_idx);
        P_regen_opt(l,1) = P_regen(opt_idx);
        X_opt(l,1) = X_range(opt_idx);
        
        %clear P_gen P_fuel P_batt P_regen
    end
    % Mileage computation and range estimation
    
    EC_Wh_m(l,1) = ((X_opt(1,1) - X_opt(l,1)) * E_batt)...
            /(DistTrvld_m(l,1));
        if EC_Wh_m(l,1) > 0
            estRange_m(l,1) = ((X_opt(l,1) - SOC_Min) * E_batt)/EC_Wh_m(l,1);
            fsblRange(l,1) = estRange_m(l,1) - (DistTrvld_m(end,1) - DistTrvld_m(l,1));
        else
            estRange_m(l,1) = Inf;
            fsblRange(l,1) = estRange_m(l,1) - (DistTrvld_m(end,1) - DistTrvld_m(l,1));
        end
    %clear estRngVec_m fsblRngVec ECvector_Wh_m
    l = l + 1;
end
if X_opt(end) < SOC_Min
    disp('## Infeasible Solution for given conditions ##')
    idx = find(X_opt < SOC_Min, 1);
    NetEC_opt = ((sum(P_batt_opt(1:idx-1)) + sum(P_fuel_opt(1:idx-1)))/3600)/DistTrvld_m(idx-1);    % Wh/m
else
    disp('## Optimization was successful ##')
    NetEC_opt = ((sum(P_batt_opt) + sum(P_fuel_opt))/3600)/DistTrvld_m(end);    % Wh/m
end

toc
%% Save variables
% sfname = strcat(fileName(1:end-4),'_SpdVarRes','_12','.mat');
% spname = '/Users/amankalia/Documents/MATLAB/DocResWork/Simulation_Models/PreDrive_DP_Optimization/RouteSelectorApp/Results_SpdVar/';
% 
% save(strcat(spname,sfname),'X_opt','SOC_Begin','SOC_Final','P_regen_opt',...
%     'P_gen_opt','P_fuel_opt','P_batt_opt','NetEC_opt','minFsblRng',...
%     'fsblRange','EC_Wh_m','estRange_m')

%% Initial Values
%{

%% SHEV Arc Cost Calculation -- needs fixing
X_opt(N) = SOC_Final;
l = N-1;
while(l > 1)
    delSOC = X_opt(l+1)-SOC_Range;                                  %Compute SOC change at each time step
    j = 1;
    while(j < M)
        if L_total(l) >= 0                                          %Power demand to drive the vehicle.
            if delSOC(j) < 0                                        % Battery got discharged
                P_batt(j) = abs(delSOC(j)) * E_batt * 3600;
                P_gen(j) = L_total(l) - abs(delSOC(j) * E_batt * 3600);
                if P_gen(j) < 0
                    P_gen(j) = 0;
                end
                if P_batt(j) + P_gen(j) > P_gen_max + P_batt_dchg_max    %Power constraint
                    P_batt(j) = inf;
                    P_gen(j) = inf;
                end
            else                                                    % Battery got charged   
                P_batt(j) = -1 * (delSOC(j) * E_batt * 3600);
                P_gen(j) = L_total(l) + (delSOC(j) * E_batt * 3600);
                if P_gen(j) > P_gen_max
                    P_gen(j) = inf;
                    P_batt(j) = inf;
                end
            end
        else                                                        %Power Recuperation
            if delSOC(j) <= 0                                        %Battery got discharged
                P_gen(j) = inf;
                P_batt(j) = inf; 
            else
                P_gen(j) = 0;
                P_batt(j) = -1 * (delSOC(j) * E_batt * 3600);
                if P_batt(j) < P_batt_ch_max
                    P_batt(j) = inf;
                end
            end
        end
        J_cost(j) = (P_gen(j)/(3600 * eta_eng)) + (P_batt(j)/3600);
        j = j + 1;
    end
    % Choosing the optimal value
    U_x(l,1:end-1,1) = P_batt;
    U_x(l,1:end-1,2) = P_gen;
    Y_x(l,1:end-1) = J_cost;
    if ~isinf(min(J_cost))
        idx_opt = find(J_cost == min(J_cost));
        X_opt(l) = SOC_Range(idx_opt);
        Y_x_opt(l) = J_cost(idx_opt);
        U_x_opt(l,1) = P_batt(idx_opt);
        U_x_opt(l,2) = P_gen(idx_opt);
        l = l-1;
    else
        X_opt(l) = X_opt(l+1);
        Y_x_opt(l) = Y_x_opt(l+1);
        U_x_opt(l,1) = P_batt(idx_opt);
        U_x_opt(l,2) = P_gen(idx_opt);
        l = l-1;
    end 
end     
toc

%% Figure
figure(1)
ax(1) = subplot(3,1,1);
yyaxis left
plot(drvCycle.time_s,drvCycle.spd_mph)
yyaxis right
plot(X_opt)
ax(2) = subplot(3,1,2);
plot(U_x_opt(:,1))
ax(3) = subplot(3,1,3);
plot(U_x_opt(:,2))
linkaxes(ax,'x')
%}