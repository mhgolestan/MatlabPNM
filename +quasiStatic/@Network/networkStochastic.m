%% Network Properties calculation
function networkStochastic(network, fileName)


currentFoldet = pwd;
networkFileFullPath = strcat(currentFoldet, '/Results/');
fileName = strcat(fileName,'_stocastic','.txt');
vtkFileID = fopen(fullfile(networkFileFullPath,fileName),'w'); 
 
if vtkFileID == -1
    error('Cannot open file for writing.');
end

fprintf( vtkFileID, '\n===============================Ntework Information=====================================\n');
fprintf( vtkFileID, 'Dimension of network in x-axis:         %d \n', network.xDimension);
fprintf( vtkFileID, 'Dimension of network in y-axis:         %d \n', network.yDimension);
fprintf( vtkFileID, 'Dimension of network in z-axis:         %d \n', network.zDimension);
fprintf( vtkFileID, 'Number of pores:                        %d \n', network.numberOfNodes);
fprintf( vtkFileID, 'Number of throats:                      %d \n', network.numberOfLinks);
fprintf( vtkFileID, 'Average connection number:              %3.3f \n', network.averageCoordinationNumber);
fprintf( vtkFileID, 'StandardDeviation connection number:    %3.3f \n', network.stdCoordinationNumber);
fprintf( vtkFileID, 'Number of connections to inlet:         %d \n', network.numOfInletLinks);
fprintf( vtkFileID, 'Number of connections to outlet:        %d \n', network.numOfOutletLinks);
fprintf( vtkFileID, 'Number of physically isolated elements: %d \n', network.numOfIsolatedElements);
fprintf( vtkFileID, 'Number of triangular shaped elements:   %d \n', network.numOfTriangularElements);
fprintf( vtkFileID, 'Number of square shaped elements:       %d \n', network.numOfSquareElements);
fprintf( vtkFileID, 'Number of circular shaped elements:     %d \n', network.numOfCircularElements);
fprintf( vtkFileID, 'Number of triangular shaped pores:      %d \n', network.numOfTriangularPores);
fprintf( vtkFileID, 'Number of square shaped pores:          %d \n', network.numOfSquarePores);
fprintf( vtkFileID, 'Number of circular shaped pores:        %d \n', network.numOfCircularPores);
fprintf( vtkFileID, 'Net porosity:                           %3.5f \n', network.Porosity);
fprintf( vtkFileID, 'Absolute permeability (mD):             %3.6f \n', network.absolutePermeability);
fprintf( vtkFileID, 'Absolute permeability (m2):             %E \n', network.absolutePermeability_m2);
fprintf( vtkFileID, '======================================================================================\n\n');
 


fprintf( vtkFileID, 'MeanPoreInscribedRadius:                        %d \n', mean(network.PSD)/2);
fprintf( vtkFileID, 'StandardDeviationPoreInscribedRadius:           %d \n', std(network.PSD)/2);
fprintf( vtkFileID, 'MeanThroatInscribedRadius:                      %d \n', mean(network.ThSD)/2);
fprintf( vtkFileID, 'StandardDeviationThroatInscribedRadius:         %d \n', std(network.ThSD)/2);
fprintf( vtkFileID, 'MinThroatInscribedLength:                       %d \n', min(network.ThSD_length));
fprintf( vtkFileID, 'MeanThroatInscribedLength:                      %d \n', mean(network.ThSD_length));
fprintf( vtkFileID, 'StandardDeviationThroatInscribedLength:         %d \n', std(network.ThSD_length));


fprintf ( vtkFileID, '#\n');