classdef FontColorable < handle
    % Mixin for component with Font color (but no other editable font properties)

    % Copyright 2020 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Font color
        FontColor (1,3) double {wt.validators.mustBeBetweenZeroAndOne} = [0 0 0]
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Access = protected)
        
        % List of graphics controls to apply to
        FontColorableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.FontColor(obj,value)
            obj.FontColor = value;
            obj.updateFontColorableComponents()
        end
        
        function set.FontColorableComponents(obj,value)
            obj.FontColorableComponents = value;
            obj.updateFontColorableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateFontColorableComponents(obj)
            
                hasFontColorProp = isprop(obj.FontColorableComponents,"FontColor");
                hasForegroundColorProp = ~hasFontColorProp & ...
                    isprop(obj.FontColorableComponents,"ForegroundColor");
                
                set(obj.FontColorableComponents(hasFontColorProp),"FontColor",obj.FontColor);
                set(obj.FontColorableComponents(hasForegroundColorProp),"ForegroundColor",obj.FontColor);
            
        end %function
        
    end %methods
    
end %classdef