function parse = skylineParse(conf, data, method)
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
