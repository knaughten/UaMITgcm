function [Areas,xEleCentre,yEleCentre,Area]=TriAreaFE(coordinates,connectivity)
    
    % [A,xEleCentre,yEleCentre]=TriAreaFE(coordinates,connectivity)
    % calculates the area of triangles in a FE mesh given coordinates and connectivity
	% assumes straigth sides
	%
    
    [Nele,nod]=size(connectivity);
    xnod=reshape(coordinates(connectivity,1),Nele,nod);
    ynod=reshape(coordinates(connectivity,2),Nele,nod);
    
    xEleCentre=mean(xnod,2); yEleCentre=mean(ynod,2);
    
    switch nod
        case 3
            %% JDR 13/02/2024: renamed function to avoid clash with duplicate
            %% file triarea.m in Mesh2d
            %Areas=TriArea(xnod,ynod);
            Areas=TriArea_Ua(xnod,ynod);
        case 6
            %% JDR 13/02/2024: renamed function to avoid clash with duplicate
            %% file triarea.m in Mesh2d
            %Areas=TriArea(xnod(:,[1 3 5]),ynod(:,[1 3 5]));
            Areas=TriArea_Ua(xnod(:,[1 3 5]),ynod(:,[1 3 5]));
        case 10
            %% JDR 13/02/2024: renamed function to avoid clash with duplicate
            %% file triarea.m in Mesh2d
            %Areas=TriArea(xnod(:,[1 4 7]),ynod(:,[1 4 7]));
            Areas=TriArea_Ua(xnod(:,[1 4 7]),ynod(:,[1 4 7]));
        otherwise
            fprintf(' case not implemented ')
            error('error in TriAreaFE')
    end
    
    Area=sum(Areas);
    
    
end
