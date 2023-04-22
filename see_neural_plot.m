%% Example neural data plotting %%
%% Made using Matlab 2022b      %%
%% by: @ElDuvelle               %%
%% Dec 2022                     %%

%% HOW TO
% Download the code repository/folder
% In Matlab, open see_neural_plot & navigate to that folder
% Note: the code may only run Matlab 2022b or later
% Change options if you'd like
% Run see_neural_plot (F5 / Run)


%% Code structure:
% 1. Options
% 2. Plotting parameters
% 3. Data retrieval & preparation
% 4. Plotting preparation
% 5. Actual plotting: Speed, raw LFP, ripple-filtered LFP, theta-filtered LFP,
% Spikes, candidate MUAs.
% 6. General formatting for each subplot
% 7. Saving

% close existing figures
close all

%% 1. Options - try and change some!
options.order_cells = 1; % 1: ordered by median firing time; 0: original order
options.show_cell_names = 0; % 1 to show individual cell names on ylabel
options.show_mua_num = 1; % 1 to show candidate MUA numbers; 0 otherwise
options.very_tight_plot = 0; % 1: no space between plots; 0: some space + title
options.show_rip_env = 0; % 1 to add the ripple z-scored envelope on ripple plot (right axis)
options.save_fig = 0; % if 1: saves the figure in current folder then
% closes it

%% 2. Plotting parameters
params.label_fs = 10;
params.label_fs_small = 6;
params.lfp_col = [0.4 0.4 0.4]; % Grey
params.rip_col = 	[1 0.1 0.1]; % Red
params.rip_env_col = [0.8500 0.3250 0.0980]; % Matlab orange
params.MUA_fill_col = [0.55 0.55 0.55]; % Also Grey
params.MUA_line_col = [0.6350 0.0780 0.1840]; % Matlab red
params.spk_width = 1.4;
% height of each plotted spike
params.offset = 0.4;

%% 3. Retrieve & prepare example data
tr_data = load('example_tr_data.mat');
tr_data = tr_data.tr_data;
% Some data processing that you might find useful

% Restart time at 0 (not necessary)
tr_st = tr_data.lfp_times(1);
tr_data.lfp_times = tr_data.lfp_times-tr_st;
tr_data.pot = tr_data.pot-tr_st;
tr_data.cell_spt = tr_data.cell_spt-tr_st;
tr_data.ripples_se = tr_data.ripples_se-tr_st;
tr_data.MUA_se = tr_data.MUA_se-tr_st;
tr_data.MUA_times = tr_data.MUA_times-tr_st;

% Prepare the ripple intervals for plotting
tr_data.rip_detected = NaN(size(tr_data.lfp_ripples));
for int_i = 1:size(tr_data.ripples_se, 1)  
    int_s = tr_data.ripples_se(int_i, 1);
    int_e = tr_data.ripples_se(int_i, 2);
    these_inds = tr_data.lfp_times >=int_s & tr_data.lfp_times <=int_e;
    % Fill the empty array with data from only detected ripple intervals
    tr_data.rip_detected(these_inds) = tr_data.lfp_ripples (these_inds);
end

% Get number of cells & MUAs 
cell_num = size(tr_data.cell_spt, 1);
MUAs_num = size(tr_data.MUA_se, 1);
% Figure out order of neurons (bottom to top)
if ~options.order_cells
    tr_data.cell_order = 1:cell_num;
else
    % Order the cells by their median firing time (proxy for ordering by 
    % place field location) during "high-speed" (running) 
    med_spt_time = median(tr_data.cell_spt_hs, 2, 'omitnan');
    [~, tr_data.cell_order] = sort(med_spt_time);   
end

% Choose spike colour: I like parula you could play with the others
% https://www.mathworks.com/help/matlab/ref/colormap.html
cell_colors = parula(cell_num); 
% cell_colors = copper(cell_num); 
% cell_colors = hot(cell_num); 
% cell_colors = winter(cell_num); 

%% 4. Plotting preparation
fig_name = ['Neural data for ' tr_data.tr_name];
fig_pos = get(0, 'Screensize'); % full screen
this_fig = figure('Name', fig_name, 'Position', fig_pos);

