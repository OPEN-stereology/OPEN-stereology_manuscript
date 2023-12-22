load   Calib_L  ;
handles.myData.Calib=Calib_L;
disp('Loaded Calibration L from file');   
    

% Load Calibration K K1 will load one not effected by this program's save
load   Calib_K_Backup1; 
 
imgd='I:\M_D17-12_slide04_section02_Region_ChAT-MS'
load('C:\GoogleDrive2\stereoArray_M_D17-12_slide04_section02_Region_ChAT-MS.mat')
load(fullfile(imgd,'stereo.mat'))
figure(1000)
for i=1:length(stereo)
    
    if ~isempty(stereo(i).xy)
        xy=stereo(i).xy;
        
        
        plot(xy(:,1),xy(:,2),'.')
        hold on
    end
end



pts=[];
pts1=[];
good_list=stereoArray(1).goodList;
for i=good_list
    pts=[pts;stereoArray(1).pointList(i).xyzg(1),stereoArray(1).pointList(i).xyzg(2)]
  pts1=[pts1;stereoArray(1).pointList(i).xyz(1),stereoArray(1).pointList(i).xyz(2)]
 
end
shg

%plot(pts1(:,1),pts1(:,2),'r'),hold on
plot(pts(:,1),pts(:,2),'b')