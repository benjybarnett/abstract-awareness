function ft_sourceplot_interactive(cfg, varargin)

% FT_SOURCEPLOT_INTERACTIVE provides a rapid way to plot 3D surface
% renderings of pos_time or pos_freq functional data, and interactively
% explore them. One figure is created with surface plots of the individual
% conditions, and by default a plot of the functional data averaged over
% the entire cortex is created over time (or frequency). Users can click in
% the line graph to shift the time point for which the functional data is
% shown in the surface plots. Additionally, users can Shift+Click in the
% surface plots to add a "virtual electrode", for which a new line graph
% figure will be created.
%
% Input data needs to be source+mesh, so has to contain a tri, pos, and one
% functional field plus a time- or frequency axis.
%
% Use e.g. like so:
%
% cfg = [];
% cfg.data_labels = {'Congruent', 'Incongruent'};
% ft_sourceplot_interactive(cfg, sourceFC, sourceFIC);
%
% Configuration options (all optional) include:
%   cfg.parameter       = string, functional parameter to plot. Default = 'pow'.
%   cfg.data_labels     = cell array of strings, describing each data input argument. Default =
%                         {'Input 1',...,'Input N'}
%   cfg.time_label      = string, xlabel for line graphs of functional data. Default = 'Time
%                         (s)' for data with time dimension, 'Frequency (Hz)' for data with
%                         freq dimension.
%   cfg.pow_label       = string, ylabel for line graphs of functional data. Default = 'Current
%                         density (a.u.)'.
%   cfg.clim            = 2-element numeric vector, color limits for surface plots. Default = 
%                         [0 max(data)*0.75], and [-max(data)*0.75, max(data)*0.75] for an
%                         optional last functional input argument reflecting a difference score
%                         (see 'has_diff' option below).
%   cfg.has_diff        = 1x1 logical, default = false. If true, this function will treat the
%                         last data input argument slightly differently from the ones before
%                         it, which is useful in case you wish to plot a difference score in
%                         addition to two per-condition current densities. Specifically, if
%                         true, (1) the line plots generated by this function will not include
%                         the last data input argument; and (2) the colours limits for the
%                         surface plot corresponding to the last data input argument will be
%                         set symmetrically around zero (if cfg.clim is left empty - see
%                         above).
%   cfg.atlas           = string, filename of an atlas to use in generating title strings for
%                         the line graphs corresponding to 'virtual electrodes' placed on the
%                         surface plots. Atlas must be in the coordinate system of the
%                         specified data input arguments. See FT_READ_ATLAS.
%   
%
% Copyright (C) 2019 Eelke Spaak, Donders Institute. e.spaak@donders.ru.nl

% these are used by the ft_preamble/ft_postamble function and scripts
ft_nargin = nargin;
ft_nargout = nargout;

% call the set of 'standard' preambles (see ft_examplefunction for details)
ft_defaults
ft_preamble init
ft_preamble debug
ft_preamble loadvar varargin
ft_preamble provenance varargin
ft_preamble trackconfig

% the ft_abort variable is set to true or false in ft_preamble_init
if ft_abort
  return;
end

% validate the input
if numel(varargin) < 1
  ft_error('this function requires at least one data input argument');
end

% first check whether the first data argument has a brainordinate field, 
% which is to be used as the atlas to provide the labels of the parcels
if isfield(varargin{1}, 'brainordinate')
  cfg = ft_checkconfig(cfg, 'forbidden', 'atlas');
  cfg.atlas = varargin{1}.brainordinate;
end

for k = 1:numel(varargin)
  varargin{k} = ft_checkdata(varargin{k}, 'datatype', {'source+mesh'}, 'feedback', 'yes', 'hasunit', 'yes');
  if k > 1 && (~isequaln(varargin{k}.pos, varargin{1}.pos) || ...
    ~isequaln(varargin{k}.tri, varargin{1}.tri))
    % ensure all input arguments are expressed on the same mesh
    ft_error('input arguments for plotting need to all have identical .pos and .tri');
  end
end

if isfield(varargin{1}, 'time') || isfield(varargin{1}, 'freq')
  % make a selection of the time and/or frequency dimension
  tmpcfg = keepfields(cfg, {'frequency', 'avgoverfreq', 'keepfreqdim', 'latency',...
    'avgovertime', 'keeptimedim', 'showcallinfo'});
  [varargin{:}] = ft_selectdata(tmpcfg, varargin{:});
  % restore the provenance information
  [cfg, varargin{:}] = rollback_provenance(cfg, varargin{:});
end

% validate the cfg options
cfg.parameter = ft_getopt(cfg, 'parameter', 'pow');
cfg.atlas     = ft_getopt(cfg, 'atlas',     []);

% check whether we're dealing with time or frequency data
dimord = getdimord(varargin{1}, cfg.parameter);
if ~ismember(dimord, {'pos_time', 'pos_freq' '{pos}_ori_time'})
  ft_error('functional data must be pos_time or pos_freq');
end

% set a sensible x-axis label for the plots over time or freq
cfg.time_label = ft_getopt(cfg, 'time_label', []);
if isempty(cfg.time_label)
  if strcmp(dimord, 'pos_time')
    cfg.time_label = 'Time (s)';
  elseif strcmp(dimord, 'pos_freq')
    cfg.time_label = 'Frequency (Hz)';
  end
end

if strcmp(dimord, 'pos_time') || strcmp(dimord, '{pos}_ori_time')
  xdat = varargin{1}.time;
elseif strcmp(dimord, 'pos_freq')
  xdat = varargin{1}.freq;
end

% optionally load an atlas
if ~isempty(cfg.atlas)
  [cfg.atlas, varargin{:}] = handle_atlas_input(cfg.atlas, varargin{:});
end

% allow for a user specified colormap of the non-diff surfaces
cfg.colormap = ft_getopt(cfg, 'colormap');

% other defaults are set in the lower-level object

% fetch the functional data
data = cellfun(@(x) x.(cfg.parameter), varargin, 'uniformoutput', false);
if isa(data{1}, 'cell') && size(data{1},1)==size(varargin{1}.pos,1)
  % convert to matrix, probably mom or so is requested
  for m = 1:numel(data)
    nsmp = max(cellfun('size', data{m}, 2));
    inside = ~cellfun(@isempty, data{m});
    tmp  = nan(numel(data{m}),nsmp);
    tmp(inside,:) = cat(1,data{m}{:});
    data{m} = tmp;
  end  
end
% set up the arguments
keyval = ft_cfg2keyval(cfg);
keyval = [keyval {'tri', varargin{1}.tri, 'pos', varargin{1}.pos, 'data', data, 'time', xdat, 'unit', varargin{1}.unit}];

% and launch the viewer
viewer = ft_plot_mesh_interactive(keyval{:});
viewer.show();

ft_postamble debug
ft_postamble trackconfig
ft_postamble provenance
ft_postamble savefig

end