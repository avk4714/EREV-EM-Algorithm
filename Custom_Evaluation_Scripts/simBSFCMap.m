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

%% BSFC Points
% This BSFC data is constructed using the emissions data from ETE and is
% then manually adjusted to provide the best approximation.
op_lim = 50;        % Maximum torque limit on the engine
batpwr_lim = [50;45;40;35;35;35;30;30;30];
LHV_E85 = 30000;    % [kJ/kg]

adjbsfc_spdbpt = [4003;4510;4987;5412;5800;5986;6322;6643;6889];
adjbsfc_trqbpt = [10;15;20;25;30;35;40;45;50];
%{
adjbsfc_map = [3400 3275 3125 3040 2985 2945 2223 2918 3090;
               2885 2310 1750 1588 1051 1578 1331 1506 2121;
               1388 1134 883 895 886 1097 1002 1047 1085;
               1174 996 733 816 796 944 800 888 925;
               1085 780 618 694 673 705 745 765 790;
               895 579 554 582 573 590 625 640 655;
               602 566 678 465 415 385 NaN NaN NaN;
               501 390 360 348 NaN NaN NaN NaN NaN;
               445 388 NaN NaN NaN NaN NaN NaN NaN;
               390 NaN NaN NaN NaN NaN NaN NaN NaN];
%}
% BSFC units [g/kWh]
adjbsfc_map = [1051 1051 1051 1051 1051 1578 1331 1506 2121;
               1388 1134 883 895 886 1097 1002 1047 1047;
               1174 996 733 816 796 944 800 888 888;
               1085 780 618 694 673 673 673 673 673;
               895 579 554 582 573 573 573 573 573;
               602 566 678 465 415 385 385 385 385;
               501 390 360 348 NaN NaN NaN NaN NaN;
               388 388 NaN NaN NaN NaN NaN NaN NaN;
               388 NaN NaN NaN NaN NaN NaN NaN NaN];
           
adjbsfc_engeff = (3600000 ./ (adjbsfc_map * LHV_E85));           

adjbsfc_engPwrOut = adjbsfc_trqbpt * (adjbsfc_spdbpt' * 0.1047);           
%% Plots

% -- Torque Limit
figure()
%set(groot, 'defaultAxesTickLabelInterpreter','latex') 
%set(groot, 'defaultLegendInterpreter','latex')
plot(dynoVFR800.spd_rpm,dynoVFR800.trq_Nm,'linewidth',2.5,'color','k')
grid on
hold on
plot(dynoVFR800.spd_rpm,op_lim * ones(size(dynoVFR800.trq_Nm)),'--','linewidth',2,'color','k')
% --- Contour Map
[c1, h1] = contourf(adjbsfc_spdbpt,adjbsfc_trqbpt,adjbsfc_map,22,'ShowText','on');
h1.LevelList = round(h1.LevelList,0);
h1.LineWidth = 2;
clabel(c1,h1,'FontSize',12,'FontWeight','bold','Color','black')
colormap(jet)
caxis([300 1100])
clb = colorbar('eastoutside');
clb.Label.String = 'Brake Specific Fuel Consumption [g/kWh]';
%clb.Label.Interpreter = 'latex';
%clb.TickLabelInterpreter = 'latex';
% --- 
% --- Power Contour Map
[c2, h2] = contour(adjbsfc_spdbpt,adjbsfc_trqbpt,adjbsfc_engPwrOut*0.001*0.86,15,'-.w');
h2.LevelList = round(h2.LevelList,0);
h2.LineWidth = 2;
clabel(c2,h2,'FontSize',12,'FontWeight','bold','Color','white')
% ---
plot(adjbsfc_spdbpt,batpwr_lim,'-.','linewidth',2,'color','r')
hold off
xlim([min(adjbsfc_spdbpt) max(adjbsfc_spdbpt)])
ylim([10 77.54])

xlabel('Engine Speed [RPM]')
ylabel('Brake Torque [Nm]')
%title('Estimated VFR800 (E85 Fueled) BSFC Map [g/kWh]')
legend('Peak Brake Torque','Max. Torque Tested','Estimated BSFC','Battery Power Limit Torque')

makePublishable(0)

% % -- Additional Settings
% figP = gcf;
% axP = gca;
% 
% % -# Axes Settings
% axP.FontSize = 14;
% figP.Contour.LevelStep = 30;
% figP.Contour.LevelListMode = 'auto';
