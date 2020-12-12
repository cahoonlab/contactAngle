function [val] = fitfun_CA( center, radius, BW )
%Determine Circle Quality, as a Fitting Figure of Merit
%From https://web.wpi.edu/Pubs/E-project/Available/E-project-042508-083811/unrestricted/MQP.pdf

crcl = circle_CA( center, radius, size( BW ) ); % Create Circle
val = 1/abs(sum(sum(BW&crcl) )-sum(sum(crcl&~BW))); % Value Drawing’s Accuracy 
return;


end

