classdef Fluids < handle
    %Fluids: contains information related to wetting and nonWetting Phase     
    
    properties
        wettingPhase_Viscosity_PaS
        nonWettingPhase_Viscosity_PaS 
        IFT_NperMeter
    end    
    
    methods
         function obj = Fluids()
             obj.wettingPhase_Viscosity_PaS    = 0.00105; % Pa.s or N.s/m2
             obj.nonWettingPhase_Viscosity_PaS = 0.00139; % Pa.s or N.s/m2 
             obj.IFT_NperMeter                 = 72.5e-3; % N/m
         end 
    end
end

