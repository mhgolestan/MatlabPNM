% Flow & ReactiveTransport Based on Raoof's paper 2010
function calculateReactiveTransport_SinglePhaseDesorption(network, inletPressure, outletPressure, soluteConcentration, poreVolumeSimulation, poreVolumeInjected)

% calculate pressure distribution
pressureDistribution_singlePhaseFlow_Cylindrical (network, inletPressure, outletPressure);

% mass transfer coefficient: alpha & distribution coefficient: K_d
k_d = 0.0001 * ones(network.numberOfLinks,1); % det
alpha = zeros(network.numberOfLinks,1); % det
K_d = zeros(network.numberOfLinks,1); % att/det
network.capillaryNumber = 1;
network.pecletNumber = 1;

residenceTime_link = zeros(network.numberOfLinks,1);
flowRate_link = zeros(network.numberOfLinks,1);
velocity_link = zeros(network.numberOfLinks,1);
network.totalFlowRate = 0;
effectiveDiffusion = 1e-9;

% calculate flowrate of links residence time
for ii = 1:network.numberOfLinks
    
    node1Index = network.Links{ii}.pore1Index;
    node2Index = network.Links{ii}.pore2Index;
    
    if ~network.Links{ii}.isInlet && ~network.Links{ii}.isOutlet
        
        % calculate the flow rate of the fluid
        flowRate_link(ii) = network.Links{ii}.cylindricalConductanceSinglePhase * ...
            abs(network.Nodes{node1Index}.waterPressure - ...
            network.Nodes{node2Index}.waterPressure);
        
    elseif network.Links{ii}.isInlet
        
        % calculate the flow rate of the fluid
        flowRate_link(ii) = network.Links{ii}.cylindricalConductanceSinglePhase * ...
            abs(inletPressure - ...
            network.Nodes{node2Index}.waterPressure);
    else
        
        % calculate the flow rate of the fluid
        flowRate_link(ii) = network.Links{ii}.cylindricalConductanceSinglePhase * ...
            abs(network.Nodes{node1Index}.waterPressure - ...
            outletPressure);
        network.totalFlowRate = network.totalFlowRate + flowRate_link(ii);
    end
    velocity_link(ii) = flowRate_link(ii)*network.Links{ii}.area;
    residenceTime_link(ii) = network.Links{ii}.volume/flowRate_link(ii);
    k_att = 4 * ( 1 - exp(-3* k_d(ii)/network.Links{ii}.radius))*velocity_link(ii) ^ 0.05 * effectiveDiffusion ^ 0.95 /...
        network.Links{ii}.radius ^ 1.95;
    k_det = 9 * velocity_link(ii) ^ 0.05 * effectiveDiffusion ^ 0.95 /...
        ((0.5 + 4.5 * k_d(ii) / network.Links{ii}.radius) * network.Links{ii}.radius ^ 1.95);
    alpha(ii) = k_det;
    K_d(ii) = k_att / k_det;
end

timeStep = min(nonzeros(residenceTime_link));
% timeStep = timeStep *100;

% for perfect mixing must be less than 1: diffusion is dominant
% rather than advection
network.pecletNumber = network.xDimension * network.velocity / effectiveDiffusion;

B = zeros(network.numberOfLinks,1);
F = zeros(network.numberOfLinks,1);
G = zeros(network.numberOfLinks,1);
H = zeros(network.numberOfLinks,1);
for i = 1:network.numberOfLinks
    
    B(i) = 1 + ...
        (flowRate_link(i) * timeStep /network.Links{i}.volume) + ...
        (timeStep * alpha(i) * K_d(i)) - ...
        (timeStep^2 * (alpha(i))^2 * K_d(i))/(1 + timeStep * alpha(i));
    F(i) = 1 / B(i) * (flowRate_link(i))^2 * timeStep / network.Links{i}.volume;
    G(i) = flowRate_link(i) /  B(i);
    H(i) = flowRate_link(i) * timeStep * alpha(i)/ (B(i)*(1 + timeStep * alpha(i)));
end

flowRate_node = zeros(network.numberOfNodes,1);
E = zeros(network.numberOfNodes,1);
I = zeros(network.numberOfNodes,1);
for i = 1:network.numberOfNodes
    
    I(i) = timeStep / network.Nodes{i}.volume;
    for j = 1:network.Nodes{i}.connectionNumber
        
        connectedLinkIndex = network.Nodes{i}.connectedLinks(j);
        connectedNodeIndex = network.Nodes{i}.connectedNodes(j);
        
        % determine link flowing into this node
        if connectedNodeIndex ~= 0 && connectedNodeIndex ~= -1
            
            if network.Nodes{connectedNodeIndex}.waterPressure > network.Nodes{i}.waterPressure
                flowRate_node(i) = flowRate_node(i) + flowRate_link(connectedLinkIndex);
            end
            
        elseif connectedNodeIndex == -1
            flowRate_node(i) = flowRate_node(i) + flowRate_link(connectedLinkIndex);
        end
    end
    
    E(i) = 1+ timeStep * flowRate_node(i) / network.Nodes{i}.volume;
end

% calculation of 3 Unknowns (concentration of nodes & concentration and adsorption of links) in each timeStep

t = 0;
time = 0;
simulationTime = poreVolumeSimulation / network.totalFlowRate;
injectionTime = poreVolumeInjected / network.totalFlowRate;

fprintf('TimePV %3.5f\n',network.poreVolume/network.totalFlowRate);
fprintf('simulationTime %3.5f\n',simulationTime);
fprintf('injectionTime %3.5f\n',injectionTime);
fprintf('injectionT  %3.5f\n',round(injectionTime/timeStep)+1);

