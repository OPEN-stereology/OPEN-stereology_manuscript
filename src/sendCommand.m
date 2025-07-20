% OPEN-Stereology Core Function – Reviewer Copy
%
% Copyright (c) 2024, OPEN-Stereology
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

function msg=sendCommand(s1,str)
 

if (s1==0)
out=instrfind('Type','serial')

if ~isempty(out)
    
    fclose(out);
    
delete(out);
end

 s1 = serial('COM1','BaudRate',38400,'DataBits',8,'StopBits',1);
fopen(s1);
end

moving=1;
pos(1)=-1;

if s1.BytesAvailable>0
    fread(s1,s1.BytesAvailable);
end

if nargin==1
    str='STAGE';
end

fprintf(s1,[str,13]);

k=0;

while (s1.BytesAvailable==0) & k<1300
 
    ds=1;
    while abs(ds)>0
        so=s1.BytesAvailable;
        for i=1:10
            s=s1.BytesAvailable;
        end
        ds=s-so;
    end
    
    k=k+1;
end
 
msg=char(fread(s1,s1.BytesAvailable))' ;
pause(0.5);
