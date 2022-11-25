function [Y, I, J] = randswap(X, dimmode)
% RANDSWAP - randomly swap elements of a matrix
%
%   For vectors, Y = RANDSWAP(X) randomly swaps the elements of X. For
%   N-D matrices, RANDSWAP(X) randomly swaps the elements along the first
%   non-singleton dimension of X. 
%
%   RANDSWAP(X,DIM) randomly swaps the elements along the dimension
%   DIM. For instance, RANDSWAP(X,1) randomly interchanges the rows of X.
%   If DIM is larger than the dimensions of X RANDSWAP returns X.
%
%   Y = RANDSWAP(X,'partial') swaps the elements for each of the
%   non-singleton dimensions of X separately. Rows are interchanged first,
%   then columns, then planes, etc. In this case, elements that belong to
%   the same row, column, ... stay together.
%
%   Y = RANDSWAP(X,'full') randomly swaps all the elements in X.
%
%   [Y, I, J] = RANDSWAP(...) return index matrices I and J so that 
%   Y = X(I) and X = Y(J). 
%
%   X can be a numeric or a cell array.
%
%   Examples:
%     % randomize a vector
%       RANDSWAP(1:5) % -> e.g. [3 5 1 2 4]
%
%     % Randomize along first non-singleton dimension (rows)
%       X = reshape(1:16,4,4) ; % test matrix
%       RANDSWAP(X) % ->  1     5     9    13
%                   %     3     7    11    15
%                   %     4     8    12    16
%                   %     2     6    10    14
%
%     % Randomize along all dimensions (swap rows, then columns)
%       X = reshape(1:9,3,3) ; % test matrix
%       RANDSWAP(X,'partial') % ->  2    8   5
%                             %     1    7   4
%                             %     3    9   6
%
%     % Swap all elements
%       X = reshape(1:9,3,3) ; % test matrix
%       RANDSWAP(X,'full') % ->  9    5     6
%                          %     4    1     8    
%                          %     7    3     2
%
%   See also RAND, RANDPERM
%   and SHAKE on the File Exchange.
% for Matlab R13
% version 2.0 (nov 2006)
% (c) Jos van der Geest
% email: jos@jasen.nl
% This function as a generalization of SHAKE.
% History:
% 1.0 (oct 2006) Created
% 2.0 (nov 2007) Fixed serious bug with dimmode
error(nargchk(1,2,nargin)) ;
if nargin==1,
    % default: shake along first non-singleton dimension
    dimmode = 0 ;
else
    if ischar(dimmode),
        dimmode = -strmatch(lower(dimmode),{'full','partial'}) ;
        if isempty(dimmode),
            error('String argument should be ''full'' or ''partial''.') ;
        end
    else
        if ~isnumeric(dimmode) || numel(dimmode)~= 1 || fix(dimmode) ~= dimmode || dimmode < 0,
            error('Dimension argument should be a positive integer.') ;
        end
    end
end
% information on X
szX = size(X) ;
ndX = ndims(X) ;
neX = numel(X) ;
% index matrix
I = reshape(1:neX, szX) ; 
if neX > 0,
    switch dimmode,
        case -1, % 'full' - swap all indices
            I(randperm(neX)) = I ;
        case -2,% 'partial' - swap indices of every dimension
            ind = repmat({':'},ndX,1) ;
            SI = find(szX>1) ;
            % loop over all dimensions with a size > 1
            for i = SI,
                ind{i} = randperm(szX(i)) ;
                I = subsref(I,substruct('()',ind)) ;
                ind{i} = ':' ;
            end
        otherwise
            % swap indices of a specific dimension
            if dimmode==0,
                % first non-singleton dimension
                dimmode = min(find(szX>1)) ;
            end
            if dimmode <= ndX && szX(dimmode) > 1,
                % interchange indices in one dimention only
                ind = repmat({':'},ndX,1);
                ind{dimmode} = randperm(szX(dimmode)) ;
                I = subsref(I,substruct('()',ind)) ;
            end
    end    
    % randomize using indices
    Y = X(I) ;
end
if nargout==3,
    J = zeros(szX) ;
    J(I) = 1:neX ;
end
