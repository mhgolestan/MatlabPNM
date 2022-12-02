function calculateThresholdPressurePistonLike_drainage (element)
% Based on Blunt 2017
if strcmp(element.geometry , 'Circle')== 1
    element.drainThresholdPressure_PistonLike = 2*element.sig_ow *cos(element.recedingContactAngle)/element.radius;
else % eq 3.10 - 3.12
    D = pi - 2 / 3 * element.recedingContactAngle +3 * sin(element.recedingContactAngle) * cos(element.recedingContactAngle) - ...
        cos(element.recedingContactAngle)^2 / (4*element.shapeFactor);
    F_d = ( 1 + sqrt(1+4* element.shapeFactor * D / cos(element.recedingContactAngle)^2))/(1+2*sqrt(pi * element.shapeFactor));
    element.drainThresholdPressure_PistonLike = (element.sig_ow / element.radius)*...
        (1+2*sqrt(pi * element.shapeFactor))*cos(element.recedingContactAngle)* F_d;
end


