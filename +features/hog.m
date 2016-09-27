%function to produce hog features
function feat = hog(img,cellsize)

    feat = hogfeat(im2double(img),cellsize);