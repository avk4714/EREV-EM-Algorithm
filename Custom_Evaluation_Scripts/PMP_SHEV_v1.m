% Pontryagin's Minimum Principle - SHEV
%% Drive Cycle
drvCycle.time_s = [];           % Time Vector - 1 Hz(required)
drvCycle.spd_mph = [];          % Speed Vector
drvCycle.grade_pct = [];        % Road Grade Vector
numCycle = 14;

if ~isempty(drvCycle)
    test = table2array(readtable('us06col.txt','HeaderLines', 2));
    for i = 1:numCycle
        if i == 1
            drvCycle.time_s = test(:,1); %[test(:,1);(test(:,1) + test(end,1) + 1)];
            drvCycle.spd_mph = test(:,2); %[test(:,2);test(:,2)];
        else
            drvCycle.time_s = [drvCycle.time_s;
                               drvCycle.time_s(end) + test(:,1) + 1];
            drvCycle.spd_mph = [drvCycle.spd_mph;
                                test(:,2)];
        end
    end
    N = length(drvCycle.time_s);   %Time Step
end
clear test                      % Remove unwanted variables
%% State Constraints - SOC
SOC_MIN = 0.1;      % Lower Limit
SOC_MAX = 1.0;      % Upper Limit
SOC_INIT = 1.0;     % Initial Value
SOC_TARGET = 0.1;   % Target SOC
MAX_FUEL = 26.49;   % Liters. 1 Liter = 0.264172

%% Power Demand Calculation - SHEV Camaro Model
%-- Vehicle Parameters
VehMass = 2012;       % Vehicle & Driver Weight
rl_a = 23;
rl_b = 0.1;
rl_c = 0.01;
L_aux = 520;                % Auxiliary load due to electronics [W]

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


%-- PMP - Power Request Calculation
% 1. Adjust power demand - Negative power demand values imply
% braking/stoppage. For ease of calculation, any power value below or equal
% to zero will be treated as a zero.
  
P_req = L_total + L_aux;

% 2. Feasible power range for battery and engine.
% Battery available power varies with SOC

P_BATT_UL = 208000;         % Discharge is positive
P_BATT_LL = -102000;        % Charge is negative

%P_GEN_UL = 15000;           % Charge to battery is negative
%P_GEN_LL = 0;               % Lower Limit is zero


% 3. Initialize additional variables and parameters

L_xN = 0;
X_opt = zeros([N 1]);               % State (SOC)
P_gen_opt = zeros([N 1]);
P_batt_opt = zeros([N 1]);
P_fuel_opt = zeros([N 1]);
%P_regen_opt = zeros([N 1]);
E_BATT = 18900;                 % Wh
P_REGEN_MAX = -15000;           % W
P_REGEN_LUT = [0 0;
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
               38 -15000];          % Regen power Lookup Table    
eta_genmot = 0.86;                  % mean value obtained based on the Bosch ICD

% 5. Initialize feasible battery and generator power values.
P_BATT_FEAS = zeros([N 2]);
P_GEN_FEAS = zeros([N 2]);
P_PRECISION = 500;            % Watts


%% Loop Section
m = 1;
COSTATE_FLAG = [];
COSTATE = [];
COSTATE_DEL = [];
CS_LL = 0.0;                            % Lower limit on the co-state
CS_UL = 10.0;                           % Upper limit on the co-state
COSTATE_INIT = (CS_UL - CS_LL)/2;       % Initial co-state estimate
ITERATE_FLAG = 1;
MAX_ITERATION = 10;

while(ITERATE_FLAG == 1 && MAX_ITERATION > 0)
GEN_FLAG = 0;

