classdef Enableable < handle
    % Mixin for component with Enable property

    % Copyright 2020 The MathWorks Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Enable of the component
        Enable (1,1) matlab.lang.OnOffSwitchState = 'on'
        
    end %properties
    
    
    
    %% Internal properties
    properties (AbortSet, Access = protected)
        
        % List of graphics controls to apply to
        EnableableComponents (:,1) matlab.graphics.Graphics
        
    end %properties
    
    
    
    %% Accessors
    methods
        
        function set.Enable(obj,value)
            obj.Enable = value;
            obj.updateEnableableComponents()
        end
        
        function set.EnableableComponents(obj,value)
            obj.EnableableComponents = value;
            obj.updateEnableableComponents()
        end
        
    end %methods
    
    
    
    %% Methods
    methods (Access = protected)
        
        function updateEnableableComponents(obj)
            
            set(obj.EnableableComponents,"Enable",obj.Enable);
            
        end %function
        
    end %methods
    
end %classdef