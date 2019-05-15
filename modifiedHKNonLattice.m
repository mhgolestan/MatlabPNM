function [NumberOfClusters, NodeL, LinkL] = modifiedHKNonLattice(NodeS, LinkS,NodeNext, LinksOfNode, OFlag)
%=====================================================
%
% Adaptation of Hoshen--Kopelman cluster labeling algorithm for disordered
% networks (nodes and links are placed at random in space)
%
% Input arguments:
%
% NodeS =Occupancy state of nodes
% LinkS = Occupancy state of links
% NodeNext = Neighboring nodes connected to each node
% LinksOfNode = Links attached to each node
% OFlag = Flag for occupied nodes and links (1 in this paper)
%
% Output arguments:
%
% NumberOfClusters = Number of occupied clusters
% NodeL = Cluster labels of nodes
% LinkL = Cluster labels of links
%
% By: Ahmed AL-Futaisi and Tadeusz Patzek
%
%=========================================
%
% STEP 1: READ THE DATA AND INITIALIZE THE OUTPUT
%
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
%
return