% Prepare the subplots
num_rows = 11;
if options.very_tight_plot
    layout_spacing_type = 'none'; % No space between plots
else
    layout_spacing_type = 'tight'; % Small space between plots
end
% Tiledlayout is great!
tiledlayout(num_rows, 1, 'TileSpacing', layout_spacing_type); 

% Store each axis in here
all_axes = {};
ind_plot = 1;

%% 5.1 Plot speed
all_axes{ind_plot} = nexttile();
plot(tr_data.pot, tr_data.pov, 'b')
% Show line for low-speed threshold
hold on
yline(tr_data.params.speed_th, 'k:');
ylim([0, 100]);
ylabel({'Speed','(cm/s)'})
if ~options.very_tight_plot
    title('Speed');
end

%% 5.2 Plot Raw LFP
ind_plot = ind_plot+1;
all_axes{ind_plot} = nexttile();
plot(tr_data.lfp_times, tr_data.lfp_raw, 'Color', params.lfp_col);
ylabel({'Raw LFP', '(uV)'})
if ~options.very_tight_plot
    title('Unfiltered Local Field Potential');
end

%% 5.3 Plot Ripple-band LFP + detected ripples
ind_plot = ind_plot+1;
all_axes{ind_plot} = nexttile();
% Show a different plot on left and right axes
% Left axis: ripple-filtered data band
% select this axis

if options.show_rip_env 
    % Note: for some reason, using this makes the detected ripples plotting
    % discontinuously (try with and without)
    yyaxis('left')
end
plot(tr_data.lfp_times, tr_data.lfp_ripples, 'Color', params.lfp_col, ...
    'LineWidth', 0.8);
% Add the detected ripple extents (see above how to create it from
% intervals)
hold on
plot(tr_data.lfp_times, tr_data.rip_detected, 'Color', params.rip_col, ...
    'LineWidth', 0.8);
set(gca, 'YColor', params.lfp_col);
% center on zero
ylims = ylim;
ylim([-ylims(2), ylims(2)])    
ylabel({'Ripple band', '(uV)'})
if ~options.very_tight_plot
    title(sprintf('Ripple-filtered LFP [%d-%d Hz]', ...
        tr_data.params.ripple_band));
end
if options.show_rip_env 
    % Add the ripple z-scored envelope and associated detection threshold
    % on the right axis
    yyaxis('right')
    plot(tr_data.lfp_times, tr_data.ripple_data_zenv, 'Color', ...
         params.lfp_col , 'LineStyle', '-', ...
        'LineWidth', 0.1);
    % Also change color of the y axis accordingly
    ylabel({'z-scored envelope','(sd)'}); 
    set(gca, 'YColor', params.rip_env_col);

    % Show z-score limit that is used to detect ripples
    yline(tr_data.params.ripple_sec_zscore_th, '--', 'Color', params.rip_env_col);
    % center on zero
    ylims = ylim;
    ylim([-ylims(2), ylims(2)])      
end


%% 5.4 Plot Theta-band LFP + theta phase
ind_plot = ind_plot+1;
all_axes{ind_plot} = nexttile();
% Cool function to color a line (with the 3rd argument)
cline(tr_data.lfp_times, tr_data.lfp_theta, tr_data.lfp_theta_phase);
colormap(all_axes{ind_plot}, 'winter')
% example of two-row label
ylabel({'Theta band', '(uV)', '& theta phase'})
if ~options.very_tight_plot
    title(sprintf('Theta-filtered LFP [%d-%d Hz]', ...
        tr_data.params.theta_band));
end

%% 5.5 Plot spikes

plot_height = 6;
ind_plot = ind_plot+1;
% Makes a multi-row subplot
all_axes{ind_plot} = nexttile([plot_height, 1]);

all_y = [];

