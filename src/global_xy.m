
% Part of OPEN-Stereology Core Function suite – Reviewer Copy ONLY
%
% Copyright (c) 2021-2025, OPEN-Stereology
% Licensed under the PolyForm Noncommercial License 1.0.0
% https://polyformproject.org/licenses/noncommercial/1.0.0
%
% Developed by the OPEN-Stereology project team at UC San Diego (UCSD).
% For more information, see: https://github.com/OPEN-Stereology
%
% ───────────────────────────────────────────────────────────────
% This version is provided for peer review only and is not yet
% released for general use. Redistribution, reuse, or modification
% is prohibited outside the scope of scholarly evaluation by
% designated reviewers or journals.
%
% This software will be made publicly available upon publication.
% ───────────────────────────────────────────────────────────────
%
% NO WARRANTY: This code is provided “as is” without warranty of any kind,
% express or implied. The authors and affiliated institutions disclaim all
% liability for any use, misuse, or interpretation of the software.
%
% DO NOT POST OR CIRCULATE WITHOUT PERMISSION.


% SYSTEM CONFIGURATION NOTICE:
%
% This version of OPEN-Stereology software includes system-specific
% parameters and hardware control commands that reflect the configuration
% used in the accompanying manuscript.
%
% These parameters include (but are not limited to):
%   - Camera type and resolution
%   - Stage driver command formats and motor interface
%   - Objective magnification calibration values
%   - Image acquisition timing and file naming conventions
%   - Directory paths for the data is being stored
%
% These settings are not guaranteed to be compatible with other systems.
% Users intending to adapt this software for their own stereology setup
% must review and modify all system-dependent variables, driver commands,
% and calibration constants accordingly. Proper adaptation will require
% access to and careful review of the manuscript associated with this
% software.


function [xg xii]=global_xy(xm,xi,handles,magIndx)

magIndx_ref=3;

img=imread([handles.myData.mrArray(1).http 'out.jpg' ]);
y=xi(1);x=xi(2);
xm1=[xm(1);xm(2)];


 
if isfield (handles.myData.pointList, 'K')
   
    K= handles.myData.Calib_K(magIndx_ref).K;       % K10 reference K where everything is in reference to
    %handles.myData.pointList(1).K;                 % Previous version of things
    L=handles.myData.Calib( magIndx_ref,magIndx).L; % L to bring it to x10 (3) ref frame from magIndx
    
    xg=[xm1;1] +K*L*[y;x;1]; % Global coords of point [xm,xi,magIndx]
    % xg=[xm1 ] +K*[y;x ];
    xg=[xg(1) xg(2)]';
    xii=[size(img,2);size(img,1)]/2;
    
else
    xg=xm1;
    xii=xi;
    
end
 

function [xg xii]=global_xy_center(xm,xi,handles)
%xm : stepper motor x y
%xi : image x y

alpha=handles.myData.pointList(1).alpha;


img=imread([handles.myData.mrArray(1).http 'out.jpg' ]);
y=xi(1);x=xi(2);
xm1=[xm(1);xm(2)];
if isfield (handles.myData.pointList, 'K')
    % K=(1/alpha)*handles.myData.pointList(1).K;
    K= handles.myData.pointList(1).K
    xg=[xm1;1] +K*[y;x;1];
    xg=[xg(1) xg(2)]';
    xii=[size(img,2);size(img,1)]/2;
else
    xg=xm1;
    xii=xi;
    
end
