classdef Link < quasiStatic.Element
    
    %LINK is a class for link objects
    %   Detailed explanation goes here
    
    properties
        pore1Index
        pore2Index
        length %total length of the link (pore center to pore center)
        pore1Length
        pore2Length
        linkLength  % only the length of the link
         
        nodeLinkSystemConductanceSinglePhase  
    end
    
    methods
        function obj = Link(index,... 
                            pore1Index,... 
                            pore2Index,...
                            radius,...
                            shapeFactor,...
                            length,...
                            pore1Length,...
                            pore2Length,...
                            linkLength,...
                            volume,...
                            clayVolume)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.index = index;
            %This condition is to set the nodes with index -1 in node1 and
            %nodes with 0 index in node2
            if pore2Index == -1 || pore1Index == 0
                obj.pore1Index = pore2Index; 
                obj.pore2Index = pore1Index;
                obj.pore1Length = pore2Length;
                obj.pore2Length = pore1Length;  
            else            
                obj.pore1Index = pore1Index; 
                obj.pore2Index = pore2Index;
                obj.pore1Length = pore1Length;
                obj.pore2Length = pore2Length;
            end
                   
            obj.radius = radius;
            obj.shapeFactor = shapeFactor;
            obj.length = length;
            obj.linkLength = linkLength;
            obj.volume = volume;
            obj.clayVolume = clayVolume;
            
            %Cheking inlet or outlet status of the link
            obj.isInlet  = false;
            obj.isOutlet = false;
            if obj.pore1Index == -1 
                obj.isInlet = true;
            elseif obj.pore2Index == 0
                obj.isOutlet = true;
            end 
        end         
    end
end