P_GEN_RANGE = [0,5000:500:15000]';
    %% Co-State Search: Bisection Method
    if m == 1
        COSTATE(m,1) = COSTATE_INIT;
        COSTATE_DEL(m,1) = 0;
    else
        if COSTATE_FLAG == -1
            CS_UL = COSTATE(m-1,1);
            COSTATE(m,1) = (CS_UL + CS_LL)/2;
            COSTATE_DEL(m,1) = COSTATE(m,1) - COSTATE(m-1,1);
        elseif COSTATE_FLAG == 1
            CS_LL = COSTATE(m-1,1);
            COSTATE(m,1) = (CS_UL + CS_LL)/2;
            COSTATE_DEL(m,1) = COSTATE(m,1) - COSTATE(m-1,1);
        end
    end
    l = 1;
    FuelUsed_L = zeros([N 1]);
    Dist_Trvld_m = zeros([N 1]);
    EC_Wh = zeros([N 1]);
    BATT_FLAG(1) = 1;
        while(l <= N)
            %% Section 1: Updated SOC
            if l == 1
                X_opt(l,1) = SOC_INIT;
                BATT_FLAG(l) = 1;
            elseif (X_opt(l-1,1) >= SOC_MIN) && (l ~= 1)
                X_opt(l,1) = X_opt(l-1,1) - (P_batt_opt(l-1,1)/(3600 * E_BATT));
                BATT_FLAG(l) = 1;
            else
                X_opt(l,1) = X_opt(l-1,1) - (P_batt_opt(l-1,1)/(3600 * E_BATT));
                %X_opt(l,1) = X_opt(l-1,1);          % Contactors on the battery opened.
                BATT_FLAG(l) = 0;
            end

            %% Section 2: Feasibility Vector
            % Available regen power is always negative.
            P_regen_avail = interp1(P_REGEN_LUT(:,1),P_REGEN_LUT(:,2),(drvCycle.spd_mph(l,1)*0.447),'linear');
            
            % Fuel check: In a scenario that the fuel is finished,
            % generator must be turned off.
            if GEN_FLAG == 1
                P_GEN_RANGE = P_GEN_RANGE * 0;
            end
            
            % Feasible parameter vector formation
            if P_req(l) > 0     % Acceleration
                if P_req(l) > P_BATT_UL     % Exceeding maximum battery power available
                    P_BATT_FEAS(l,1) = P_BATT_UL;
                    P_BATT_FEAS(l,2) = P_BATT_UL;
                    P_GEN_FEAS(l,1) = min((P_req(l) - P_BATT_UL),min(P_GEN_RANGE));     % Assuming there is no infeasible power demand
                    P_GEN_FEAS(l,2) = max(P_GEN_RANGE);
                else 
                    P_BATT_FEAS(l,1) = P_req(l) - max(P_GEN_RANGE);
                    P_BATT_FEAS(l,2) = P_req(l);
                    P_GEN_FEAS(l,1) = min(P_GEN_RANGE);
                    P_GEN_FEAS(l,2) = max(P_GEN_RANGE);
                end
            else                % No Propulsion or Braking
                P_BATT_FEAS(l,1) = max(P_req(l),P_regen_avail) - max(P_GEN_RANGE);
                P_BATT_FEAS(l,2) = max(P_req(l),P_regen_avail);
                P_GEN_FEAS(l,1) = min(P_GEN_RANGE);
                P_GEN_FEAS(l,2) = max(P_GEN_RANGE);
            end
            % Feasible Range at every time step
            P_BATT_RANGE = (P_BATT_FEAS(l,2) - P_GEN_RANGE);
            RANGE_SZ = length(P_GEN_RANGE);
            PENALTY_COST = zeros([RANGE_SZ 1]);     %Initialized to zero
            fuelRate = zeros([RANGE_SZ 1]);
            % Penalty cost prevents battery charging when SOC is between 100 - 99%.
            if X_opt(l,1) >= 0.99
                pen_idx = find(P_BATT_RANGE < 0);
                PENALTY_COST(pen_idx,1) = -1000000;
            end

            %% Section 3: Hamiltonian
            for k = 1:RANGE_SZ
                [engEff,fuelRate(k,1)] = calcEngEff(abs(P_GEN_RANGE(k)/eta_genmot));
                P_FUEL_RANGE(k,1) = (P_GEN_RANGE(k)/eta_genmot) * (1/engEff);
                if isnan(P_FUEL_RANGE(k,1))
                    P_FUEL_RANGE(k,1) = 0;
                end
            end
            HAM_Range = P_FUEL_RANGE + (COSTATE(m,1) * P_BATT_RANGE) +...
                (PENALTY_COST .* P_BATT_RANGE);
            H_Total(l,:) = HAM_Range;
            H(l,1) = min(HAM_Range);
            H_idx = find(HAM_Range == H(l,1));
            % Edge Case
            if length(H_idx) ~= 1
                H_idx = 1;
            end
            % ---
            P_gen_opt(l,1) = P_GEN_RANGE(H_idx);
            P_batt_opt(l,1) = P_BATT_RANGE(H_idx);
            P_fuel_opt(l,1) = P_FUEL_RANGE(H_idx);
            if l == 1
                FuelUsed_L(l,1) = fuelRate(H_idx);
            else
                FuelUsed_L(l,1) = FuelUsed_L(l-1,1) + fuelRate(H_idx);
            end
            
            %% Check if enough fuel is left
            if FuelUsed_L(l,1) > MAX_FUEL
                GEN_FLAG = 1;
            else
                GEN_FLAG = 0;
            end
            
            %% Overall energy consumption
            if (BATT_FLAG(l) ~= 0) && (l == 1)
                Dist_Trvld_m(l,1) = 0;
            elseif (BATT_FLAG(l) ~= 0) && (l ~= 1)
                Dist_Trvld_m(l,1) = Dist_Trvld_m(l-1,1) + (drvCycle.spd_mph(l,1) * ...
                0.44704);
                EC_Wh(l,1) = EC_Wh(l-1,1) + ((P_fuel_opt(l,1) + P_batt_opt(l,1))/3600);
            else
                Dist_Trvld_m(l,1) = Dist_Trvld_m(l-1,1);
                EC_Wh(l,1) = EC_Wh(l-1,1);
            end  

            l = l + 1;
        end

        %% Final: SOC Target condition check
        TOLERANCE = 0.02;       % +/- 2% SOC Tolerance
     if m == 1   
        if X_opt(end) - SOC_TARGET > TOLERANCE
            ITERATE_FLAG = 1;
            COSTATE_FLAG = -1;
            disp(['## Iteration ',num2str(m),' completed! Will re-iterate.'])
            disp(['Co-State = ',num2str(COSTATE(m,1))])
            disp('---')
        elseif X_opt(end) - SOC_TARGET < (-1 * TOLERANCE)
            ITERATE_FLAG = 1;
            COSTATE_FLAG = 1;
            disp(['## Iteration ',num2str(m),' completed! Will re-iterate.'])
            disp(['Co-State = ',num2str(COSTATE(m,1))])
            disp('---')
        else
            ITERATE_FLAG = 0;
            disp('## Solution obtained.')
            disp(['Co-State = ',num2str(COSTATE(m,1))])
            disp('---')
        end
     elseif (COSTATE_DEL(m,1) + COSTATE_DEL(m-1,1) == 0) 
        ITERATE_FLAG = 0;
        disp('## Solution obtained.')
        disp(['Co-State = ',num2str(COSTATE(m,1))])
        disp('---')
     else
         if X_opt(end) - SOC_TARGET > TOLERANCE
            ITERATE_FLAG = 1;
            COSTATE_FLAG = -1;
            disp(['## Iteration ',num2str(m),' completed! Will re-iterate.'])
            disp(['Co-State = ',num2str(COSTATE(m,1))])
            disp('---')
        elseif X_opt(end) - SOC_TARGET < (-1 * TOLERANCE)
            ITERATE_FLAG = 1;
            COSTATE_FLAG = 1;
            disp(['## Iteration ',num2str(m),' completed! Will re-iterate.'])
            disp(['Co-State = ',num2str(COSTATE(m,1))])
            disp('---')
        else
            ITERATE_FLAG = 0;
            disp('## Solution obtained.')
            disp(['Co-State = ',num2str(COSTATE(m,1))])
            disp('---')
        end
     end
    m = m + 1;                          % Outer loop iteration counter
    MAX_ITERATION = MAX_ITERATION - 1;
end
%% Overall Energy Consumption Calculation & Post Processing
EC_Wh_m = EC_Wh(end)/Dist_Trvld_m(end);