% Plot spikes from each cell, from the bottom up
for order_i = 1:cell_num
    % get identity of first cell, second cell, etc.
    cell_i = tr_data.cell_order(order_i);
    % Get this cell's spikes
    these_sp = tr_data.cell_spt(cell_i, :);
    % Remove the nans that we had to add to make cell_spt a matrix
    these_sp(isnan(these_sp)) = [];
    this_y = order_i* params.offset*2;
    all_y = [all_y, this_y];
    these_y = ones(size(these_sp)).*this_y;
    these_heights = ones(size(these_sp)).*params.offset;    
    this_color = cell_colors(order_i, :);
    
    % Actual plotting of the spikes
    % We could try to find a 'faster' - less memory-consuming method
    % but for now errorbar seems slightly better than plot or line
    errorbar(these_sp, these_y, these_heights,'LineStyle','none','CapSize',...
        0,'LineWidth', params.spk_width, 'Color', this_color);
    %         plot([these_sp'; these_sp'],[these_y'-params.offset;these_y'+params.offset], 'Color', this_color);
    %         line([these_sp'; these_sp'],[these_y'-params.offset;these_y'+params.offset], 'Color', this_color)
    hold on
end


% Show cell names
if options.show_cell_names
    % Because my cell names have underscores I have to remove the LateX
    % interpreter of the axis
    yaxisproperties= get(gca, 'YAxis');
    yaxisproperties.TickLabelInterpreter = 'none';   
    these_cell_names = tr_data.cell_names(tr_data.cell_order);
    yticks(all_y);
    yticklabels(these_cell_names);
    set(gca, 'fontsize', params.label_fs_small);
end
ylim([0, all_y(end)+1]);
ylabel('Neurons')

if ~options.very_tight_plot
    title('Look at these spikes');
end

%% 5.6 Plot MUA

ind_plot = ind_plot+1;
all_axes{ind_plot} = nexttile();
% MUA firing
h = area(tr_data.MUA_times, tr_data.MUA_fr);
h(1).FaceColor = params.MUA_fill_col;
hold on 
% MUA extent
% counter to alternate display of MUA number on 2 'rows' for improved
% lisibility
this_y_lim = ylim;
this_y_lim = this_y_lim(2);
mua_num_pos = 50/100*this_y_lim;
% 
% if options.very_tight_plot
%     mua_num_pos = +150;
% else
%     mua_num_pos = +100;
% end
MUA_switch = 0;
% Note: could probably avoid the loop?
for MUA_i = 1:MUAs_num   
    % Show the MUA as a red bar below the plot    
    plot(tr_data.MUA_se(MUA_i,:), ones(size(tr_data.MUA_se(MUA_i,:)))*-10, ...
        'Color', params.MUA_line_col, 'LineWidth',4);
    if options.show_mua_num
        % add the MUA number at the start of each MUA period
        % Plot it in bold and slighlty larger for a 'halo' effect
        text(tr_data.MUA_se(MUA_i,1), mua_num_pos - MUA_switch*40,...
            num2str(tr_data.MUA_names(MUA_i)), 'FontSize', 11, ...
            'Color', [1 1 1], 'FontWeight', 'bold');
        text(tr_data.MUA_se(MUA_i,1), mua_num_pos - MUA_switch*40,...
            num2str(tr_data.MUA_names(MUA_i)), 'FontSize', 9, ...
            'Color', params.MUA_line_col);
        MUA_switch = abs(1-MUA_switch);                  

    end
end
% Add more tick marks
set(all_axes{ind_plot}, 'XMinorTick', 'on')
ylabel({'MUA (Hz)';'low speed'});
if ~options.very_tight_plot
    title('Multiunit Activity (at low speeds)');
end

%% 6. General formatting that will apply to each plot
for ax_i = 1:length(all_axes)
    set(all_axes{ax_i},'fontsize', params.label_fs)
    % Do not show the top right axes
    box(all_axes{ax_i}, 'off');
    if ax_i == length(all_axes) % Last axis
        xlabel('Time since start (s)')
    else
        % Since all plots share the same x-axis: remove it
        all_axes{ax_i}.XAxis.Visible = 'off'; 
    end
end
% Add a general title to the plot
sgtitle(fig_name, 'Interpreter', 'none');

% This is maybe the most important: make all plots move together on their
% x-axis
linkaxes([all_axes{:}], 'x')

%% 7. Save figure (in the current folder)
if options.save_fig
    set(this_fig, 'visible', 'on')
    this_fig.InvertHardcopy = 'off'; % forgot why 
    this_fig.Color = 'w';
    disp(['Saving figure to ' fig_name ])
    print(this_fig, '-dpng','-r300', fig_name)              
	% Close the fig to save memory
    close(this_fig)  
end
