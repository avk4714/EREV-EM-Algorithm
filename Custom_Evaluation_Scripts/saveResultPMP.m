% Use this script to save workspace variables as a MAT file
% Filename syntax:
% <Cycle Acronym>_<Number of Cycles>Cyc_<Starting SOC>_<Target SOC>_PMP.mat
fileName = 'US06_14Cyc_100_10_PMP.mat';
dir = 'PMP_SimResults/';

save(strcat(dir,fileName),'Dist_Trvld_m','drvCycle','EC_Wh_m','COSTATE',...
    'FuelUsed_L','H','H_Total','P_batt_opt','P_gen_opt','SOC_TARGET',...
    'X_opt','EC_Wh','GEN_FLAG')

clear all

%% 
% US06_PMP_14.DistTrvld_m = Dist_Trvld_m;
% US06_PMP_14.EC_Wh_m = EC_Wh_m;
% US06_PMP_14.P_batt_opt = P_batt_opt;
% US06_PMP_14.P_gen_opt = P_gen_opt;
% US06_PMP_14.SOC_opt = X_opt;
% US06_PMP_14.spd_mph = drvCycle.spd_mph;
% US06_PMP_14.H_Total = H_Total;
% US06_PMP_14.COSTATE = COSTATE;