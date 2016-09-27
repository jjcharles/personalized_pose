%function to extract rectangle from image provided with
%-image
%-anchor points on rectangle as percentage of rectangle height
%-2x2d coordinates in the image
%-input width of rectangle
%-output width and height
%Output is a canonicalised patch from the input image when converted to
%colour_space either 'RGB' or 'YUV'
function can_patch = img2can(img,xin,yin,anchor,width,height_out,colour_space)
    can_patch = [];
    
    %check for singularity
    if sum((xin(1)==xin(2))+(yin(1)==yin(2)))==2 %error correct if joints are on top of each other
        yin(2) = yin(2) + 1;
    end
        
    coords = [xin,yin];
    diff = (coords(1,:)-coords(2,:));
    diff = diff/sqrt(sum(diff.^2));
    X = [coords; [coords(1,1) + diff(2)*5, coords(1,2) - diff(1)*5]];
    can_coords = [width/2, anchor(1)*height_out;...
        width/2, anchor(2)*height_out]; 
    U = [can_coords; [ (can_coords(1,1) - 5), can_coords(1,2)]];
    t_concord = cp2tform(X,U,'affine');  
    can_patch = imtransform(img,t_concord,'bilinear','XData',[1 width],...
        'YData',[1 height_out],'XYScale',1,'FillValues',0);

