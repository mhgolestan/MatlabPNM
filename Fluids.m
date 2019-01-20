classdef Fluids < handle
    %Fluids: contains information related to oil, gas and water 
    
    %   send the conductivity and cross section area of each fluid to each
    %   element and also viscosuty, thermal conductivity, diffusivity of
    %   each phase
    
    properties
        waterViscosity
        oilViscosity
        gasViscosity
        sig_ow
        
      % Calculated properties
%         waterCrossSectionArea
%         oilCrossSectionArea
%         gasCrossSectionArea        
%         waterConductance
%         oilConductance
%         gasConductance

    end
    
    
    methods
         function obj = Fluids()
             obj.waterViscosity = 0.00105;
             obj.oilViscosity = 0.00139;
             obj.gasViscosity = 0.00001;
             obj.sig_ow = 10e-3; % N/m
         end
%         function obj = Fluids(Type)
%            %Fluids Construct an instance of class Fluids
%             %   This class contains fluids properties
%             switch Type
%                 case 'water'
%                     obj.waterViscosity = 0.001;
%                 case 'oil'
%                     obj.oilViscosity = 0.001;
%                 case 'gas'
%                     obj.gasViscosity = 0.00001;
%             end
%         end
    end
end

