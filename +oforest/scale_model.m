%function to scale test functions of model to work with different sized
%images
function model = scale_model(model,scale)

for f =1:numel(model.forestmat)
    model.forestmat{f}(5:8,:) = floor(model.forestmat{f}(5:8,:)*scale);
end

model.opts.bbox(:) = floor(model.opts.bbox(:)*scale);
model.opts.bbox(model.opts.bbox<1) = 1;
