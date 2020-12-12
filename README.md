# contactAngle
A MATLAB tool for measuring contact area of droplets on a surface

Written by Jonathan K. Meyers (ORCID 0000-0002-6698-3420)

Created in MATLAB R2016a

This project was inspired by Ken Osborne (2008). Some sections are exact duplications. Most sections required minor/major modifications. Source code is available here: https://web.wpi.edu/Pubs/E-project/Available/E-project-042508-083811/unrestricted/MQP.pdf

One function (rotateAround_CA.m) was written by Jan Motl and is redistributed according to license. Please see the comments in that function for a fair warning disclaimer on its use. It was obtained here: https://www.mathworks.com/matlabcentral/fileexchange/40469-rotate-an-image-around-a-point.


main_CA.m is the portal by which measurements are initialized and completed.

First, a measurement job is submitted to a queue. This section should be run while in the working directory for a set of images captured for a single pair of droplet/substrate materials. Depending on how many images there are, at least 2 figures will load and prompt you to select the area of interest. The final cropping mask is a combination of each of those masks. See Fig1(mask).png for an example.

Next you must choose the baseline for the droplet/substrate interface. This is done on at least 2 images and the rotation angle is averaged. See Fig2(baseline).png for an example.

After cropping and leveling, you will see some sample figures appear and disappear of the droplets being converted to black and white and then identifying and filling in the droplet. A file is then saved with all the measurement parameters.

Once you've added all your samples to the queue, run the second section of main_CA.m. This then performs the measurement on all the images for all the samples in the queue and does so by optimizing a circle of best fit overlayed on the droplet. The progress will display in the command window. The contact angle is caculated by the tangent line between the circle of best fit and the substrate baseline (see Fig3(geometry).png). After each sample is finished, an average contact angle is displayed, and the data is saved. Examples of the output data are included herein (see SiNatOx_APTES_example_output.mat, ca-v-pp.fig, hw-v-pp.fig, projArea-v-pp.fig). These plots are easily customized in the code.

The last section in main_CA.m is for convenience in reproducing the image of the circle of best fit on the droplet silhouette. Simply load on of the output data files, specify the index of one of the images, and run the section.
