classdef Element<Fluids    
    properties
        % properties set from the link and node input files
        index
        radius
        shapeFactor
        volume
        clayVolume
        isInlet
        isOutlet
        
        % Calculated properties
        conductance %Element conductance
        geometry % geometrical shape of the element
        halfAngle1
        halfAngle2
        halfAngle3
        halfAngle4
        area
               
        waterCrossSectionArea
        oilCrossSectionArea
        gasCrossSectionArea 
        
        waterConductance
        oilConductance 
        gasConductance
        
        concentration = 0; 
        
        recedingContactAngle = 0;
        advancingContactAngle = 0; 
        
        waterPressure
        oilPressure
        gasPressure
        thresholdPressure % Capillary Threshold Pressure in Drainage
        occupancy = 'A';  % Element filled by Water
        
        ThresholdPressure_PistonLike = nan;
        ThresholdPressure_SnapOff = nan;
        ThresholdPressure_LayerCollapse = nan(1,4);
        oilLayerExist = nan;
        hingeAngles = nan(1,4);
    end    
    
    methods        
        %% Drainage
        %% Piston-Like
        function ThresholdPressure = calculateThresholdPressurePistonLike (obj, ContactAngle)
         % calculateThresholdPressurePistonLike Summary of this method goes here
         % Detailed explanation goes here  
         % Based ob Al-Futaisi & Patzek 2001: eqs 2-5
             if strcmp(obj.geometry , 'Circle')== 1
                 ThresholdPressure = 2*obj.sig_ow *cos(ContactAngle)/obj.radius;
             else                 
                 nominator = 0;
                 halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];
                 for j = 1:4
                     if ~isnan(halfAngles(j)) && halfAngles(j) < pi/2 - ContactAngle
                         E2 = cos(ContactAngle + halfAngles(j)) *...
                             cos(ContactAngle) / sin(halfAngles(j));
                         E0 = pi / 2 - ContactAngle - halfAngles(j);
                         nominator = nominator +  (E2 - E0);
                     end
                 end
                 ThresholdPressure = (obj.sig_ow / obj.radius)*...
                     cos(ContactAngle)*(1+sqrt(1 -(4*obj.shapeFactor*...
                     nominator)/(cos(ContactAngle)^2)));
             end
        end
        %% Imbibition
        %% Piston-Like & oilLayerExist
        function [ThresholdPressure_PistonLike, oilLayerExist] = calculateThresholdPressurePistonLike_Imbibition (obj, Pc_max_drainage, Pc)
       
         if strcmp(obj.geometry , 'Circle')== 1
                 % Based on Al-Futaisi&Patzek_2001: eqs 2-5 & Piri_2005: eq C4 
                 ThresholdPressure_PistonLike = 2*obj.sig_ow *cos(obj.advancingContactAngle)/obj.radius;
                 oilLayerExist = nan;
         else
             % Based on  Al-Futaisi&Patzek_2001: eqs 2-4 & 6-10             
             halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];             
             if strcmp(obj.geometry , 'Triangle')== 1
                 nc = 3;
             else
                 nc = 4;
             end
             b = zeros(nc,1); E0 = zeros(nc,1); E1 = zeros(nc,1); alpha = zeros(nc,1);hingeAngle = zeros(1,nc);
             nominator = 0;
             for i = 1:nc
                 if ~isnan(halfAngles(i))
                     nominator = nominator + cos(obj.recedingContactAngle + halfAngles(i));
                 end
             end
             maxAdvAngle = acos ((-4 * obj.shapeFactor * nominator)/...
                 ((obj.radius * Pc_max_drainage / obj.sig_ow) - cos(obj.recedingContactAngle)+...
                 4 * nc * obj.shapeFactor * sin(obj.recedingContactAngle)));             
             rpd = obj.sig_ow / Pc_max_drainage;             
             r_initialGuess = obj.sig_ow / Pc;
             
             if obj.advancingContactAngle <= maxAdvAngle % Spontaneous imbibition
                 rp1 = 2 * r_initialGuess;
                 rp2 = r_initialGuess;
                 while abs(rp2 - rp1) > 10^-10 % fixed point iteration method
                     rp1 = rp2;                                         
                     for ii = 1:nc
                         hingeAngle(ii) = min (acos((rpd / rp1)*cos(obj.recedingContactAngle + halfAngles(ii))) - halfAngles(ii), obj.advancingContactAngle);
                         if ~isnan(halfAngles(ii)) && hingeAngle(ii) <= obj.advancingContactAngle
                             b(ii) = rpd * cos(obj.recedingContactAngle + halfAngles(ii))/ sin(halfAngles(ii));
                             alpha(ii) = asin(b(ii)/rp1*sin(halfAngles(ii)));
                         elseif ~isnan(halfAngles(ii)) && hingeAngle(ii) > obj.advancingContactAngle                             
                             b(ii) = rp1 * cos(obj.advancingContactAngle + halfAngles(ii))/ sin(halfAngles(ii));
                             alpha(ii) = pi/2 - obj.advancingContactAngle - halfAngles(ii);
                         end                         
                         E0(ii) = pi/2 - hingeAngle(ii) - halfAngles(ii);
                         E1(ii) = b(ii) * cos(hingeAngle(ii)); 
                     end
                     rp2 = (obj.radius ^ 2 / 4 / obj.shapeFactor - rp1 * sum(E1) + rp1^2 * sum(E0))/...
                         (2*rp1 * sum(alpha) + (obj.radius/2/obj.shapeFactor - 2 * sum(b)) * cos(obj.advancingContactAngle));
                 end
                 obj.hingeAngles = hingeAngle;
                 ThresholdPressure_PistonLike = obj.sig_ow / rp2;
                 oilLayerExist = nan;
             elseif obj.advancingContactAngle > maxAdvAngle && obj.advancingContactAngle < pi/2 + max(halfAngles) % Forced imbibition
                 ThresholdPressure_PistonLike = 2 * obj.sig_ow * cos(obj.advancingContactAngle) / obj.radius;
                 oilLayerExist = nan;
             elseif obj.advancingContactAngle >= pi/2 + max(halfAngles) % Forced imbibition
                 ThresholdPressure_PistonLike = -calculateThresholdPressurePistonLike(obj, (pi - obj.advancingContactAngle));
                 oilLayerExist = 1;
             end
         end
        end 
        %% Snap-off
        function ThresholdPressure_SnapOff = calculateThresholdPressureSnapOff(obj,Pc_max_drainage)
         % calculateThresholdPressurePistonLike Summary of this method goes here
         % Detailed explanation goes here 
         if strcmp(obj.geometry , 'Circle')== 1
             ThresholdPressure_SnapOff = nan;
         else
             % Based on  Al-Futaisi&Patzek_2001: eqs 12-14          
             halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];             
             maxAdvAngle = pi/2 - min(halfAngles);
             if strcmp(obj.geometry , 'Triangle')== 1
                 nc = 3;
             else
                 nc = 4;
             end
             if obj.advancingContactAngle < maxAdvAngle
                 rso = zeros(1,nc);
                 for edge = 1:nc
                     rso1 = obj.sig_ow / Pc_max_drainage; 
                     rso2 = rso1*2;
                     while abs(rso1 - rso2) > 10^-10
                         rso1 = rso2;
                         ii = edge;
                         hingeAngle_ii = acos((obj.sig_ow / rso1)*...
                             cos(obj.recedingContactAngle + halfAngles(ii))/Pc_max_drainage) - halfAngles(ii);
                         theta_i = min(hingeAngle_ii , obj.advancingContactAngle);
                         E1_i = cos(theta_i + halfAngles(ii))/sin(halfAngles(ii));
                         if ii == nc
                             jj = 1;
                             hingeAngle_jj = acos((obj.sig_ow / rso1)*...
                                 cos(obj.recedingContactAngle + halfAngles(jj)) / Pc_max_drainage) - halfAngles(jj);
                             theta_j = min(hingeAngle_jj , obj.advancingContactAngle);
                             E1_j = cos(theta_j + halfAngles(jj)) / sin(halfAngles(jj));
                             rso2 = obj.radius *(cot(halfAngles(ii)) + cot(halfAngles(jj))) / (E1_i + E1_j);
                             rso(edge) = rso2;
                         else
                             jj = edge + 1;
                             hingeAngle_jj = acos((obj.sig_ow / rso1)*...
                                 cos(obj.recedingContactAngle + halfAngles(jj)) / Pc_max_drainage) - halfAngles(jj);
                             theta_j = min(hingeAngle_jj , obj.advancingContactAngle);
                             E1_j = cos(theta_j + halfAngles(jj)) / sin(halfAngles(jj));
                             rso2 = obj.radius *(cot(halfAngles(ii))+ cot(halfAngles(jj))) / (E1_i + E1_j);
                             rso(edge) = rso2;
                         end
                     end
                 end
                 ThresholdPressure_SnapOff = obj.sig_ow / min(rso);
             elseif obj.advancingContactAngle == maxAdvAngle
                 ThresholdPressure_SnapOff = 0;
             elseif obj.advancingContactAngle > maxAdvAngle && obj.advancingContactAngle < pi - min(halfAngles)
                 ThresholdPressure_SnapOff = Pc_max_drainage*cos(obj.advancingContactAngle + min(halfAngles))/...
                     cos(obj.recedingContactAngle + min(halfAngles));
             elseif obj.advancingContactAngle >= pi - min(halfAngles)
                 ThresholdPressure_SnapOff = -Pc_max_drainage/cos(obj.recedingContactAngle + min(halfAngles));
             end
         end
         
        end          
        %% LayerCollapse Piri_old
        function ThresholdPressure_LayerCollapse = calculateThresholdPressureLayerCollapse_ver1 (obj, Pc_max_drainage, Pc)
         % calculateThresholdPressurePistonLike Summary of this method goes here
         % Detailed explanation goes here  
         if strcmp(obj.geometry , 'Circle')== 1
             ThresholdPressure_LayerCollapse = nan(1,4);
         else
              halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4]; 
              if strcmp(obj.geometry , 'Triangle')== 1
                  nc = 3;
              elseif strcmp(obj.geometry , 'Square')== 1
                  nc = 4;
              end
              ThresholdPressure_LayerCollapse = nan(1,4);
              for i = 1:nc
                  if obj.advancingContactAngle > pi/2 + halfAngles(i) % convex oil layer is impossible
                      
                  obj.hingeAngles(i) = acos(Pc/Pc_max_drainage*cos(obj.recedingContactAngle + halfAngles(i))) - halfAngles(i);
                  b = obj.sig_ow * cos(obj.recedingContactAngle + halfAngles(i))/sin(halfAngles(i))/Pc_max_drainage;
                  ThresholdPressure_LayerCollapse(i) = obj.sig_ow *...
                      (3*(sin(halfAngles(i)))^2+ 4*sin(halfAngles(i))*cos(obj.advancingContactAngle)+(cos(obj.advancingContactAngle))^2)/...
                      (b*(cos(halfAngles(i))*sin(obj.advancingContactAngle)*(2*sin(halfAngles(i))+cos(obj.advancingContactAngle))+...
                      (sin(halfAngles(i)))^2 * ...
                      sqrt(4*(cos(halfAngles(i)))^2-3-(cos(obj.advancingContactAngle))^2-4*sin(halfAngles(i))*cos(obj.advancingContactAngle))));
                  end
              end
         end
        end
        %% LayerCollapse Piri-new
        function ThresholdPressure_LayerCollapse = calculateThresholdPressureLayerCollapse (obj, Pc_max_drainage, Pc)
         % calculateThresholdPressurePistonLike Summary of this method goes here
         % Detailed explanation goes here           
         
         if strcmp(obj.geometry , 'Circle')== 1
             ThresholdPressure_LayerCollapse = nan(1,4);
         else
              halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4]; 
              maxRadius = obj.sig_ow / Pc_max_drainage;              
              if strcmp(obj.geometry , 'Triangle')== 1
                  nc = 3;
              elseif strcmp(obj.geometry , 'Square')== 1
                  nc = 4;
              end
              b = zeros(nc , 1);
              ThresholdPressure_LayerCollapse = nan(1, 4);
              for i = 1:nc
                  obj.hingeAngles(i) = acos(abs(Pc/Pc_max_drainage)*cos(obj.recedingContactAngle + halfAngles(i))) - halfAngles(i);
                  b(i) = maxRadius * cos(obj.hingeAngles(i)+halfAngles(i))/sin(halfAngles(i));                      
                  ThresholdPressure_LayerCollapse(1,i) = obj.sig_ow *...
                      (3*(sin(halfAngles(i)))^2+ 4*sin(halfAngles(i))*cos(obj.hingeAngles(i))+(cos(obj.hingeAngles(i)))^2)/...
                      (b(i)*(cos(halfAngles(i))*sin(obj.hingeAngles(i))*(2*sin(halfAngles(i))+cos(obj.hingeAngles(i)))+...
                      (sin(halfAngles(i)))^2 * ...
                      sqrt(abs(4*(cos(halfAngles(i)))^2-3-(cos(obj.hingeAngles(i)))^2-4*sin(halfAngles(i))*cos(obj.hingeAngles(i))))));                 
              end
              
         end
        end        
        %% Conductance Calculation _ Drainage
         function [waterCrossSectionArea, waterConductance, oilCrossSectionArea, oilConductance] = ...
                 calculateConductance_Drainage(obj, Pc, contactAngle)   
             if obj.occupancy == 'B' %element was occupied by oil
                 halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];
                 cornerArea = zeros(1,4);
                 cornerConductance = zeros(1,4);
                 %Raduis of Curvature
                 Rc = obj.sig_ow / abs(Pc);
                 for jj = 1:4
                     if ~isnan(halfAngles(jj))
                         % Area
                         % Based on Piri_2005: eq A4 & A5 
                         if (halfAngles(jj) + contactAngle) == pi/2
                             cornerArea(jj) = (Rc * cos(contactAngle + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                                 sin(halfAngles(jj)) * cos(halfAngles(jj));
                         else
                             cornerArea(jj) = Rc ^2 * (cos(contactAngle)*...
                                 (cot(halfAngles(jj)) * cos(contactAngle) - sin(contactAngle))+ ...
                                 contactAngle + halfAngles(jj) - pi/2);
                         end
                         %Conductance
                         % Based on Piri_2005: eq B(10 - 15)
                         f = 1; % no-flow boundary condition suitable for oil-water interfaces
                         F1 = pi/2 - halfAngles(jj) - contactAngle;
                         F2 = cot(halfAngles(jj)) * cos(contactAngle) - sin(contactAngle); 
                         F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
                         
                         if (contactAngle <= pi/2 - halfAngles(jj))  % Positive Curvature                       
                             cornerConductance(jj) = (cornerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                                 (F2 * cos(contactAngle) - F1) * F3 ^ 2) / ...
                                 (12 * obj.waterViscosity * ((sin(halfAngles(jj))) * ...
                                 (1 - F3) * (F2 + f * F1))^ 2);
                         elseif (contactAngle > pi/2 - halfAngles(jj)) % Negative Curvature
                             cornerConductance(jj) = (cornerArea(jj)^2 * tan(halfAngles(jj))* ...
                                 (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                                 (12 * obj.waterViscosity *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
                         end
                     end
                     waterCrossSectionArea = sum(cornerArea);
                     if waterCrossSectionArea>obj.area
                         waterCrossSectionArea = obj.area;
                     end
                     waterConductance = sum(cornerConductance);
                 end
                 oilCrossSectionArea = obj.area - waterCrossSectionArea;
                 if strcmp(obj.geometry , 'Circle')== 1
                     oilConductance = oilCrossSectionArea^2 * 0.5 * obj.shapeFactor /obj.oilViscosity;
                 elseif strcmp(obj.geometry , 'Triangle')== 1
                     oilConductance = oilCrossSectionArea^2 * 3  * obj.shapeFactor / obj.oilViscosity/5;
                 elseif strcmp(obj.geometry , 'Square')== 1
                     oilConductance = oilCrossSectionArea^2 *0.5623 * obj.shapeFactor /obj.oilViscosity;
                 end
             else
                 waterCrossSectionArea = obj.area;
                 waterConductance = obj.conductance; 
                 oilCrossSectionArea = 0;
                 oilConductance = 0; 
             end
         end         
          %% Conductance Calculation _ Imbibition
         function [waterCrossSectionArea, waterConductance, oilCrossSectionArea, oilConductance] =...
                 calculateConductance_Imbibition(obj, network, Pc)
             Pc = abs(Pc);
             
             if isnan(obj.oilLayerExist) %&& obj.occupancy == 'A'
                 
              if obj.occupancy == 'B' %element was occupied by oil
                 halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];
                 cornerArea = zeros(1,4);
                 cornerConductance = zeros(1,4);
                 %Raduis of Curvature
                 if strcmp(obj.geometry , 'Circle')== 1
                     Rc = 0;
                 else
                     % Based on  Al-Futaisi&Patzek_2001: eqs 2-4 & 6-10
                     halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];             
                     if strcmp(obj.geometry , 'Triangle')== 1
                         nc = 3;
                     else
                         nc = 4;
                     end
                     b = zeros(nc,1); E0 = zeros(nc,1); E1 = zeros(nc,1); alpha = zeros(nc,1);hingeAngle = zeros(1,nc);
                     nominator = 0;
                     for i = 1:nc
                         if ~isnan(halfAngles(i))
                             nominator = nominator + cos(obj.recedingContactAngle + halfAngles(i));
                         end
                     end
                     maxAdvAngle = acos ((-4 * obj.shapeFactor * nominator)/...
                         ((obj.radius * network.Pc_drain_max / obj.sig_ow) - cos(obj.recedingContactAngle)+...
                         4 * nc * obj.shapeFactor * sin(obj.recedingContactAngle)));             
                     rpd = obj.sig_ow / network.Pc_drain_max;             
                     r_initialGuess = obj.sig_ow / Pc;
                     
                     if obj.advancingContactAngle <= maxAdvAngle % Spontaneous imbibition
                         rp1 = 2 * r_initialGuess;
                         rp2 = r_initialGuess;
                         while abs(rp2 - rp1) > 10^-10 % fixed point iteration method
                             rp1 = rp2;                                         
                             for ii = 1:nc
                                 hingeAngle(ii) = min (acos((rpd / rp1)*cos(obj.recedingContactAngle + halfAngles(ii))) - halfAngles(ii), obj.advancingContactAngle);
                                 if ~isnan(halfAngles(ii)) && hingeAngle(ii) <= obj.advancingContactAngle
                                     b(ii) = rpd * cos(obj.recedingContactAngle + halfAngles(ii))/ sin(halfAngles(ii));
                                     alpha(ii) = asin(b(ii)/rp1*sin(halfAngles(ii)));
                                 elseif ~isnan(halfAngles(ii)) && hingeAngle(ii) > obj.advancingContactAngle                             
                                     b(ii) = rp1 * cos(obj.advancingContactAngle + halfAngles(ii))/ sin(halfAngles(ii));
                                     alpha(ii) = pi/2 - obj.advancingContactAngle - halfAngles(ii);
                                 end
                                 E0(ii) = pi/2 - hingeAngle(ii) - halfAngles(ii);
                                 E1(ii) = b(ii) * cos(hingeAngle(ii)); 
                             end
                             rp2 = (obj.radius ^ 2 / 4 / obj.shapeFactor - rp1 * sum(E1) + rp1^2 * sum(E0))/...
                                 (2*rp1 * sum(alpha) + (obj.radius/2/obj.shapeFactor - 2 * sum(b)) * cos(obj.advancingContactAngle));
                         end
                         obj.hingeAngles = hingeAngle;
                         Rc = rp2;
                     end
                 end 
                 for jj = 1:4
                     if ~isnan(halfAngles(jj))
                         contactAngle = obj.hingeAngles(jj);
                         % Area
                         % Based on Piri_2005: eq A4 & A5 
                         if (halfAngles(jj) + contactAngle) == pi/2
                             cornerArea(jj) = (Rc * cos(contactAngle + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                                 sin(halfAngles(jj)) * cos(halfAngles(jj));
                         else
                             cornerArea(jj) = Rc ^2 * (cos(contactAngle)*...
                                 (cot(halfAngles(jj)) * cos(contactAngle) - sin(contactAngle))+ ...
                                 contactAngle + halfAngles(jj) - pi/2);
                         end
                         %Conductance
                         % Based on Piri_2005: eq B(10 - 15)
                         f = 1; % no-flow boundary condition suitable for oil-water interfaces
                         F1 = pi/2 - halfAngles(jj) - contactAngle;
                         F2 = cot(halfAngles(jj)) * cos(contactAngle) - sin(contactAngle); 
                         F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));
                         
                         if (contactAngle <= pi/2 - halfAngles(jj))  % Positive Curvature                       
                             cornerConductance(jj) = (cornerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                                 (F2 * cos(contactAngle) - F1) * F3 ^ 2) / ...
                                 (12 * obj.waterViscosity * ((sin(halfAngles(jj))) * ...
                                 (1 - F3) * (F2 + f * F1))^ 2);
                         elseif (contactAngle > pi/2 - halfAngles(jj)) % Negative Curvature
                             cornerConductance(jj) = (cornerArea(jj)^2 * tan(halfAngles(jj))* ...
                                 (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                                 (12 * obj.waterViscosity *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
                         end
                     end
                     waterCrossSectionArea = sum(cornerArea);
                     if waterCrossSectionArea>obj.area
                         waterCrossSectionArea = obj.area;
                     end
                     waterConductance = sum(cornerConductance);
                 end
                 oilCrossSectionArea = obj.area - waterCrossSectionArea;
                 if strcmp(obj.geometry , 'Circle')== 1
                     oilConductance = oilCrossSectionArea^2 * 0.5 * obj.shapeFactor /obj.oilViscosity;
                 elseif strcmp(obj.geometry , 'Triangle')== 1
                     oilConductance = oilCrossSectionArea^2 * 3  * obj.shapeFactor / obj.oilViscosity/5;
                 elseif strcmp(obj.geometry , 'Square')== 1
                     oilConductance = oilCrossSectionArea^2 *0.5623 * obj.shapeFactor /obj.oilViscosity;
                 end
             else
                 waterCrossSectionArea = obj.area;
                 waterConductance = obj.conductance; 
                 oilCrossSectionArea = 0;
                 oilConductance = 0; 
             end
                 
             elseif ~isnan(obj.oilLayerExist)
                 if strcmp(obj.geometry , 'Triangle')== 1
                     nc = 3;
                 else
                     nc = 4;
                 end
                 
                 R = network.sig_ow / Pc; %Raduis of Curvature
                 halfAngles = [obj.halfAngle1, obj.halfAngle2,obj.halfAngle3, obj.halfAngle4];
                 inerArea = zeros(1,nc);
                 outerArea = zeros(1,nc);
                 layerArea = zeros(1,nc);
                 inerConductance = zeros(1,nc);
                 layerConductance = zeros(1,nc);
                 for jj = 1:nc
                     if ~isnan(obj.ThresholdPressure_LayerCollapse(1,jj)) %if the layer exist in the corner
                         
                         R_min = network.sig_ow / network.Pc_drain_max;
                         bi = R_min * cos(obj.recedingContactAngle+halfAngles(jj))/sin(halfAngles(jj));
                         thetaHingRec = acos(bi*sin(halfAngles(jj))/R)-halfAngles(jj);
                         
                         if thetaHingRec > obj.advancingContactAngle
                             thetaHingRec = obj.advancingContactAngle;
                         end
                         % Area of corner water
                         if (halfAngles(jj) + thetaHingRec) == pi/2
                             inerArea(jj) = (R * cos(thetaHingRec + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                                 sin(halfAngles(jj)) * cos(halfAngles(jj));
                         else
                             inerArea(jj) = R ^2 * (cos(thetaHingRec)*...
                                 (cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec))+ ...
                                 thetaHingRec+ halfAngles(jj) - pi/2);
                         end
                         % Conductance of corner water
                         if thetaHingRec <= pi/2 - halfAngles(jj) % Positive Curvature       
                             f = 1; % no-flow boundary condition suitable for oil-water interfaces
                             F1 = pi/2 - halfAngles(jj) - thetaHingRec;
                             F2 = cot(halfAngles(jj)) * cos(thetaHingRec) - sin(thetaHingRec); 
                             F3 = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));  
                             
                             inerConductance(jj) = (inerArea(jj)^2 * (1 - sin(halfAngles(jj)))^2 * ...
                                 (F2 * cos(thetaHingRec) - F1) * F3 ^ 2) / ...
                                 (12 * network.waterViscosity * ((sin(halfAngles(jj))) * ...
                                 (1 - F3) * (F2 + f * F1))^ 2);
                         elseif (thetaHingRec > pi/2 - halfAngles(jj)) % Negative Curvature
                             inerConductance(jj) = (inerArea(jj)^2 * tan(halfAngles(jj))* ...
                                 (1 - sin(halfAngles(jj)))^2 * F3 ^ 2) / ...
                                 (12 * network.waterViscosity *(sin(halfAngles(jj)))^2*(1 - F3) * (1 + f * F3)^ 2);
                         end
                         thetaHingAdv = pi - obj.advancingContactAngle;
                         if (halfAngles(jj) + thetaHingAdv) == pi/2
                             outerArea(jj) = (R * cos(thetaHingAdv + halfAngles(jj))/ sin (halfAngles(jj)))^2 *...
                                 sin(halfAngles(jj)) * cos(halfAngles(jj));
                         else
                             outerArea(jj) = R ^2 * (cos(thetaHingAdv)*...
                                 (cot(halfAngles(jj)) * cos(thetaHingAdv) - sin(thetaHingAdv))+ ...
                                 thetaHingAdv+ halfAngles(jj) - pi/2);
                         end
                         % Area of oil layer
                         layerArea(jj) = outerArea(jj)-inerArea(jj);
                         % Conductance of oil layer
                         F3_layer = (pi/2 - halfAngles(jj)) * tan(halfAngles(jj));  
                         layerConductance(jj) = (layerArea(jj)^3 * (1 - sin(halfAngles(jj)))^2 * ...
                             tan(halfAngles(jj)) * F3_layer ^ 2) / ...
                             (12 * network.oilViscosity *outerArea(jj)* (sin(halfAngles(jj)))^2 * ...
                             (1 - F3_layer) * (1 + F3_layer - (1- F3) * sqrt(inerArea(jj)/outerArea(jj))));
                     end
                 end
                 % Center water area and conductance
                 centerWaterArea = obj.area - sum(outerArea);
                 if strcmp(obj.geometry , 'Circle')== 1
                     centerWaterConductance = 0.5 * obj.shapeFactor * centerWaterArea^2/network.waterViscosity;
                 elseif strcmp(obj.geometry , 'Triangle')== 1
                     centerWaterConductance = 3 *obj.radius^2*centerWaterArea/20/network.waterViscosity;
                 else
                     
                     centerWaterConductance = 0.5623 * obj.shapeFactor * centerWaterArea^2/network.waterViscosity;
                 end
                 
                 waterCrossSectionArea = obj.area - sum(layerArea);
                 waterConductance = centerWaterConductance + sum(inerConductance);
                 oilCrossSectionArea = sum(layerArea);
                 oilConductance = sum(layerConductance);
             end
         end   
    end
end

