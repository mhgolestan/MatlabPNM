function calculateThresholdPressureLayerCollapse_Piri(element, Pc_max_drainage)
         
         if strcmp(element.geometry , 'Circle')== 1
             element.imbThresholdPressure_LayerCollapse = nan(1,4);
         else
              halfAngles = [element.halfAngle1, element.halfAngle2,element.halfAngle3, element.halfAngle4];  
              if strcmp(element.geometry , 'Triangle')== 1
                  nc = 3;
              elseif strcmp(element.geometry , 'Square')== 1
                  nc = 4;
              end
              element.imbThresholdPressure_LayerCollapse = nan(1, 4); hingingAngles = zeros(1,4);   b_i = zeros(nc , 1);
              for i = 1:nc 
                  hingingAngles(i) = element.advancingContactAngle;
                  h = hingingAngles(i)/2;
                  b_i(i) = element.IFT_NperMeter / element.imbThresholdPressure_PistonLike * cos(hingingAngles(i) + halfAngles(i))/sin(halfAngles(i));
                  while abs(hingingAngles(i) - h) > 10 ^ -5  
                      Pc_n = element.IFT_NperMeter *...
                          (3*(sin(halfAngles(i)))^2+ 4*sin(halfAngles(i))*cos(hingingAngles(i))+(cos(hingingAngles(i)))^2)/...
                          (b_i(i)*(cos(halfAngles(i))*sin(halfAngles(i))*(2*sin(halfAngles(i))+cos(hingingAngles(i)))+...
                          (sin(halfAngles(i)))^2 * ...
                          sqrt(4*(cos(halfAngles(i)))^2-3-(cos(hingingAngles(i)))^2-4*sin(halfAngles(i))*cos(hingingAngles(i)))));                       
                      h = hingingAngles(i);
                      hingingAngles(i) = acos((Pc_n/Pc_max_drainage)*cos(element.recedingContactAngle + halfAngles(i))) - halfAngles(i);  
                      hingingAngles(i) = min (hingingAngles(i), element.advancingContactAngle);
                      b_i(i) = element.IFT_NperMeter / Pc_n * cos(hingingAngles(i) + halfAngles(i))/sin(halfAngles(i));
                  end
                  element.imbThresholdPressure_LayerCollapse(i) = Pc_n;
              end
              
         end
        end 