function [NumberOfClusters, NodeL, LinkL,cluster_A_nums,cluster_B_nums] = clustering_wettingPhase(network)
% Arguments of HoshenKopelman function
NodeS = zeros(network.numberOfNodes,1);
LinksOfNode = zeros(network.numberOfNodes,network.maxCoordinationNumber);
NodeNext = zeros(network.numberOfNodes,network.maxCoordinationNumber);
wettingPhase = 0;
for i = 1:network.numberOfNodes
    NodeS(i,1) = network.Nodes{i}.occupancy; % nodes with nonWetting(B),nodes with wettingPhase(A)
    
    if network.Nodes{i}.occupancy == 'A'
        wettingPhase = 1;
    end
    if network.Nodes{i}.shapeFactor <= 1 / 16 % There is wettingPhase in the corners
        NodeS(i,1) = 'A';
    end
    if ~network.Nodes{i}.isInlet && ~network.Nodes{i}.isOutlet
        LinksOfNode(i,1:network.Nodes{i}.connectionNumber) = network.Nodes{i}.connectedLinks;
        NodeNext(i,1:network.Nodes{i}.connectionNumber) = network.Nodes{i}.connectedNodes;
    else
        a = 1;
        for j = 1:network.Nodes{i}.connectionNumber
            if ~network.Links{network.Nodes{i}.connectedLinks(j)}.isInlet && ~network.Links{network.Nodes{i}.connectedLinks(j)}.isOutlet
                LinksOfNode(i,a) = network.Nodes{i}.connectedLinks(j);
                NodeNext(i,a) = network.Nodes{i}.connectedNodes(j);
                a = a+1;
            end
        end
    end
end
LinkS = zeros(network.numberOfLinks,1);
for i =1:network.numberOfLinks
    if ~network.Links{i}.isInlet && ~network.Links{i}.isOutlet
        LinkS(i,1) = network.Links{i}.occupancy; % throats with nonWetting(B), throats with wettingPhase(A)
        
        if network.Links{i}.occupancy == 'A'
            wettingPhase = 1;
        end
        if network.Links{i}.shapeFactor <= 1 / 16 % There is wettingPhase in the corners
            LinkS(i,1) = 'A';
        end
    end
end
OFlag = 'A'; %nonWetting clusters has numbers B:NumberOfClusters %wettingPhase clusters are A

if  wettingPhase == 1
    %% HoshenKopelman Algorithm for clustering
%     [NumberOfClusters, NodeL, LinkL] = modifiedHKNonLattice(NodeS, LinkS,NodeNext, LinksOfNode, OFlag);
NumberOfNodes = length(NodeS); % Number of nodes in current network
NumberOfLinks = length(LinkS); % Number of links in current network
NumberOfClusters = 0;
%
% STEP 2: INITIALIZE THE HK ALGORITHM VARIABLES NodeL and LinkL
%
NodeL = zeros(NumberOfNodes,1); % Array to store cluster labels of nodes
LinkL = zeros(NumberOfLinks,1); % Array to store cluster labels of links
%
% STEP 3: CREATE EMPTY ARRAY NodeLP AND START CLUSTER COUNTER
%
NodeLP=[]; % Array used for relabeling steps
Cluster=0; % Cluster counter
%
% STEP 4: SCAN THE NETWORK NODES
%
for i=1:NumberOfNodes
    %
    % Check if the node (Case 4c):
    % 1.has OFlag occupancy
    % 2.has both NodeNext and LinksOfNode that have OFlag occupancy
    N=find((NodeS(i)==OFlag).*(NodeS(nonzeros(NodeNext(i,:))) == OFlag).*...
    (LinkS(nonzeros(LinksOfNode(i,:)))==OFlag));
    %
    if (~isempty(N))
        %
        % Define the occupancy status of NodeNext
        %
        Nodes=NodeNext(i,N);
        NodeNextL=NodeL(Nodes);
        %
        % Case 4c i: No labeled neighbour
        %
        if any(NodeNextL)==0 % Start a new cluster
            Cluster=Cluster+1;
            NodeL(i)=Cluster;
            NodeLP(end+1)=Cluster;
            %
            % Case 4c ii: There exists a labeled neighbor
            %
        else % Put in the minimum labeling
            N=nonzeros(NodeNextL);
            for k = 1:length(N)
                M= NodeLP(N(k));
                while M<N(k)
                    N(k) = M;
                    M = NodeLP(N(k));
                end
            end
            NodeLPmin=min(N);
            NodeL(i)=NodeLPmin;
            NodeLP(N)=NodeLPmin;
        end
        %
        % This node is type 4b:
    elseif NodeS(i)==OFlag
        Cluster=Cluster+1; % Start a new cluster
        NodeL(i)=Cluster;
        NodeLP(end+1)=Cluster;
    end
    %
    % Skip nodes that are type 4a

