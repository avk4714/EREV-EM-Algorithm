%% Script Description

%% Open Model

% ## Check if model is already loaded, if not then open system
try
    openStat = get_param('SHEV_Camaro_PwrLossMdl','Shown');
catch
    open_system('SHEV_Camaro_PwrLossMdl') 
end

%% Load Simulation Parameters

t_step = 0.1;      % Simulation time step [seconds]

% Load drive cycle
opt = 2;
switch opt
    case 1  %EEC Drive Trace - Complete
        %load('EECY4_DriveCycle.mat')
        gfile = 'EECY4_DriveCycle';  
        load(strcat(gfile,'.mat'))
        simDrv = EECY4_AttemptCycle;
    case 2  %Seattle Route
        %load('SeattleRoute.mat')
        gfile = 'SeattleRoute';
        load(strcat(gfile,'.mat'))
        eval(['simDrv = ',gfile,';'])
    case 3  %EEC Drive Trace - Single Cycle
        %load('EEC_Single_DriveCycle.mat')
        gfile = 'EEC_Single_DriveCycle';  
        load(strcat(gfile,'.mat'))
        simDrv = EEC_Single;
    case 4  %Google downloaded drive trace
        %load('Dec062019154949.mat') %Dec032019165351.mat
        gfile = 'Dec062019154949';  
        load(strcat(gfile,'.mat'))
        eval(['simDrv = ',gfile,';'])
        %simNopt = N_OptResults;
        %simRopt = R_OptResults;
    case 5  % Custom Cycle
        gfile = 'CustomCycle3';
        load(strcat(gfile,'.mat'))
        eval(['simDrv = ',gfile,';'])
    otherwise
        error('Incorrect selection value.')
end

% Road Data
paramRdGrd = 0;     % Road grade in percent

% Battery Params

load('PwrLossMdl_ESS.mat')
load('PwrLossMdl_A123Battery.mat')
A123_ESS.Init_soc = 1.0;

% Propulsion System Params
mot_gbx_rat = 4.2;
tire_rad_m = 0.346;

load('PwrLossMdl_PropSysEffData.mat')
contMotTrq = [180;180;180;180;180;180;180;180;170];     % Limiting based on actual performance.

% Generator System Params
V_fuel_init_gal = 7;    % U.S. Gallons
rho_fuel_gpL = 783;   % Fuel Density [gpL]
E85_LHV = 30000;      % J/g

load('PwrLossMdl_GenSysEffData.mat')

% Energy Management Control Params
% 1. Rule-based energy mode control
cs_ll = 0.15;
cs_ul = 0.25; % 0.17;