classdef IO < quasiStatic.Fluids
    
    properties  
    end    
    
    methods 
          function obj = IO()
          end
       
                 
        % Network Properties calculation & printing & plotting Network Properties 
        output_networkStochasticAndPlotInfo_singlePhaseFlow(obj, network) 
        output_networkStochasticAndPlotInfo_twoPhaseFlow(obj, network) 
         
        % Paraview visualization
        visualization(obj, network,process, timeStep)   
    end
end

