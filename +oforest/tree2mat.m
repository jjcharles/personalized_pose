%function to convert a ctree into matrix form
function mat_tree = tree2mat(tree)
    numclasses = numel(tree(end).distribution);

    %preallocate memory
    mat_tree = zeros(11+numclasses,numel(tree));
    
    

    for n = 1:numel(tree)
        if ~isempty(tree(n).left); mat_tree(1,n) = (tree(n).left-1)*19; end
        if ~isempty(tree(n).right); mat_tree(2,n) = (tree(n).right-1)*19; end
        mat_tree(3,n) = tree(n).leaf;
        mat_tree(4,n) = tree(n).depth;
        
        if ~isempty(tree(n).test)
            mat_tree(5,n) = tree(n).test(1); %offset1x
            mat_tree(6,n)= tree(n).test(2); %offset1y
            mat_tree(7,n) = tree(n).test(3); %offset2x
            mat_tree(8,n) = tree(n).test(4); %offset2y
            mat_tree(9,n)= tree(n).test(5); %func type
            mat_tree(10,n) = tree(n).test(6); %thresh
            mat_tree(11,n)= tree(n).test(7); %channel
        end
        
        if n ~= 1
            mat_tree(12:(11+numclasses),n) = tree(n).distribution;
        end
    end
    