function elecPwr = calcMotElecPwr(vehOutPwr,vehSpd)
%CALCMOTGBXEFF Performs interpolation on a pre-computed motor - gearbox
% assembly efficiency map
%   Input arguments to this function include the required Output Vehicle
%   Power(W) and the Vehicle Speed(mph).

effMap = [0.25,0.31,0.30,0.29,0.282,0.279,0.275,0.270,0.25;
          0.31,0.36,0.39,0.45,0.445,0.44,0.43,0.383,0.305;
          0.37,0.39,0.48,0.641,0.635,0.62,0.585,0.541,0.458;
          0.38,0.406,0.64,0.7151,0.705,0.697,0.637,0.633,NaN;
          0.40,0.428,0.807,0.877,0.81,0.736,0.672,NaN,NaN;
          0.490,0.521,0.697,0.85,0.83,0.784,0.7514,NaN,NaN;
          0.58,0.601,0.761,0.847,0.850,0.814,NaN,NaN,NaN;
          0.64,0.694,0.865,0.912,0.931,NaN,NaN,NaN,NaN];

% The outPwrMap was computed  to depict the net
% feasible output Power [Watts] i.e. with two motors.

outPwrMap = [0.2094,104.7,209.4,314.1,418.8,523.5,628.2,732.9,837.6;
             5.235,2617.5,5235,7852.5,10470,13087.5,15705,18322.5,20940;
             10.47,5235,10470,15705,20940,26175,31410,36645,41880;
             15.705,7852.5,15705,23557.5,31410,39262.5,47115,54967.5,62820;
             20.94,10470,20940,31410,41880,52350,62820,73290,83760;
             26.175,13087.5,26175,39262.5,52350,65437.5,78525,91612.5,104700;
             31.41,15705,31410,47115,62820,78525,94230,109935,125640;
             36.645,18322.5,36645,54967.5,73290,91612.5,109935,128257.5,146580];    

% The elecPwrMap is based on the effMap and assumed outPwrMap to depict the
% amount of electric power [watts] required.
elecPwrMap = [0.8376,337.742,698,1083.103,1485.1064,1876.3441,2284.364,2714.44,3350.4;
              16.8871,7270.833,13423.0769,17450,23528.089,29744.32,36523.256,47839.43,68655.74;
              28.297,13423.077,21812.5,24500.78,32976.378,42217.742,53692.3077,67735.675,91441.048;
              41.329,19341.133,24539.063,32942.945,44553.192,56330.703,73963.89,86836.493,NaN;
              52.35,24462.62,25947.95,35815.28,51703.704,71127.72,93482.143,NaN,NaN;
              53.42,25119.962,37553.802,46191.1765,63072.289,83466.199,104504.92,NaN,NaN;
              54.15,26131.45,41274.64,55625.74,73905.88,96468.059,NaN,NaN,NaN;
              57.26,26401.297,42364.162,60271.382,78721.804,NaN,NaN,NaN,NaN];

motTrqbpt = [1;25;50;75;100;125;150;175];
motSpdbpt = [1;500;1000;1500;2000;2500;3000;3500;4000];

tireRad_m = 0.346;
gbxRat = 4.2;

qSpd_rpm = ((vehSpd * 0.447 * gbxRat)/(0.1047 * tireRad_m));
qTrq_Nm = (abs(vehOutPwr) * 0.5)/(qSpd_rpm * 0.1047);

pwrSign = sign(vehOutPwr);
%[r_sz,c_sz] = size(outPwrMap);
%qTrq_Nm = ;

% 1. For speed value less and greater than bpt values.
% Instead of extrapolating, we intend to continue using that limiting
% value.

if qSpd_rpm < 1
    qSpd_rpm = 1;
elseif qSpd_rpm > 4000
    qSpd_rpm = 4000;
end

% 2. Determine interpolated vector based on target speed.
idx = find(motSpdbpt == qSpd_rpm);
if ~isempty(idx)        % If the speed exists in the bpt vector
    outPwrVec(:,1) = outPwrMap(:,idx);
    elecPwrVec(:,1) = elecPwrMap(:,idx);
    effVec(:,1) = effMap(:,idx);
else            % If the speed does not exist in the bpt vector
    l_idx = find(motSpdbpt < qSpd_rpm, 1, 'last');
    u_idx = find(motSpdbpt > qSpd_rpm, 1);
    factor1 = (qSpd_rpm - motSpdbpt(l_idx))/(motSpdbpt(u_idx) - motSpdbpt(l_idx));
    outPwrVec(:,1) = outPwrMap(:,l_idx) + (factor1 * (outPwrMap(:,u_idx) - outPwrMap(:,l_idx)));
    elecPwrVec(:,1) = elecPwrMap(:,l_idx) + (factor1 * (elecPwrMap(:,u_idx) - elecPwrMap(:,l_idx)));
    effVec(:,1) = effMap(:,l_idx) + (factor1 * (effMap(:,u_idx) - effMap(:,l_idx)));
end

% 3. Determine the index for the required power
if abs(vehOutPwr) < 1
    elecPwr = 0;
else
    % idx2 = find(outPwrVec == abs(vehOutPwr));
    idx2 = find(motTrqbpt == abs(qTrq_Nm));
    if ~isempty(idx2)       % If the power exists in the outPwrVec
        %elecPwr = pwrSign * elecPwrVec(idx2,1);
        elecPwr = vehOutPwr/effVec(idx2,1);
    else
        %l_idx2 = find(outPwrVec < abs(vehOutPwr), 1, 'last');
        %u_idx2 = find(outPwrVec > abs(vehOutPwr), 1);
        l_idx2 = find(motTrqbpt < abs(qTrq_Nm), 1, 'last');
        u_idx2 = find(motTrqbpt > abs(qTrq_Nm), 1);
        if ~isempty(l_idx2) && ~isempty(u_idx2) 
            %if ~isnan(elecPwrVec(l_idx2)) && ~isnan(elecPwrVec(u_idx2))
            if ~isnan(effVec(l_idx2)) && ~isnan(effVec(u_idx2))
                factor2 = (abs(qTrq_Nm) - motTrqbpt(l_idx2))/(motTrqbpt(u_idx2) - motTrqbpt(l_idx2));
                t_eff = effVec(l_idx2,1) + (factor2 * (effVec(u_idx2,1) - effVec(l_idx2,1)));
                elecPwr = vehOutPwr/t_eff;
            elseif ~isnan(effVec(l_idx2)) && isnan(effVec(u_idx2))
                elecPwr = vehOutPwr/effVec(l_idx2,1);
            else
                idx3 = find(~isnan(effVec), 1, 'last');
                elecPwr = vehOutPwr/effVec(idx3,1);
            end       
        elseif isempty(l_idx2)
            factor2 = (abs(qTrq_Nm) - 0)/(motTrqbpt(u_idx2) - 0);
            t_eff = 0 + (factor2 * (effVec(u_idx2,1) - 0));
            elecPwr = vehOutPwr/t_eff;
        elseif isempty(u_idx2) 
            if ~isnan(effVec(l_idx2))
                elecPwr = vehOutPwr/effVec(l_idx2,1);
            else
                idx3 = find(~isnan(effVec), 1, 'last');
                elecPwr = vehOutPwr/effVec(idx3,1);
            end
        else 
            t_eff = effVec(u_idx2,1); 
            elecPwr = vehOutPwr/t_eff;
        end
    end
end

end

