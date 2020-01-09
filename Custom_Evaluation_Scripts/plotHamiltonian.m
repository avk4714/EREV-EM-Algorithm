% Use this script to plot the hamiltonians for with and without REx
% operation.

figure()
ax(1) = subplot(1,2,1);
s1 = scatter(1:22,round(EEC_PMP_3.H_Total(663,:)*0.001,4),100,'filled');
ylabel('Hamiltonian [kW]')
xlabel('Element Number')
xlim([1 22])
xticks(1:1:22)
grid on
title('ESS Only: Co-State = 0')
%ax(1).YTickLabel = [];
s1.MarkerEdgeColor = 'b';
s1.MarkerFaceColor = 'b';
%legend('Co-state = 0')

ax(2) = subplot(1,2,2);
s2 = scatter(1:22,round(EEC_PMP_9.H_Total(663,:)*0.001,4),100,'filled');
ylabel('Hamiltonian [kW]')
xlabel('Element Number')
xlim([1 22])
xticks(1:1:22)
grid on
title('ESS + REx: Co-State = 4.44')
%ax(2).YTickLabel = [];
s2.MarkerEdgeColor = 'r';
s2.MarkerFaceColor = 'r';
%legend('Co-state = 3.76')

makePublishable(0)