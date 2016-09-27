%function to load oforest from folder containing trees
function model = load_forest_from_folder(folder)

    folder(folder=='\') = '/';
    if folder(end)~='/'; folder = [folder '/']; end
    
    forestfile = sprintf('%sforest.mat',folder);
    model = struct();
    if ~exist(forestfile,'file'); 
        %get number of trees in folder
        files = dir(sprintf('%stree*.mat',folder));
        numtrees = numel(files);

        %load each tree and add to model
        for f = 1:numtrees
            fprintf('loading tree %d of %d\n',f,numtrees);
            tree = load(sprintf('%s%s',folder,files(f).name));
            
            if isstruct(tree.tree)
                model.forestmat{f} = oforest.tree2mat(tree.tree);
                model.opts = tree.opts;
                opts = tree.opts;
                tree = oforest.tree2mat(tree.tree);
                
                save(sprintf('%s%s',folder,files(f).name),'tree','opts');
            else
                model.forestmat{f} = tree.tree;
                model.opts = tree.opts;
            end
        end
        save(forestfile,'model','-v7.3');
    else
        load(forestfile);
    end