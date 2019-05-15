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
    end
    
    
    methods
         function obj = Fluids()
             obj.waterViscosity = 0.00105;
             obj.oilViscosity = 0.00139;
             obj.gasViscosity = 0.00001;
             obj.sig_ow = 10e-3; % N/m
         end
    end
end

