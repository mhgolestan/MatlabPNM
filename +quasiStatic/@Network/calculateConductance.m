 function calculateConductance(obj, Pc)           
    for i = 1:obj.numberOfNodes
        if obj.Nodes{i}.occupancy == 'B' %Node was occupied by oil
            [obj.Nodes{i}.waterCrossSectionArea, obj.Nodes{i}.waterConductance] =...
                obj.Nodes{i}.calculateWaterConductance(obj, Pc); 
            [obj.Nodes{i}.oilCrossSectionArea, obj.Nodes{i}.oilConductance] = ...
                obj.Nodes{i}.calculateOilConductance(obj);    
        else
            obj.Nodes{i}.waterCrossSectionArea = obj.Nodes{i}.area;
            obj.Nodes{i}.waterConductance = obj.Nodes{i}.conductance; 
            obj.Nodes{i}.oilCrossSectionArea = 0;
            obj.Nodes{i}.oilConductance = 0;  
        end
    end
    for i = 1:obj.numberOfLinks
        if obj.Links{i}.occupancy == 'B' %Link was occupied by oil
            [obj.Links{i}.waterCrossSectionArea, obj.Links{i}.waterConductance] =...
                obj.Links{i}.calculateWaterConductance(obj, Pc); 
            [obj.Links{i}.oilCrossSectionArea, obj.Links{i}.oilConductance] = ...
                obj.Links{i}.calculateOilConductance(obj);  
        else
            obj.Links{i}.waterCrossSectionArea = obj.Links{i}.area;
            obj.Links{i}.waterConductance = obj.Links{i}.conductance; 
            obj.Links{i}.oilCrossSectionArea = 0;
            obj.Links{i}.oilConductance = 0;
        end
    end            
end