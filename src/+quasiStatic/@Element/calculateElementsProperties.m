function calculateElementsProperties(element)
% Geometry and conductance specification of the elements is
% based of : Patzek, T. W., & Silin, D. B. (2001). Shape factor and hydraulic conductance in noncircular capillaries: I. One-phase creeping flow. Journal of Colloid and Interface Science. https://doi.org/10.1006/jcis.2000.7413
% For ducts with square cross-sections, all four half-angles are equal to /4? and G = 1/16 . Circular ducts have no corners and G =1/ 4? . For simplicity, all ducts with shape factors between those of equilateral triangle and square can be mapped onto squares, and those with shape factors above 1/16 onto circles.
% we'd better to insert star shapes later
if  element.shapeFactor <= sqrt(3) / 36
    element.shapeFactor = max(element.shapeFactor, 10^-7);
    element.geometry = 'Triangle';
    betha2_min = atan((2 / sqrt(3)) * cos((acos(-12 * sqrt(3) * element.shapeFactor)) / 3 + (4 * pi / 3)));
    betha2_max = atan((2 / sqrt(3)) * cos((acos(-12 * sqrt(3) * element.shapeFactor)) / 3 ));
    % rand(0.25-0.75)
    rand_1 = 0.5*(rand+0.5);
    element.halfAngle2 = betha2_min + rand_1 * (betha2_max - betha2_min);
    element.halfAngle1 = -0.5 * element.halfAngle2 + 0.5 * asin((tan(element.halfAngle2) + 4 * element.shapeFactor) * sin(element.halfAngle2) / (tan(element.halfAngle2) - 4 * element.shapeFactor));
    element.halfAngle3 = pi / 2 - element.halfAngle1 - element.halfAngle2;
    element.halfAngle4 = nan;
    element.area = element.radius^2/4/element.shapeFactor;
    element.conductanceSinglePhase = 3 * element.area^2 * element.shapeFactor / 5 / element.wettingPhase_Viscosity_PaS; % Here it should be viscosity be divided, I think. 29.02.2024
    element.crossSectionShape = 1;
elseif element.shapeFactor > sqrt(3) / 36 && element.shapeFactor <= 1 / 16
    element.geometry = 'Square';
    element.halfAngle1 = pi / 4;
    element.halfAngle2 = pi / 4;
    element.halfAngle3 = pi / 4;
    element.halfAngle4 = pi / 4;
    element.area = 4*element.radius^2;
    element.conductanceSinglePhase = 0.5623 * element.area^2 * element.shapeFactor / element.wettingPhase_Viscosity_PaS ;
    element.crossSectionShape = 2;
elseif element.shapeFactor > 1 / 16
    element.geometry = 'Circle';
    element.halfAngle1 = nan;
    element.halfAngle2 = nan;
    element.halfAngle3 = nan;
    element.halfAngle4 = nan;
    element.area = pi*element.radius^2;
    element.conductanceSinglePhase = 0.5 * element.area^2 * element.shapeFactor / element.wettingPhase_Viscosity_PaS ;
    element.crossSectionShape = 4;
end
if element.volume == 0
    element.volume = element.area * element.length;
end
end
          
