function calculateThresholdPressurePistonLike_Imbibition(element, Pc_max_drainage)

if strcmp(element.geometry , 'Circle')== 1
    % Based on Al-Futaisi&Patzek_2001: eqs 2-5 & Piri_2005: eq C4
    element.imbThresholdPressure_PistonLike = 2*element.IFT_NperMeter *cos(element.advancingContactAngle)/element.radius;
    element.nonWettingLayerExist(1,:) = nan;
else
    % Based on  Al-Futaisi&Patzek_2001: eqs 2-4 & 6-10
    halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];
    if strcmp(element.geometry , 'Triangle')== 1
        nc = 3;
    else
        nc = 4;
    end
    
    nominator = 0;
    for i = 1:nc
        if ~isnan(halfAngles(i))
            nominator = nominator + cos(element.recedingContactAngle + halfAngles(i));
        end
    end
    a = (-4 * element.shapeFactor * nominator)/...
        ((element.radius * Pc_max_drainage / element.IFT_NperMeter) - cos(element.recedingContactAngle)+...
        12 * element.shapeFactor * sin(element.recedingContactAngle));
    if a >1
        a = 1;
    elseif a< -1
        a = -1;
    end
    maxAdvAngle = acos (a);
    
    if element.advancingContactAngle <= maxAdvAngle % Spontaneous imbibition
        
        maxIteration = 5000;it = 0;
        rpd = element.IFT_NperMeter / Pc_max_drainage;
        NR = 0;
        E0 = zeros(nc,1); E1 = zeros(nc,1); alpha = zeros(nc,1);hingingAngles = zeros(1,nc);b_i=zeros(1,nc);
        rp1 =rpd*2;
        rp2 = rpd;
        while abs(rp2 - rp1) > 10^-10 && NR == 0 % fixed point iteration method
            rp1 = rp2;
            for ii = 1:nc
                t = (rpd / rp1)*cos(element.recedingContactAngle + halfAngles(ii));
                if t > 1 && t >= -1
                    t = 1;
                elseif t < -1
                    t = -1;
                end
                hingingAngles(ii) = acos(t) - halfAngles(ii);
                %
                if ~isnan(halfAngles(ii)) && hingingAngles(ii) <= element.advancingContactAngle
                    b_i(ii) = rpd * cos(element.recedingContactAngle + halfAngles(ii))/ sin(halfAngles(ii));
                    part = b_i(ii)/rp1*sin(halfAngles(ii));
                    if part < -1
                        part = -1;
                    elseif part > 1
                        part = 1;
                    end
                    alpha(ii) = asin(part);
                elseif ~isnan(halfAngles(ii)) && hingingAngles(ii) > element.advancingContactAngle
                    b_i(ii) = rp1 * cos(element.advancingContactAngle + halfAngles(ii))/ sin(halfAngles(ii));
                    alpha(ii) = pi/2 - element.advancingContactAngle - halfAngles(ii);
                end
                if b_i(ii) < 0
                    b_i(ii) = 0;
                end
                hingingAngles(ii) = min ( hingingAngles(ii) , element.advancingContactAngle);
                E0(ii) = pi/2 - hingingAngles(ii) - halfAngles(ii);
                E1(ii) = b_i(ii) * cos(hingingAngles(ii));
            end
            rp2 = (element.radius ^ 2 / 4 / element.shapeFactor - rp1 * sum(E1) + rp1^2 * sum(E0))/...
                (2*rp1 * sum(alpha) + (element.radius/2/element.shapeFactor - 2 * sum(b_i)) * cos(element.advancingContactAngle));
            
            R_n = rp2;
            
            if R_n == rp1 %|| abs(rp2-rp1)> 10^-10
                it = it+1;
                NR = 1;
            end
        end
        
        if NR == 1
            R_o =  rpd * 2;
            R_n =  rpd;
            while abs(R_o - R_n) > 10^-10  % NR method based on Khazali 2018
                dU_dR = 0; dO_dR = 0; dN_dR = 0; dM_dR = 0; M = 0; N = 0; O = 0; U = 0;
                R_o = R_n;
                for ii = 1:nc
                    %-------------------------------------------------
                    t = rpd/R_o*cos(element.recedingContactAngle + halfAngles(ii));
                    if t <= 1 && t >= -1
                        teta_H = acos(rpd/R_o*cos(element.recedingContactAngle + halfAngles(ii)))-halfAngles(ii);
                    else
                        teta_H = element.recedingContactAngle;
                    end
                    if teta_H <= element.advancingContactAngle
                        b_i = rpd * cos(element.recedingContactAngle + halfAngles(ii)) / sin(halfAngles(ii));
                        t = b_i / R_o * sin( halfAngles(ii));
                        if t <= 1 && t >= -1
                            alpha = asin (b_i / R_o * sin( halfAngles(ii)));
                        else
                            alpha = 0;
                        end
                    else
                        b_i = R_o * cos(element.advancingContactAngle + halfAngles(ii)) / sin(halfAngles(ii));
                        alpha = pi / 2 - element.advancingContactAngle - halfAngles(ii);
                    end
                    teta_H = min (teta_H , element.advancingContactAngle);
                    %-------------------------------------------------
                    if teta_H <= element.advancingContactAngle
                        db_dR = 0;
                        t = (b_i/ R_o * sin(halfAngles(ii)))^2;
                        if t <= 1 && t >= -1
                            dalpha_dR = (R_o * db_dR - b_i) * sin( halfAngles(ii)) / ...
                                (R_o ^ 2 * sqrt(1-(b_i/ R_o * sin(halfAngles(ii)))^2));
                        else
                            dalpha_dR = 0;
                        end
                    else
                        db_dR = cos(element.advancingContactAngle + halfAngles(ii))/sin( halfAngles(ii));
                        dalpha_dR = 0;
                    end
                    t = rpd / R_o * cos(element.recedingContactAngle+halfAngles(ii));
                    if t <= 1 && t >= -1
                        a = acos(rpd / R_o * cos(element.recedingContactAngle+halfAngles(ii))) - halfAngles(ii);
                        if a >= element.advancingContactAngle
                            dtetaH_dR = 0;
                        else
                            t = (rpd/R_o * cos(element.recedingContactAngle+halfAngles(ii)))^2;
                            if t <= 1 && t >= -1
                                dtetaH_dR = rpd * cos(element.recedingContactAngle+halfAngles(ii))/...
                                    (R_o ^ 2 * sqrt(1-(rpd/R_o * cos(element.recedingContactAngle+halfAngles(ii)))^2));
                            else
                                dtetaH_dR = rpd * cos(element.recedingContactAngle+halfAngles(ii))/(R_o ^ 2 );
                            end
                        end
                    else
                        dtetaH_dR = 0;
                    end
                    %-------------------------------------------------
                    dU_dR = dU_dR - 2 * cos(element.advancingContactAngle) * db_dR;
                    dO_dR = dO_dR + 2 * alpha + 2 * R_o * dalpha_dR;
                    dN_dR = dN_dR + 2 * R_o * (pi/2 - teta_H - halfAngles(ii)) - R_o ^2 * dtetaH_dR;
                    dM_dR = dM_dR + R_o * (dtetaH_dR * b_i * sin(teta_H) - db_dR * cos(teta_H)) - b_i * cos(teta_H);
                    M = M - R_o * b_i * cos(teta_H) ;
                    N = N + R_o ^ 2 * (pi/2 - teta_H - halfAngles(ii));
                    O = O + 2 * R_o * alpha;
                    U = U + (element.radius /2 / element.shapeFactor - 2 * b_i ) * cos(element.advancingContactAngle);
                end
                A = element.radius ^ 2 / 4 / element.shapeFactor;
                F_R = (A + M + N) / (O + U)- R_o;
                dF_R = ((dM_dR+dN_dR)*(O + U)-(dO_dR + dU_dR)*(M + N + A)) / (O + U)^2 - 1;
                R_n = R_o - F_R / dF_R;
            end
            if it > maxIteration
                err = 2 * abs(R_o - R_n) / (abs(R_o) + abs(R_n)+0.001);
                fprintf('err %f\n',err);
            end
        end
        element.imbThresholdPressure_PistonLike = element.IFT_NperMeter / R_n;
    elseif element.advancingContactAngle > maxAdvAngle && element.advancingContactAngle < pi/2 + max(halfAngles) % Forced imbibition
        element.imbThresholdPressure_PistonLike = 2 * element.IFT_NperMeter * cos(element.advancingContactAngle) / element.radius;
    elseif element.advancingContactAngle >= pi/2 + max(halfAngles) % Forced imbibition
        element.imbThresholdPressure_PistonLike = -calculateThresholdPressurePistonLike_drainage(element, (pi - element.advancingContactAngle));
    end
end
end