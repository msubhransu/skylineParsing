function parse = skylineParse(conf, data, method)

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
        
