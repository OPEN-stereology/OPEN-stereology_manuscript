function [T,dx,dy]=getAffine(img2,img3)
 
 tic  

c=0;
M10=5;
while c<0.1 
    
[dx,dy,c]=getdxdy4(img2,img3,M10) ;
M10=M10+5;
if (M10>50)
    keyboard
end

end




% [dx1,dy1]=getdxdy(img2,img3,10) 
% keyboard
h=toc
% 
% tran=0;
% 
% if (dx==0)
%     img3=img3';
%     img2=img2';
%     
%     img3o=permute(img3o, [2 1 3]) ;
% img2o=permute(img2o, [2 1 3]) ;
% 
% % 
% %     img3o=img3o';
% %     img2o=img2o';
%     tran=1;
%     %[dx,dy]=getdxdy(img2,img3);
%     dx=dy;
%     dy=0;
% end
% 
% 
% % if tran==1
% %     figure,imagesc(img2);
% % figure,imagesc(img2);
% % title(['dx= ' , num2str(dx)])
% % hold on;
% rev=0;
% if (dx>0)
%     dx=abs(dx)-1;
%       imgx=img2;
%       imgxo=img2o;
%     
%     
%     img2=img3;
%     img2o=img3o;
%     img3=imgx;
%     img3o=imgxo;
%     rev=1;
% % imgg1=[img2(:,1:dx)*0 img2]; 
% % imgg2= [img3 img2(:,1:dx)*0 ]; 
% % 
% % plot([1 nn-dx],[mm/2 mm/2],'g','linewidth',10);
% % plot([ nn-dx nn  ],[mm/2 mm/2],'r','linewidth',10);
% 
% 
% elseif (dx<0)
%     dx=abs(dx)-1;
%   
% %    imgg1=[ img2 img2(:,1:dx)*0]; 
% % imgg2= [img2(:,1:dx)*0  img3];  
% % 
% % plot([1  dx],[mm/2 mm/2],'r','linewidth',10);hold all
% % plot([dx  nn   ],[mm/2 mm/2],'g','linewidth',10);
% 
% 
% % plot([1 nn-dx],[mm/2 mm/2],'g','linewidth',10);
% % plot([ nn-dx nn  ],[mm/2 mm/2],'r','linewidth',10);
% end
% title(num2str([dx dy h]));
% 
% % An->(n-1)
 
T=maketform('affine',double([1 0 0;0 1 0;  -dx    -dy 1])) 