end
%
% STEP 5A: CORRECT LABELS IN NodeLP RECURSIVELY
%
for i=1:length(NodeLP)
    N=i;
    while (NodeLP(N)<N)
    N=NodeLP(N);
    end
    NodeLP(i)=N;
end
%
% STEP 5B: RENUMBER LABELS IN NodeLP TO RUN SEQUENTIALLY
%
NodeLP1=sort(NodeLP);
RelabL=NodeLP1(2:end).*(NodeLP1(2:end) > NodeLP1(1:end-1));
RelabL=[NodeLP1(1), nonzeros(RelabL)'];
for i=1:length(RelabL)
    NodeLP(find(NodeLP==RelabL(i)))=i;
end
%
% STEP 6: APPLY THE CORRECT LABELS TO THE ARRAYS NodeL AND LinkL
%
for i=1:length(NodeLP)
    N=nonzeros(LinksOfNode(find(NodeL==i),:));
    LinkL(nonzeros(N.*(LinkS(N)==OFlag)))=NodeLP(i);
    NodeL(find(NodeL==i))=NodeLP(i);
end
%
% STEP 7: FINALLY, LABEL THE CLUSTERS THAT CONSIST OF SINGLE LINKS
%
SingleLink=find(LinkL==0 & LinkS==OFlag);
if ~isempty(SingleLink)
    NewCluster = max(max(NodeL),max(LinkL))+1;
    NewCluster = [NewCluster:NewCluster+(length(SingleLink)-1)];
    LinkL(SingleLink)=NewCluster;
end
%
% RECORD NUMBER OF CLUSTERS
%
NumberOfClusters=max(max(NodeL),max(LinkL));    
%%
    % Modify number of inlet & outlet Links of Clusters
    a = 0;
    for i =1:network.numberOfLinks
        if network.Links{i}.isInlet
            if  network.Links{i}.occupancy == 'A' || any(network.Links{i}.wettingPhaseCornerExist)
                if network.Nodes{network.Links{i}.pore2Index}.occupancy == 'A' || network.Nodes{network.Links{i}.pore2Index}.shapeFactor <= 1 / 16
                    LinkL(i,1) = NodeL(network.Links{i}.pore2Index);
                else
                    a = a + 1;
                    LinkL(i,1) = max(NodeL)+a;
                end
            end
            
        elseif network.Links{i}.isOutlet
            if network.Links{i}.occupancy == 'A' || any(network.Links{i}.wettingPhaseCornerExist)
                if network.Nodes{network.Links{i}.pore1Index}.occupancy == 'A' || network.Nodes{network.Links{i}.pore1Index}.shapeFactor <= 1 / 16
                    LinkL(i,1) = NodeL(network.Links{i}.pore1Index);
                else
                    a = a + 1;
                    LinkL(i,1) = max(NodeL)+a;
                end
            end
        end
    end
    
    inlet_cluster_indx = zeros(network.numOfInletLinks,2);
    outlet_cluster_indx = zeros(network.numOfOutletLinks,2);
    inlet = 1;
    outlet = 1;
    for i = 1:network.numberOfLinks
        if network.Links{i}.isInlet
            inlet_cluster_indx(inlet,1) = network.Links{i}.index;
            inlet_cluster_indx(inlet,2) = LinkL(i,1);
            inlet = inlet +1;
        elseif network.Links{i}.isOutlet
            outlet_cluster_indx(outlet,1) = network.Links{i}.index;
            outlet_cluster_indx(outlet,2) = LinkL(i,1);
            outlet = outlet + 1;
        end
    end
    
    a = 0;
    A = zeros(max(network.numOfOutletLinks , network.numOfInletLinks),1);
    for i = 1:length(outlet_cluster_indx)
        if outlet_cluster_indx(i,2) ~= 0
            for j = 1:length(inlet_cluster_indx(:,2))
                if outlet_cluster_indx(i,2) == inlet_cluster_indx(j,2)
                    if ~any(outlet_cluster_indx(i,2) == A(:,1))
                        a = a+1;
                        A(a,1) = outlet_cluster_indx(i,2);
                        break
                    end
                end
            end
        end
    end
    cluster_A_nums = nonzeros(A);
    
    b = 0;
    B = zeros(network.numberOfLinks,1);
    for i = 1:length(outlet_cluster_indx)
        if outlet_cluster_indx(i,2) ~= 0
            if ~any(outlet_cluster_indx(i,2) == cluster_A_nums(:))
                if ~any(outlet_cluster_indx(i,2) == B(:))
                    b = b +1;
                    B(b,1) = outlet_cluster_indx(i,2);
                end
            end
        end
    end
    cluster_B_nums = nonzeros(B);
else
    NumberOfClusters=-1; NodeL=-2*ones(network.numberOfNodes,1); LinkL=-2*ones(network.numberOfLinks,1); cluster_A_nums=-1; cluster_B_nums=-1;
end
