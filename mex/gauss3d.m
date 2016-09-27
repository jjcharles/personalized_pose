function J = gauss3d(I,sigma,varargin)

if sigma>0
	kw=ceil(3*sigma);
	k=exp(-(-kw:kw).^2/(2*sigma^2))/sqrt(2*pi*sigma^2);
	J=imfilter(I,k,varargin{:});
    J=imfilter(J,k',varargin{:});
    J=imfilter(J,reshape(k,1,1,[]),varargin{:});
else
    J=I;
end