% Plot & Animation
figure('name','BTC')
title('Break Through Curve')
xlabel('Time(s)')
ylabel('DimensionlessConcentration(-)')
h = animatedline;
h.Color = 'b';
h.LineStyle = '-';
h.LineWidth = 2;
axis([0 simulationTime 0 1])

timePlot = zeros(round(simulationTime/timeStep)+1 ,1);
flux_averagedConcentration = zeros(round(simulationTime/timeStep)+1 ,1);
network.BreakThroughCurve_singlePhase = zeros(round(simulationTime/timeStep)+1 ,2);
soluteConcentration1 = soluteConcentration;

while time < simulationTime
    
    if time > injectionTime
        soluteConcentration = 0;
    end
    
    t = t+1;
    time = time + timeStep;
    timePlot(t) = time;
    sumOfConcentration = 0;
    sumOfFlowRate = 0;
    
    Factor = zeros(network.numberOfNodes, network.numberOfNodes);
    Known = zeros(network.numberOfNodes, 1);
    
    % calculate concentration of nodes: based on eq.7
    for i = 1:network.numberOfNodes
        
        for j = 1:network.Nodes{i}.connectionNumber
            
            connectedLinkIndex = network.Nodes{i}.connectedLinks(j);
            connectedNodeIndex = network.Nodes{i}.connectedNodes(j);
            adsorbedConcentration = network.Links{connectedLinkIndex}.adsorbedConcentration(t);
            linksConcentration = network.Links{connectedLinkIndex}.concentration(t);
            
            if connectedNodeIndex ~= 0 && connectedNodeIndex ~= -1
                
                % determine link flowing into this node
                if network.Nodes{connectedNodeIndex}.waterPressure > network.Nodes{i}.waterPressure
                                         
                    Factor(i, connectedNodeIndex) = -I(i) * F(connectedLinkIndex);
                    Known(i,1) = Known(i,1) +...
                        G(connectedLinkIndex) * linksConcentration + H(connectedLinkIndex) * adsorbedConcentration;
                end
            elseif connectedNodeIndex == -1
                                
                Known(i,1) = Known(i,1) + ...
                    G(connectedLinkIndex) * linksConcentration + H(connectedLinkIndex) * adsorbedConcentration + ...
                    F(connectedLinkIndex) * soluteConcentration;
            end
        end
        Factor(i, i) = E(i);
        Known(i,1) = network.Nodes{i}.concentration(t) + I(i) * Known(i,1);
    end
    
    nodesConcentration_new = gmres(Factor, Known,[], 1e-10, network.numberOfNodes);
    
    % asign new concentration of nodes
    for i = 1:network.numberOfNodes
        if nodesConcentration_new(i) > soluteConcentration1
            network.Nodes{i}.concentration(t+1) = soluteConcentration1;
        else
            network.Nodes{i}.concentration(t+1) = nodesConcentration_new(i);
        end
    end
    
    % calculate new concentration & adsorbedConcentration of links:
    % based on eq.3&4
    for i = 1:network.numberOfLinks
        
        node1Index = network.Links{i}.pore1Index;
        node2Index = network.Links{i}.pore2Index;
        
        if ~network.Links{i}.isInlet && ~network.Links{i}.isOutlet
            if network.Nodes{node1Index}.waterPressure > network.Nodes{node2Index}.waterPressure
                upstreamNode = node1Index;
            else
                upstreamNode = node2Index;
            end
            network.Links{i}.concentration(t+1) = 1/ B(i)*(network.Links{i}.concentration(t) + ...
                timeStep * alpha(i) * network.Links{i}.adsorbedConcentration(t) / ...
                (1 + alpha(i) * timeStep) + ...
                flowRate_link(i) * timeStep * network.Nodes{upstreamNode}.concentration(t+1)/...
                network.Links{i}.volume);
        elseif network.Links{i}.isInlet
            network.Links{i}.concentration(t+1) = 1/ B(i)*(network.Links{i}.concentration(t)+ ...
                timeStep * alpha(i) * network.Links{i}.adsorbedConcentration(t) / ...
                (1 + alpha(i) * timeStep) + ...
                flowRate_link(i) * timeStep * soluteConcentration/network.Links{i}.volume);
        else
            network.Links{i}.concentration(t+1) = 1/ B(i)*(network.Links{i}.concentration(t) + ...
                timeStep * alpha(i) * network.Links{i}.adsorbedConcentration(t) / ...
                (1 + alpha(i) * timeStep) + ...
                flowRate_link(i) * timeStep * network.Nodes{node1Index}.concentration(t+1)/...
                network.Links{i}.volume);
            
            % calculation for BreakThroughCurve at outlet of network
            sumOfConcentration = sumOfConcentration + ...
                network.Links{i}.concentration(t+1)*flowRate_link(i);
            sumOfFlowRate = sumOfFlowRate + flowRate_link(i);
        end
        network.Links{i}.adsorbedConcentration(t+1) = (alpha(i) * timeStep * K_d(i) * ...
            network.Links{i}.concentration(t+1)+ network.Links{i}.adsorbedConcentration(t))/...
            (1 + alpha(i) * timeStep);
    end
    % calculate BreakThroughCurve at outlet of network
    flux_averagedConcentration(t) = sumOfConcentration / sumOfFlowRate / soluteConcentration1;
    
    % Plot & Animation
    addpoints(h,timePlot(t),flux_averagedConcentration(t));
    drawnow
    
    network.BreakThroughCurve_singlePhase(t,1) = timePlot(t);
    network.BreakThroughCurve_singlePhase(t,2) = flux_averagedConcentration(t);
    
        if mod(t,10)==0
            network.visualization('Desorption',t);
        end
end

% Plot
plot(network.BreakThroughCurve_singlePhase(:,1),network.BreakThroughCurve_singlePhase(:,2),'*');
end