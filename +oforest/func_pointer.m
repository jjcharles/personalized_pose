%provides a pointer to a function indexed by a number
function fp = func_pointer(num)
    switch num
        case 1
            fp = @unary;
        case 2
            fp = @binary1;
        case 3
            fp = @binary2;
        case 4
            fp = @binary3;
        otherwise
            fp = @unary;
    end
end

function val = unary(feature1)
    val = feature1;
end

function val = binary1(feature1, feature2)
    val = feature1 - feature2;
end

function val = binary2(feature1, feature2)
    val = abs(feature1-feature2);
end

function val = binary3(feature1, feature2)
    val = feature1+feature2;
end
