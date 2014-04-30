function parse = skylineParse(conf, data, method)
% SKYLINEPARSE parses the buildings in a skyline image
%   PARSE = SKYLINEPARSE(CONF, DATA, METHOD) parses the image contained in
%   DATA using the seeds and tiers provided. The METHOD is one of
%   {rectangle, refined, tiered, or standard} specifying the various MRF
%   formulations. If the unary terms are not provided they are computed as
%   a part of the routing.
%
% Output
%   PARSE is a structure containing each building parsed
%
% Author: Subhransu Maji


% Compute unary potentials if they are not provided
if ~isfield(data,'unary')
    disp('Preparing data..');
    data = prepareData(conf, data);
end

% Parse buildings into rectangles
switch lower(method)
    case {'rectangle','refined'}
        parse = rectangleMRF(conf, data);
        
    case 'tiered'
        parse = tieredMRF(conf, data);

    case 'standard'
        parse = standardMRF(conf, data); % parse is a label matrix
    
    otherwise
        disp('Unknown method [options are: rectangle, refined, tiered, standard]');
end     
