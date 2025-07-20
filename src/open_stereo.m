% NOTICE: Certain components are under restricted access during peer review.
% Please contact the authors or the journal to request 
% full access to this file: open_stereo.m


% Part of OPEN-Stereology Core Function suite – Reviewer Copy ONLY
%
% Copyright (c) 2024, OPEN-Stereology
% Licensed under the PolyForm Noncommercial License 1.0.0
% https://polyformproject.org/licenses/noncommercial/1.0.0
%
% Developed by the OPEN-Stereology project team at UC San Diego (UCSD).
% For more information, see: https://github.com/OPEN-Stereology
%
% ???????????????????????????????????????????????????????????????
% This version is provided for peer review only and is not yet
% released for general use. Redistribution, reuse, or modification
% is prohibited outside the scope of scholarly evaluation by
% designated reviewers or journals.
%
% This software will be made publicly available upon publication.
% ???????????????????????????????????????????????????????????????
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

function varargout = open_stereo_dummy(varargin)
 
msg = sprintf([ ...
    'NOTICE: OPEN-Stereology Reviewer Copy\n\n' ...
    'Certain components are under restricted access during peer review.\n' ...
    'If you are a reviewer attempting to evaluate this tool:\n'...
    'Please contact the authors or the journal to request access to open_stereo.m file.\n' ...
    'All other components are available online for download otherwise. \n\n' ...
    'This version is not released for general use. Redistribution,\n' ...
    'reuse, or modification is prohibited outside of scholarly review.\n\n' ...
    'UC San Diego • OPEN-Stereology Project Team' ]);

helpdlg(msg, 'OPEN-Stereology – Reviewer Copy');

