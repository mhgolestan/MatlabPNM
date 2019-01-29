classdef Water < Fluids
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        viscosity = 0.001;
        sig_ow = 0.02;
        network;
        
        % Calculated properties
        waterArea;
        crossSectionArea;        
        conductance;
    end
    
    methods
        function obj = Water (network)
            obj = obj@Fluids('Water');
            obj.network = network;
        end
            
        function calculateConductance(obj)           
            for ii = 1:obj.network.numberOfNodes
                curvatureRadius = obj.sig_ow / obj.network.Nodes{ii}.thresholdPressure;
                b = zeros(1,4); % Meniscus-Apex distance
                if strcmp(obj.network.Nodes{ii}.geometry , 'Circle')== 1
                    obj.waterArea = 0;
                    obj.conductance = 0;
                else
                    dimenlessAreaCorner = zeros(1,4);
                    cornerShapeFactor = zeros(1,4);
                    scaledDimenlessConducCorner = zeros(1,4);
                    dimenlessConducCorner = zeros(1,4);
                    halfAngles = [obj.network.Nodes{ii}.halfAngle1, obj.network.Nodes{ii}.halfAngle2,...
                        obj.network.Nodes{ii}.halfAngle3, obj.network.Nodes{ii}.halfAngle4];
                    for jj = 1:4
                        if ~isnan(halfAngles(jj))
                            b(jj) = (curvatureRadius * cos(obj.network.Nodes{ii}.receedingContactAngle +...
                                halfAngles(jj)) / sin(halfAngles(jj)));
                            
                            if (halfAngles(jj) + obj.network.Nodes{ii}.receedingContactAngle) == pi/2
                                dimenlessAreaCorner(jj) = sin(halfAngles(jj))*cos(halfAngles(jj));
                                cornerShapeFactor(jj) = dimenlessAreaCorner(jj) /...
                                    (4 * (1 + sin(halfAngles(jj)))^2);
                            else
                                dimenlessAreaCorner(jj) = (sin(halfAngles(jj)) /...
                                    cos(obj.network.Nodes{ii}.receedingContactAngle + halfAngles(jj)))^2 *...
                                    ((cos(obj.network.Nodes{ii}.receedingContactAngle)*...
                                    cos(obj.network.Nodes{ii}.receedingContactAngle + halfAngles(jj)) /...
                                    sin(halfAngles(jj)))+ obj.network.Nodes{ii}.receedingContactAngle +...
                                    halfAngles(jj) - pi/2);
                                cornerShapeFactor(jj) = dimenlessAreaCorner(jj) /...
                                    (4 * (1 - (sin(halfAngles(jj)) / cos(halfAngles(jj)+...
                                    obj.network.Nodes{ii}.receedingContactAngle))*...
                                    (obj.network.Nodes{ii}.receedingContactAngle + halfAngles(jj) - pi/2))^2);
                            end
                            
                            scaledDimenlessConducCorner(jj) = -15.1794 * cornerShapeFactor(jj)^2 +...
                                7.6307 * cornerShapeFactor(jj) - 0.53488;
                            
                            dimenlessConducCorner(jj) = exp((scaledDimenlessConducCorner(jj) +...
                                0.02 * sin(halfAngles(jj) - pi/6)) / (1/4/pi - cornerShapeFactor(jj))^(7/8)...
                                / cos(halfAngles(jj) - pi/6)^0.5) * dimenlessAreaCorner(jj)^2;
                        end
                    end
                    obj.waterArea = sum(b.^2 .* dimenlessAreaCorner);
                    obj.network.Nodes{ii}.waterConductance = sum(2 * b.^4 .* dimenlessConducCorner / obj.viscosity);
                end
            end
            for ii = 1:obj.network.numberOfLinks
                curvatureRadius = obj.sig_ow / obj.network.Links{ii}.thresholdPressure;
                b = zeros(1,4); % Meniscus-Apex distance
                if strcmp(obj.network.Links{ii}.geometry , 'Circle')== 1
                    obj.waterArea = 0;
                    obj.conductance = 0;
                else
                    dimenlessAreaCorner = zeros(1,4);
                    cornerShapeFactor = zeros(1,4);
                    scaledDimenlessConducCorner = zeros(1,4);
                    dimenlessConducCorner = zeros(1,4);
                    halfAngles = [obj.network.Links{ii}.halfAngle1, obj.network.Links{ii}.halfAngle2,...
                        obj.network.Links{ii}.halfAngle3, obj.network.Links{ii}.halfAngle4];
                    for jj = 1:4
                        if ~isnan(halfAngles(jj))
                            b(jj) = (curvatureRadius * cos(obj.network.Links{ii}.receedingContactAngle +...
                                halfAngles(jj)) / sin(halfAngles(jj)));
                            
                            if (halfAngles(jj) + obj.network.Links{ii}.receedingContactAngle) == pi/2
                                dimenlessAreaCorner(jj) = sin(halfAngles(jj))*cos(halfAngles(jj));
                                cornerShapeFactor(jj) = dimenlessAreaCorner(jj) /...
                                    (4 * (1 + sin(halfAngles(jj)))^2);
                            else
                                dimenlessAreaCorner(jj) = (sin(halfAngles(jj)) /...
                                    cos(obj.network.Links{ii}.receedingContactAngle + halfAngles(jj)))^2 *...
                                    ((cos(obj.network.Links{ii}.receedingContactAngle)*...
                                    cos(obj.network.Links{ii}.receedingContactAngle + halfAngles(jj)) /...
                                    sin(halfAngles(jj)))+ obj.network.Links{ii}.receedingContactAngle +...
                                    halfAngles(jj) - pi/2);
                                cornerShapeFactor(jj) = dimenlessAreaCorner(jj) /...
                                    (4 * (1 - (sin(halfAngles(jj)) / cos(halfAngles(jj)+...
                                    obj.network.Links{ii}.receedingContactAngle))*...
                                    (obj.network.Links{ii}.receedingContactAngle + halfAngles(jj) - pi/2))^2);
                            end
                            
                            scaledDimenlessConducCorner(jj) = -15.1794 * cornerShapeFactor(jj)^2 +...
                                7.6307 * cornerShapeFactor(jj) - 0.53488;
                            
                            dimenlessConducCorner(jj) = exp((scaledDimenlessConducCorner(jj) +...
                                0.02 * sin(halfAngles(jj) - pi/6)) / (1/4/pi - cornerShapeFactor(jj))^(7/8)...
                                / cos(halfAngles(jj) - pi/6)^0.5) * dimenlessAreaCorner(jj)^2;
                        end
                    end
                    obj.waterArea = sum(b.^2 .* dimenlessAreaCorner);
                    obj.network.Links{ii}.waterConductance = sum(2 * b.^4 .* dimenlessConducCorner / obj.viscosity);
                end
            end
        end
    end
    
end

