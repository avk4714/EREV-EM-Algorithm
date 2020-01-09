function [engEff,fuelRate] = calcEngEff(engPwrOut)
%CALCENGEFF Computes engine efficiency by interpolation from EffMap.
%   Input argument is the power output for the engine. Using interpolation
%   the engine efficiency is computed.
%   engPwrOut: Units are in Watts.
%   Engine efficiency map is computed and obtained from a different script.

%   [Function Update][10/17/19]: 
%   Adding fuel consumption rate in liters/second as an output.

%% Main Section

adjbsfc_spdbpt = [4003;4510;4987;5412;5800;5986;6322;6643;6889];
adjbsfc_trqbpt = [10;15;20;25;30;35;40;45;50];
LHV_E85 = 30000;    % [kJ/kg]
RHO_E85 = 783;      % [g/L]

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
adjbsfc_engPwrOut = adjbsfc_trqbpt * (adjbsfc_spdbpt' * 0.1047);    % Watts
[~,c_sz] = size(adjbsfc_engPwrOut);

if engPwrOut ~= 0
    
    % Interpolation Algorithm
    for i = 1:c_sz
        lim_pwr(i,1) = find(adjbsfc_engPwrOut(:,i) >= engPwrOut, 1 );           % Upper Limit
        if isempty(find(adjbsfc_engPwrOut(:,i) <= engPwrOut, 1, 'last' ))
            rat_interp = (engPwrOut - 0)...
                    /((adjbsfc_engPwrOut(lim_pwr(i,1),i)) - 0);
            eff(i,1) = 0 + ...
                    (rat_interp * ((adjbsfc_engeff(lim_pwr(i,1),i)) - 0));
        else
            lim_pwr(i,2) = find(adjbsfc_engPwrOut(:,i) <= engPwrOut, 1, 'last' );
            rat_interp = (engPwrOut - adjbsfc_engPwrOut(lim_pwr(i,2),i))...
                    /((adjbsfc_engPwrOut(lim_pwr(i,1),i)) - (adjbsfc_engPwrOut(lim_pwr(i,2),i)));
            eff(i,1) = adjbsfc_engeff(lim_pwr(i,2),i) + ...
                    (rat_interp * ((adjbsfc_engeff(lim_pwr(i,1),i)) - (adjbsfc_engeff(lim_pwr(i,2),i))));
        end

    end

    engEff = max(eff);  % Consider the maximum value - as that will be optimal.
    fuelRate = engPwrOut/(engEff * LHV_E85 * RHO_E85);
else
    engEff = 0;         % Can result in an Inf if in denominator in a script.
    fuelRate = 0;
end
    

end

