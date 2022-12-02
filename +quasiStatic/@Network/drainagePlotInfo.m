function drainagePlotInfo(network)
%% Fluid info
fprintf('===============================Ntework Information=====================================\n');
fprintf('Water Viscosity:                        %f \n', network.waterViscosity);
fprintf('Oil Viscosity:                          %f \n', network.oilViscosity);
fprintf('Interfacial Tension:                    %f \n', network.sig_ow);
fprintf('======================================================================================\n\n');

%==============================================================================================================
figure('name','MatlabPNM Cappilary Pressure & Relative Permeability Curves',...
    'units','normalized','outerposition',[0 0 1 1])
subplot(2,2,[1 3]);
plot(network.DrainageData(:,1),network.DrainageData(:,2),'-r')
legend('MatlabPNM Drainage','Location','North')
xlabel('Sw')
xlim([0 1])
% ylim([0 10000])
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

% figure
% plot(network.DrainageData(:,1),network.DrainageData(:,2),'-r')
% title('Drainage Cappilary Pressure Curves')
% xlabel('Sw')
% xlim([0 1])
% ylabel('Pc (Pa)')
% legend('Drainage Pc')