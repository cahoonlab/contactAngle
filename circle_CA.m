function subim = circle_CA( center, radius, sz )
%Create an Image with Fitted Circle Points
%From https://web.wpi.edu/Pubs/E-project/Available/E-project-042508-083811/unrestricted/MQP.pdf
% tic
[a,b] = ndgrid( -radius:radius ); % Restrict domain to radius
tmp = a.^2 + b.^2 <= radius^2; % Make Domain Circular
subim = zeros( sz ); % Matrix of Zeros
subim(round(min(end, max(1,center(1)+[-radius:radius]) )), ...
round(min(end, max(1,center(2)+[-radius:radius]) )) ) = tmp; %Draw Circle
% toc
return;

end