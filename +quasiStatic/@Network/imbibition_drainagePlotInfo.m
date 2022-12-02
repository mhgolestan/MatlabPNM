function imbibition_drainagePlotInfo(network)
%% Fluid info
fprintf('===============================Ntework Information=====================================\n');
fprintf('Water Viscosity:                        %f \n', network.waterViscosity);
fprintf('Oil Viscosity:                          %f \n', network.oilViscosity);
fprintf('Interfacial Tension:                    %f \n', network.sig_ow);
fprintf('======================================================================================\n\n');

%==============================================================================================================
% figure('name','MatlabPNM Cappilary Pressure & Relative Permeability Curves',...
%     'units','normalized','outerposition',[0 0 1 1])
subplot(2,2,[1 3]);
hold on
plot(network.DrainageData(:,1),network.DrainageData(:,2),'-r')
hold on
plot(network.ImbibitionData(:,1),network.ImbibitionData(:,2),'-b')
legend(' Drainage',' Imbibition','Location','North')
xlabel('Sw')
xlim([0 1])
ylabel('Pc (Pa)')

subplot(2,2,2);
plot(network.DrainageData(:,1),network.DrainageData(:,3),'-b',network.DrainageData(:,1),network.DrainageData(:,4),'-r')
hold on
xlabel('Sw')
xlim([0 1])
ylabel('Reative Permeability')
ylim([0 1])
legend('Water Relative Permeability Drainage','Oil Relative Permeability Drainage','Location','North')
title('Drainage Relative Permeability Curves')

subplot(2,2,4);
plot(network.ImbibitionData(:,1),network.ImbibitionData(:,3),'-b',network.ImbibitionData(:,1),network.ImbibitionData(:,4),'-r')
hold on
xlabel('Sw')
xlim([0 1])
ylabel('Reative Permeability')
ylim([0 1])
legend('Water Relative Permeability Imbibition','Oil Relative Permeability Imbibition','Location','North')
title('Imbibition Relative Permeability Curves')
