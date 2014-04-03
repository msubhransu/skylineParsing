function [overlaps, matchId] = evalLabels(predicted, true, isfg, match)

% Assume that the labels
numLabels = sum(isfg);