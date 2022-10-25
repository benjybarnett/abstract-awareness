function neighbours_matrix = create_neigh_mat(neighbours_struct)
%creates a mtrix of neighrbours in the format needed by mvpa light from the
%output of ft_prepare_neighbours from fieldtrip

%INPUT: output from ft_prepare_neigbours()
%OUTPUT: Logical matrix needed by mvpa light representing neighbours

%Author Benjy Barnett 2021
neighbours_matrix = ones(size(neighbours_struct,2));

dict = containers.Map({neighbours_struct.label},1:size(neighbours_struct,2));

for chan = 1:size(neighbours_struct,2)
    label = neighbours_struct(chan).label;
    neighbours =neighbours_struct(chan).neighblabel;
    
    neigh_idxs = values(dict,neighbours);
    
    neighbours_matrix(chan,chan) = 0;
    neighbours_matrix(chan,cell2mat(neigh_idxs)) = 0;
    
end

neighbours_matrix = neighbours_matrix < 1;
end