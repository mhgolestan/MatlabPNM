function Sw_drain = calculateSaturations(obj, Pc)
    calculateConductance(obj, Pc);
    % Water Saturation Calculation
    waterVolume = 0;   
    vol=0;
    for i = 1:obj.numberOfNodes
%                 if ~obj.Nodes{i}.isInlet && ~obj.Nodes{i}.isOutlet 
        if obj.Nodes{i}.occupancy == 'B'
             waterVolume = waterVolume + (obj.Nodes{i}.waterCrossSectionArea / obj.Nodes{i}.area) *...
                 (obj.Nodes{i}.volume + obj.Nodes{i}.clayVolume);
        else
             waterVolume = waterVolume + obj.Nodes{i}.volume + obj.Nodes{i}.clayVolume;
        end
        vol=vol+obj.Nodes{i}.volume + obj.Nodes{i}.clayVolume;
%                 end
    end
    for i = 1:obj.numberOfLinks   
%                 if ~obj.Links{i}.isInlet && ~obj.Links{i}.isOutlet 
        if obj.Links{i}.occupancy == 'B'
             waterVolume = waterVolume+ (obj.Links{i}.waterCrossSectionArea / obj.Links{i}.area) *...
                 (obj.Links{i}.volume + obj.Links{i}.clayVolume);
        else
             waterVolume = waterVolume + obj.Links{i}.volume + obj.Links{i}.clayVolume;
        end  
        vol=vol+obj.Links{i}.volume + obj.Links{i}.clayVolume;
%                 end
    end  
    Sw_drain = waterVolume / vol;            
end
