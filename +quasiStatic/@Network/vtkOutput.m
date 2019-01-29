function vtkOutput(obj)
            vtkFileID = fopen('output.vtk','w');
            if vtkFileID == -1
                error('Cannot open file for writing.');
            end
            title = 'output';
            fprintf ( vtkFileID, '# vtk DataFile Version 2.0\n' );
            fprintf ( vtkFileID, '%s\n', title );
            fprintf ( vtkFileID, 'ASCII\n' );
            fprintf ( vtkFileID, '\n' );
            fprintf ( vtkFileID, 'DATASET POLYDATA\n' );
            fprintf ( vtkFileID, 'POINTS %d double\n', obj.numberOfNodes );
            for i = 1:obj.numberOfNodes
                fprintf( vtkFileID,'%d %d %d \n', obj.Nodes{i}.x_coordinate, obj.Nodes{i}.y_coordinate, obj.Nodes{i}.z_coordinate );
            end
            
end