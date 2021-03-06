classdef (Sealed) Toolbar < wt.abstract.BaseWidget & wt.mixin.TitleColorable ...
        & wt.mixin.FontStyled
    % A configurable toolbar
    
    % Copyright 2020 The MathWorks Inc.
    
    %% Events
    events
        
        % Event triggered when a button is pushed
        ButtonPushed
        
    end %events
    
    
    
    %% Public properties
%     properties (AbortSet, UsedInUpdate = false)
    properties (AbortSet)
        
        % Sections that are part of the toolbar
        Section (:,1) wt.toolbar.HorizontalSection
        
    end %properties
    
    
    properties (Dependent, AbortSet, UsedInUpdate = false)
        
        % Color of the dividers between horizontal sections
        DividerColor
        
    end %properties
    
    
    properties (AbortSet, UsedInUpdate = false)
        
        % Callback triggered when a button is pushed
        ButtonPushedFcn function_handle
        
    end %properties
    
    
    
    %% Internal Properties
    properties (GetAccess = protected, SetAccess = private)
        
        % The listbox control
        ListBox (1,1) matlab.ui.control.ListBox
        
        % The label for each section
        SectionLabel (:,1) matlab.ui.control.Label
        
        % Buttons used when space is limited
        SectionButton (:,1) matlab.ui.control.Button
        
        % The dummy section filling up remaining space
        DummySection (:,1) matlab.ui.container.Container
        
        % Listen to section changes
        SectionChangedListener event.listener
        
        % Listen to size changes
        SizeChangedListener event.listener
        
        % Listen to button pushes in sections
        ButtonPushedListener event.listener
        
        % Sections that are open outside the toolbar
        OpenSection wt.toolbar.HorizontalSection
        
    end %properties
    
    
    properties (Constant, Access = protected)
    
        % The down arrow mask for the button icons
        BUTTON_MASK (:,:) logical = sectionButtonIconMask()
        
    end %properties
    
    
    
    %% Protected methods
    methods (Access = protected)
        
        function setup(obj)
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();
            
            % Configure style defaults
            obj.FontColor = [1 1 1] * 0.3;
            obj.TitleColor = [1 1 1] * 0.5;
            
            % Configure grid
            obj.Grid.Padding = [0 0 0 0]; %If changed, modify updateLayout!
            obj.Grid.RowHeight = {'1x'};
            obj.Grid.ColumnWidth = {};
            obj.Grid.ColumnSpacing = 1; %If changed, modify updateLayout!
            
            obj.Grid.RowHeight = {'1x',15};
            obj.Grid.ColumnWidth = {'1x'};
            obj.Grid.RowSpacing = 0;
            obj.Grid.BackgroundColor = [1 1 1]*0.5;
            
            % Add a dummy section to color the empty space
            obj.DummySection = uicontainer(obj.Grid);
            %obj.DummySection = uipanel(obj.Grid);
            %obj.DummySection.BorderType = 'none';
            %obj.DummySection.Title = '';
            obj.DummySection.Layout.Row = [1 2];
            obj.BackgroundColorableComponents = obj.DummySection;
            
            % Listen to size changes
            obj.SizeChangedListener = event.listener(obj,'SizeChanged',...
                @(h,e)obj.updateLayout());
            
        end %function
        
        
        function update(obj)
            % Update the toolbar
             
            % Update each section
            numSections = numel(obj.Section);
            for sIdx = 1:numSections
                
                % Do we need to add more labels/buttons?
                if sIdx > numel(obj.SectionLabel)
                    obj.SectionLabel(sIdx) = uilabel(obj.Grid);
                    obj.SectionButton(sIdx) = uibutton(obj.Grid);
                end
                
                % Update each label
                obj.SectionLabel(sIdx).Parent = obj.Grid;
                obj.SectionLabel(sIdx).Layout.Row = 2;
                obj.SectionLabel(sIdx).Layout.Column = sIdx;
                obj.SectionLabel(sIdx).BackgroundColor = obj.BackgroundColor;
                obj.SectionLabel(sIdx).FontSize = 10;
                obj.SectionLabel(sIdx).HorizontalAlignment = 'center';
                obj.SectionLabel(sIdx).Text = upper(obj.Section(sIdx).Title);
                
                % Update each button
                obj.SectionButton(sIdx).Parent = obj.Grid;
                obj.SectionButton(sIdx).Layout.Row = [1 2];
                obj.SectionButton(sIdx).Layout.Column = sIdx;
                obj.SectionButton(sIdx).BackgroundColor = obj.BackgroundColor;
                obj.SectionButton(sIdx).FontSize = 10;
                obj.SectionButton(sIdx).IconAlignment = 'bottom';
                obj.SectionButton(sIdx).WordWrap = 'on';
                obj.SectionButton(sIdx).Visible = 'off';
                obj.SectionButton(sIdx).ButtonPushedFcn = @(h,e)obj.onPanelButtonPushed(e);
                obj.SectionButton(sIdx).Text = upper(obj.Section(sIdx).Title);
                
                % Update each section
                if ~isequal(obj.Section(sIdx).Parent, obj.Grid)
                    obj.Section(sIdx).Parent = obj.Grid;
                end
                obj.Section(sIdx).Layout.Row = 1;
                obj.Section(sIdx).Layout.Column = sIdx;
                
            end %for
            
            % Remove any extra labels/buttons
            numLabels = numel(obj.SectionLabel);
            if numLabels > numSections
                idxRemove = (numSections+1):numLabels;
                delete(obj.SectionLabel(idxRemove));
                obj.SectionLabel(idxRemove) = [];
                delete(obj.SectionButton(idxRemove));
                obj.SectionButton(idxRemove) = [];
            end
            
            % Unparent removed components
            isHorizontalSection = get(obj.Grid.Children,'Type') == ...
                lower("wt.toolbar.HorizontalSection");
            oldSections = obj.Grid.Children(isHorizontalSection);
            removedSections = setdiff(oldSections, obj.Section);
            set(removedSections,'Parent',[]);
            
            % Update component style lists
            obj.TitleColorableComponents = obj.SectionLabel;
            obj.BackgroundColorableComponents = [
                obj.Section
                obj.SectionButton
                obj.SectionLabel
                obj.DummySection
                ];
            obj.FontStyledComponents = [
                obj.Section
                obj.SectionButton
                ];
            
            % Update listeners
            obj.ButtonPushedListener = event.listener(obj.Section,...
                'ButtonPushed',@(h,e)obj.onButtonPushed(e));
            obj.SectionChangedListener = event.listener(obj.Section,...
                'PropertyChanged',@(h,e)obj.update());
            
            % Update the layout
            obj.updateLayout();
            
        end %function
        
        
        function updateLayout(obj)
            % Dynamically configure the toolbar based on space
             
            % Close any open sections
            obj.closePanel();
            
            % Return if no sections to show
            if isempty(obj.Section)
                return
            end
            
            % How many sections
            numSections = numel(obj.Section);
            
            % Total available width to place sections
            pos = getpixelposition(obj);
            wAvail = pos(3);
            
            % Subtract off needed spacing between components
            spacingNeeded = numSections - 1;
            wAvail = wAvail - spacingNeeded;
            
            % Calculate the width options
            sectionWidth = [obj.Section.TotalWidth];
            minSectionWidth = [obj.Section.MinimizedWidth];
            widthOptions = cumsum(sectionWidth) + ...
                flip( cumsum([0 minSectionWidth(1:end-1)]) ) ;
            
            % Which panels can be fully shown?
            isFullyShown = widthOptions <= wAvail;
            
            % Loop on each obj.Section
            for idx = 1:numel(obj.Section)
                
                % If unparented, fix it
                if ~isequal(obj.Section(idx).Parent, obj.Grid)
                    obj.Section(idx).Parent = obj.Grid;
                    obj.Section(idx).Layout.Row = 1;
                    obj.Section(idx).Layout.Column = idx;
                end
                
                % Toggle visibilities
                obj.Section(idx).Visible = isFullyShown(idx);
                if idx <= numel(obj.SectionLabel)
                    obj.SectionLabel(idx).Visible = isFullyShown(idx);
                    obj.SectionButton(idx).Visible = ~isFullyShown(idx);
                end
                
            end %for idx = 1:numel(section)
            
            % Update the grid column widths
            sectionWidth(~isFullyShown) = minSectionWidth(~isFullyShown);
            obj.Grid.ColumnWidth = [num2cell(sectionWidth),'1x'];
            
            % Place the dummy section
            obj.DummySection.Layout.Column = numSections + 1;
            
        end %function
        
        
        function updateBackgroundColorableComponents(obj)
            
            % Update button icons
            obj.updateButtonIcons();
            
            % Override the default, not setting the Grid background
            hasProp = isprop(obj.BackgroundColorableComponents,'BackgroundColor');
            set(obj.BackgroundColorableComponents(hasProp),...
                "BackgroundColor",obj.BackgroundColor);
            
        end %function
        
        
        function updateFontStyledComponents(obj,varargin)
            
            % Update button icons
            obj.updateButtonIcons();
            
            % Call the superclass method
            obj.updateFontStyledComponents@wt.mixin.FontStyled(varargin{:});
            
        end %function
        
        
        function updateButtonIcons(obj)
            % Color the down arrow on buttons the same as font color
            
            % Has foreground or background color changed?
            if ~isempty(obj.SectionButton) && ( ...
                    ~isequal(obj.SectionButton(end).FontColor, obj.FontColor) || ...
                    ~isequal(obj.DummySection.BackgroundColor, obj.BackgroundColor) )
                
                % Create the button icon
                icon = cell(1,3);
                for cIdx = 1:3
                    icon{cIdx} = ~obj.BUTTON_MASK * obj.BackgroundColor(cIdx);
                    icon{cIdx}(obj.BUTTON_MASK) = obj.FontColor(cIdx);
                end
                icon = cat(3,icon{:});
                
                % Update the icon on each button
                set(obj.SectionButton,'Icon',icon);
                
            end %if
            
        end %function
        
        
        function onButtonPushed(obj,evt)
            
            % Close any open panel
            obj.closePanel();
            
            % Trigger event
            notify(obj,"ButtonPushed",evt);
            
            % Trigger callback
            obj.callCallback("ButtonPushedFcn",evt);
            
        end %function
        
    end %methods
    
    
    
    %% Private methods
    methods (Access = private)
        
        
        function onPanelButtonPushed(obj,e)
            
            % Which panel?
            sectionButton = e.Source;
            section = obj.Section(obj.SectionButton == sectionButton);
            
            % Is it the button for a panel that's already open? If so, just
            % close it and return
            if isequal(section, obj.OpenSection)
               obj.closePanel();
               return
            end
            
            % Close any open sections
            obj.closePanel();
            
            
            % Where are things located now?
            bPos = getpixelposition(sectionButton, true);
            fig = ancestor(obj,'figure');
            figPos = getpixelposition(fig);
            figureWidth = figPos(3);
            
            % Where should the panel go?
            panelX = bPos(1);
            panelWidth = section.TotalWidth;
            panelHeight = bPos(4) - obj.Grid.RowHeight{2} - obj.Grid.RowSpacing;
            panelY = bPos(2) - panelHeight;
            
            % Adjust panel X position if needed
            panelRightEdge = panelX + panelWidth;
            if panelRightEdge > figureWidth
                panelX = figureWidth - panelWidth;
            end
            
            % Now, position and show the panel as a dropdown
            panelPos = [panelX panelY panelWidth panelHeight];
            obj.OpenSection = section;
            section.Parent = fig;
            setpixelposition(section, panelPos, true);
            section.Visible = 'on';
            
        end %function
        
        
        function closePanel(obj)
            
            % Is a section panel open?
            if ~isempty(obj.OpenSection)
                
                obj.OpenSection.Parent = [];
                obj.OpenSection(:) = [];
                
            end %if ~isempty(obj.OpenSection)
            
        end %function
        
    end %methods
    

    %% Accessors
    methods
        
        function value = get.DividerColor(obj)
            value = obj.Grid.BackgroundColor;
        end
        function set.DividerColor(obj,value)
            obj.Grid.BackgroundColor = value;
        end
        
    end %methods
    
    
end % classdef


%% Helper Functions

function mask = sectionButtonIconMask()

mask = logical([
    0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0
    1 1 1 1 1 1 1 1 1 
    0 1 1 1 1 1 1 1 0 
    0 0 1 1 1 1 1 0 0 
    0 0 0 1 1 1 0 0 0 
    0 0 0 0 1 0 0 0 0 
    ]);

end %function