% This script is used to develop the bsfc map for the 2002 Honda VFR800
% engine based on emission estimated fuel flow rate.

%% Dyno Performance Data 2002 VFR800 Engine

dynoVFR800.spd_rpm = [3000;3466;4003;4510;4987;5412;5800;5986;6322;6643; ...
                      6889;7015;7209;7560;7933;8283;8634;9007;9484;9648; ...
                      9924;10080;10356;10640;10819;10901;11139;11229;11318; ...
                      11445;11542;11654];
dynoVFR800.trq_Nm = [56.98;59.59;58.71;58.43;59.98;61.85;63.85;64.25;65.34;...
                     64.33;69.27;73.10;74.10;74.43;75.42;76.53;77.54;75.91;...
                     72.09;71.61;69.61;69.95;68.09;65.60;63.20;62.07;59.46;...
                     57.72;56.64;54.14;53.69;51.95];
dynoVFR800.pwr_kW = (dynoVFR800.trq_Nm .* (dynoVFR800.spd_rpm * 0.1047)) * 0.001;

%% Torque vs. Speed Plot
figure()
plot(dynoVFR800.spd_rpm,dynoVFR800.trq_Nm,'linewidth',3,'color','k')
xlabel('Engine Speed [RPM]')
ylabel('Engine Torque [N-m]')
grid on
xlim([3000 11650])
ylim([0 80])

