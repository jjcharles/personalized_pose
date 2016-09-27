%function to plot particles on img input
function hndl = draw(particle,img,hndl)
   
    if nargin < 3
        hndl{1} = gcf;
        hndl{2} = imagesc(img); 
        axis image
        hold on
    else
        figure(hndl{1});
        set(hndl{2},'cdata',img);
    end
    
    
    
    X = cat(1,particle(:).x);
    Y = cat(1,particle(:).y);
    W = cat(1,particle(:).weight);
    W = floor(W./(max(W(:))+eps)*99)+1;
    clr = jet(100);
    
    %plot particles
    for i = 1:numel(X)
        if nargin < 3
            hndl{i+2} = plot(X(i),Y(i),'wo','markersize',5,'markerfacecolor',clr(W(i),:),'linewidth',1);
        else
            set(hndl{i+2},'xdata',X(i),'ydata',Y(i),'markerfacecolor',clr(W(i),:));
        end
    end
    
    %plot prediction
    P = pfilter.get_prediction(particle);
    if nargin < 3
        hndl{i+3} = plot(P(:,1),P(:,2),'kx','markersize',20,'linewidth',4);
        hndl{i+4} = plot(P(:,1),P(:,2),'wx','markersize',15,'linewidth',2);
    else
        set(hndl{i+3},'xdata',P(:,1),'ydata',P(:,2))
        set(hndl{i+4},'xdata',P(:,1),'ydata',P(:,2))
    end