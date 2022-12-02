classdef Fluids < handle
    %Fluids: contains information related to oil, gas and water     
    
    properties
        waterViscosity
        oilViscosity
        gasViscosity
        sig_ow 
    end    
    
    methods
         function obj = Fluids()
             obj.waterViscosity = 0.00105; % Pa.s or N.s/m2
             obj.oilViscosity = 0.00139;
             obj.gasViscosity = 0.00001;
             obj.sig_ow = 72.5e-3; % N/m
         end 
    end
end

