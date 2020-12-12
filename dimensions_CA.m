function [area,height,width]=dimensions_CA(image) % Function name

%%
% figure; imshow(image)

%sum the pixels
area = sum(sum(image));
% n0 = numel(image) - n1;

height_map = sum(image,1);
heights = height_map(find(height_map > 0.5*max(height_map)));
height = mean(heights);

width_map = sum(image,2);
widths = width_map(find(width_map > 0.1*max(width_map)));
width = mean(widths);


end