clc;clear

fileName = 'rock';
link_1_fileID = fopen(strcat(fileName, '_link1.dat'), 'w');
link_2_fileID = fopen(strcat(fileName, '_link2.dat'), 'w');
node_1_fileID = fopen(strcat(fileName, '_node1.dat'), 'w');
node_2_fileID = fopen(strcat(fileName, '_node2.dat'), 'w');

nodesInXDirection = 40;
nodesInYDirection = 40;
nodesInZDirection = 40;

% network dimention in meter
networkXDirection = 0.002;
networkYDirection = 0.002;
networkZDirection = 0.002;

x_coordinates = linspace(0,networkXDirection,nodesInXDirection);
y_coordinates = linspace(0,networkYDirection,nodesInYDirection);
z_coordinates = linspace(0,networkZDirection,nodesInZDirection);

nodeIndex = 1;

for ii = 1:length(x_coordinates)
    for jj = 1:length(y_coordinates)
        for kk = 1:length(z_coordinates)
            if ii == 1
                if jj == 1
                    if kk == 1
                        fprintf(node_1_fileID, '%d\t%4.8f\t%4.8f\t%4.8f\n',nodeIndex, x_coordinates(ii), y_coordinates(jj), z_coordinates(kk));
                        nodeIndex = nodeIndex + 1;
                    elseif kk == nodesInZDirection
                        fprintf(node_1_fileID, '%d\t%4.8f\t%4.8f\t%4.8f\n',nodeIndex, x_coordinates(ii), y_coordinates(jj), z_coordinates(kk));
                        nodeIndex = nodeIndex + 1;
                    else
                        fprintf(node_1_fileID, '%d\t%4.8f\t%4.8f\t%4.8f\n',nodeIndex, x_coordinates(ii), y_coordinates(jj), z_coordinates(kk));
                        nodeIndex = nodeIndex + 1;
                    end
                elseif jj == nodesInYDirection
                    
                else
                    
                    
                end
                
                
            
            
            end
        end
    end
end


%closing the files
fclose(link_1_fileID); fclose(link_2_fileID);
fclose(node_1_fileID); fclose(node_2_fileID);
