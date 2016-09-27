%make a canonical joint patch
function patch = make_patch(width)
    disc = strel('disk',width,0);
    [r,c] = find(disc.getnhood);
    patch = [c, r] - width - 1;
end