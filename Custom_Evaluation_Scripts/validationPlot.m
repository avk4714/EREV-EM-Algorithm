% This script is used for plotting estimated fuel flow rate based net fuel
% consumption versus fuel tank level measurement

%% Add measurement data parameters here
rho = 0.783;        % grams/ml
t = bsfc_EEC_CS_CTLA.time_s;
measFuelLvl_L = bsfc_EEC_CS_CTLA.measFuelTankLvl_gal_1Hz * 3.785;

%% Add estimated data here
estFuelLvl_L = zeros(size(measFuelLvl_L));
estFuelLvl_L(1) = 4.41 * 3.785;
for i = 2:length(estFuelLvl_L)
    estFuelLvl_L(i) = estFuelLvl_L(i-1) - ((bsfc_EEC_CS_CTLA.est_mdot_fuelAdj_1Hz_gps(i)/rho) * 0.001);
end

%% Error Calculation
err = -estFuelLvl_L + measFuelLvl_L;
pct_err = (abs(err)./measFuelLvl_L) * 100;
mu_pct_err = mean(measFuelLvl_L);
rmse_pct_err = rms(err);
cv = (rmse_pct_err/mu_pct_err) * 100;
%% Plot
figure(1)
ax(1) = subplot(2,1,1);
scatter(t,measFuelLvl_L,'filled')
hold on
plot(t,estFuelLvl_L,'linewidth',2)
hold off
grid on
xlim([0 1218])
ylim([10 20])
ylabel('Remaining Fuel Level [liters]')
xlabel('Duration [seconds]')
%title('(a)')
legend('Measured Fuel Level','Estimated Fuel Level')

ax(2) = subplot(2,1,2);
stem(t,pct_err,'filled','g')
hold on
plot(t,cv * ones(size(t)),'-.r','linewidth',2)
hold off
grid on
xlim([0 1218])
ylabel('Percentage Error [%]')
xlabel('Duration [seconds]')
%title('(b)')
legend('Estimation Error','Coeff. of Variation')

linkaxes(ax,'x')

makePublishable(0)



