classdef EventMarker < handle
    
    %%%%%%%%%%%%%%%% public properties %%%%%%%%%%%%%%%%%%
    properties (Access = public)
        main_ax %axis with markers
        label_ax; %Axis with labels
        
        %Create bounds on area placement
        xbounds
        ybounds
        
        %List of types of events
        event_types
        
        %List of added events
        event_list = [];
        
        %Colors for the different selections
        colors
        
        %fontsize
        label_fontsize
        
        %callback for motion
        eventMotionCallback
        
        %ID of selected object
        selected_ind = [];
    end
    
    %%%%%%%%%%%%%%%% private properties %%%%%%%%%%%%%%%%%%
    properties (Access = private)
        main_fig %Main figure
        
        
        check_double_click=[]; %Check if there's a double click
        
        current_object=[]; %Current_object selected
        current_object_ind=[]; %Index of selected object
        
        use_imline = ~any(which('drawline.m'));
    end
    
    %%%%%%%%%%%%%%% public methods %%%%%%%%%%%%%%%%%%%%%%
    methods (Access = public)
        
        %***********************************************
        %             CONSTRUCTOR METHOD
        %***********************************************
        
        %obj = EventMarker(event_axis, xbounds, ybounds, event_types, event_list, line_colors, font_size, motioncallback)
        function obj = EventMarker(varargin)
            %Check for image processing toolbox
            if ~license('test','image_toolbox')
                error('The Image Processing Toolbox is required to run EventMarker');
            end
            
            %Set up default param values
            args={gca, xlim(gca), ylim(gca), [], [], get(gca,'colororder'), 12, []};
            args(~cellfun('isempty',varargin)) = varargin(~cellfun('isempty',varargin));
            [obj.main_ax,obj.xbounds,obj.ybounds, obj.event_types, obj.event_list, obj.colors, obj.label_fontsize, obj.eventMotionCallback]=args{:};
            
            %Set up main figure
            obj.main_fig=get(obj.main_ax,'parent');
            %Callback for clicks
            set(obj.main_fig,'units','normalized','windowbuttondownfcn',@obj.clickcallback);
            
            %Set up main axis
            set(obj.main_ax,'nextplot','replacechildren','units','normalized');
            
            %Create new axis for text labels
            pos=get(obj.main_ax,'position');
            pos(2)=pos(2)+pos(4)+.02;
            pos(4)=1e-9;
            
            obj.label_ax=axes('position',pos,'visible','off');
            linkaxes([obj.main_ax obj.label_ax'],'x');
            
            iptPointerManager(obj.main_fig, 'enable');
        end
        
        %-----------------------------------------------------------
        %                ADD AN EVENT TYPE
        %-------------------------------------------------------
        function add_event_type(obj,event_obj)
            %Start the list if empty
            if isempty(obj.event_types)
                obj.event_types=event_obj;
            else
                %Check if the name is unique
                if any(strcmpi({obj.event_types.name},event_obj.name))
                    warning(['Event type not added. Name "' event_obj.name '" already exists.']);
                    return;
                end
                
                %Check if the ID is unique
                if any([obj.event_types.type_ID]==event_obj.type_ID)
                    warning(['Event type "' event_obj.name '" not added. ID "' num2str(event_obj.type_ID) '" already exists.']);
                    return
                end
                
                %If event type is unique then add to event_types list
                obj.event_types(end+1)=event_obj;
            end
        end
        
        
        %-----------------------------------------------------------
        %               GET EVENT LIST
        %-----------------------------------------------------------
        function [etimes, etypes, eIDs, isregion] = get_events(obj)
            etypes = [obj.event_list.type_ID];
            eIDs = [obj.event_list.event_ID];
            isregion = [obj.event_list.region];
            etimes_raw = cellfun(@(x)x.XData(1),{obj.event_list(~isregion).obj_handle});
            etimes_raw = [etimes_raw cellfun(@(x)x.Position(1),{obj.event_list(isregion).obj_handle})];
            [etimes, inds]= sort(etimes_raw);
            etypes = etypes(inds);
            eIDs = eIDs(inds);
            isregion = isregion(inds);
        end
        
        %-----------------------------------------------------------
        %                    MARK EVENT
        %-----------------------------------------------------------
        function new_event = mark_event(obj, varargin)
            if length(varargin) == 2
                obj.mark_events(varargin{:});
                return;
            else
                event_type_id = varargin{1};
            end
            
            
            %Check for errors
            if isempty(obj.event_types)
                error('No event types to add');
            end
            
            event_ind =[obj.event_types.type_ID]==event_type_id;
            if ~any(event_ind)
                error(['Event ID ' num2str(event_type_id) ' is invalid']);
            end
            
            %Create new event object
            new_event=obj.event_types(event_ind);
            
            %Check to see if the new event is a region or a single-time event
            if new_event.region
                %Get data if event is being user defined
                if nargin<3
                    %Pick click the start and end points
                    points = obj.get_clicks(2);
                    
                    xstart = [points(1,1) points(2,1)];
                    ystart = [points(1,2) points(2,2)];
                    
                    %Get rectangle parameters
                    if new_event.constrain
                        rect_pos=[min(xstart) obj.ybounds(1) abs(diff(xstart)) abs(diff(obj.ybounds))];
                    else
                        rect_pos=[min(xstart) min(ystart) abs(diff(xstart)) abs(diff(ystart))];
                    end
                else
                    rect_pos=position;
                end
                
                %Create the rectangle
                new_event.obj_handle=rectangle('parent',obj.main_ax,'position',rect_pos,'edgecolor',obj.colors(event_ind,:),'linewidth',4);
                
                %Get the x-axis location for the text
                obj_middle=mean([rect_pos(1) (rect_pos(1)+rect_pos(3))]);
            else %If new event is a single-time event
                
                %Get data if event is being user defined
                if nargin<3
                    %Pick click the moment for event
                    pos = obj.get_clicks(1);
                    xpos = pos(1);
                    
                else
                    xpos=position;
                end
                
                %Create the vertical line
                line_x=[xpos xpos];
                line_y=ylim(obj.main_ax);
                %Create a vertical line
                new_event.obj_handle=line(line_x,line_y,'parent',obj.main_ax,'color',obj.colors(event_type_id,:),'linewidth',4);
                
                %Get the x-axis location for the text
                obj_middle=xpos;
            end
            
            %Create text object
            if ~isempty(new_event.name)
                new_event.label_handle=text(obj.label_ax, obj_middle,0,new_event.name,'fontsize',obj.label_fontsize,'verticalalignment','top','color','k','horizontalalignment','center');
            end
            
            if new_event.region
                %set(new_event.label_handle,'edgecolor','k'); Uncomment for box
                if new_event.constrain
                    set(new_event.label_handle,'verticalalignment','bottom');
                end
            end
            
            %Create random event ID
            new_event.event_ID = randi(intmax);
            
            %Add the new line to the obj
            obj.event_list=[obj.event_list new_event];
            
            %Revert to original cursor
            set(gcf,'Pointer','arrow');
        end
        
        %-----------------------------------------------------------
        %                  MARK LOTS OF EVENTS
        %-----------------------------------------------------------
        function new_event = mark_events(obj, event_type_id, position)
            %Check for errors
            if isempty(obj.event_types)
                error('No event types to add');
            end
            
            event_ind =[obj.event_types.type_ID]==event_type_id;
            if ~any(event_ind)
                error(['Event ID ' num2str(event_type_id) ' is invalid']);
            end
            
            num_events = size(position,1);
            old_list_size = length(obj.event_list);
            
            if ~isempty(obj.event_list)
            obj.event_list(old_list_size + num_events) = nan;
            end
            
            for ii = 1:num_events
                %Create new event object
                new_event=obj.event_types(event_ind);
                
                %Check to see if the new event is a region or a single-time event
                if new_event.region
                    rect_pos=position(ii,:);
                    
                    
                    %Create the rectangle
                    new_event.obj_handle=rectangle('parent',obj.main_ax,'position',rect_pos,'edgecolor',obj.colors(event_ind,:),'linewidth',4);
                
                    %Get the x-axis location for the text
                    obj_middle=mean([rect_pos(1) (rect_pos(1)+rect_pos(3))]);
                else %If new event is a single-time event
                    
                    xpos=position(ii,1);
                    
                    %Create the vertical line
                    line_x=[xpos xpos];
                    line_y=ylim(obj.main_ax);
                    %Create a vertical line
                    new_event.obj_handle=line(line_x,line_y,'parent',obj.main_ax,'color',obj.colors(event_type_id,:),'linewidth',4);
                    
                    %Get the x-axis location for the text
                    obj_middle=xpos;
                end
                
                %Create text object
                if ~isempty(new_event.name)
                    new_event.label_handle=text(obj.label_ax, obj_middle,0,new_event.name,'fontsize',obj.label_fontsize,'verticalalignment','top','color','k','horizontalalignment','center');
                end
                
                if new_event.region
                    %set(new_event.label_handle,'edgecolor','k'); Uncomment for box
                    if new_event.constrain
                        set(new_event.label_handle,'verticalalignment','bottom');
                    end
                end
                
                %Create random event ID
                new_event.event_ID = randi(intmax);
                
                %Add the new line to the obj
                if isempty(obj.event_list)
                    obj.event_list = new_event;
                else
                    obj.event_list(old_list_size + ii)= new_event;
                end
            end
        end
        
        
        %-----------------------------------------------------------
        %             DELETE SELECTED EVENT
        %-----------------------------------------------------------
        function delete_selected(obj)
            if ~isempty(obj.current_object)
                selected_obj=obj.event_list(obj.current_object_ind);
                
                %Get the text label info from the main object
                label_handle=selected_obj.label_handle;
                graphics_obj_handle=selected_obj.obj_handle;
                
                %Delete the selected object
                delete(obj.current_object);
                %Delete the underlying non-selected object
                delete(graphics_obj_handle);
                %Delete the text
                delete(label_handle);
                
                %Fix the object list
                if length(obj.event_list)>1
                    obj.event_list=obj.event_list(setdiff(1:length(obj.event_list),obj.current_object_ind));
                else
                    obj.event_list=[];
                end
                
                %Revert to no selected object
                obj.current_object=[];
                obj.current_object_ind=[];
            end
        end
        
        %-----------------------------------------------------------
        %                     SAVE DATA
        %-----------------------------------------------------------
        function save(obj, fname)
            
            %Saving the event positional data
            event_data=cell(1,length(obj.event_types));
            
            %See if there are any events
            if isempty(obj.event_list)
                warning('Nothing to save');
                return;
            end
            
            %Extract the positional information from each object
            for type = 1:length(obj.event_types)
                %Find the indices of the events with the given type
                type_inds = find(([obj.event_list.type_ID] == obj.event_types(type).type_ID));
                
                %Loop through the events of the given type
                for eventnum = 1:length(type_inds)
                    event_obj = obj.event_list(type_inds(eventnum));
                    
                    %If region, add bounds
                    if obj.event_types(type).region
                        pos=get(event_obj.obj_handle,'position');
                        event_x = [pos(1) pos(1)+pos(3)];
                        event_y = [pos(2) pos(2)+pos(4)];
                        
                        %Just have the x bounds for the constrained region
                        if obj.event_types(type).constrain
                            event_data{type}(eventnum,:) = event_x;
                        else %Have both x and y bounds for the unconstrained event
                            event_data{type}(eventnum,:) = [event_x event_y];
                        end
                    else
                        %Get the xdata for the single event
                        times = get(event_obj.obj_handle,'xdata');
                        xpos = times(1);
                        
                        %Save the event time
                        event_data{type}(eventnum,:)=xpos;
                    end
                end
            end
            
            event_types = obj.event_types;
            
            %Save position and event type data
            if nargin == 1 || isempty(fname)
                [filename, pathname] = uiputfile('saved_events.mat','Save Event Data');
                save(fullfile(pathname,filename),'event_types','event_data');
            else
                save(fname,'event_types','event_data');
            end
        end
        %-----------------------------------------------------------
        %                     LOAD DATA
        %-----------------------------------------------------------
        function load(obj, fname)
            
            if nargin<2 || isempty(fname)
                [filename, pathname] = uigetfile('*.mat','Select Event File');
                load(fullfile(pathname,filename));
            else
                if exist(fname,'file')
                    load(fname);
                else
                    error('EventMarker: bad file name');
                end
            end
            
            if exist('event_types','var') && exist('event_data','var')
                
                for ii=1:length(obj.event_types)
                    if obj.event_types(ii).region
                        position = zeros(size(event_data{ii},1),4);
                    else
                        position = zeros(size(event_data{ii},1),1);
                    end
                    
                    for j=1:size(event_data{ii},1)
                        %Get the position
                        position(ii,:)=event_data{ii}(j,:);
                        if obj.event_types(ii).region
                            if obj.event_types(ii).constrain
                                %Reconstruct for constrained region
                                newpos(1)=min(position(1:2));
                                newpos(2)=min(obj.ybounds);
                                newpos(3)=abs(diff(position(1:2)));
                                newpos(4)=max(obj.ybounds);
                            else
                                %Reconstruct from unconstrained region
                                newpos(1)=min(position(1:2));
                                newpos(2)=min(position(3:4));
                                newpos(3)=abs(diff(position(1:2)));
                                newpos(4)=abs(diff(position(3:4)));
                            end
                            
                            %Use as the new position
                            position(ii,:)=newpos;
                        end
                    end
                end
                mark_event(obj, obj.event_types(ii).type_ID, position);
            else
                error('Invalid File');
            end
        end
    end
    methods (Access = private)
        %-----------------------------------------------------------
        %              HANDLE MOUSE EVENTS
        %-----------------------------------------------------------
        function clickcallback(obj, varargin)
            if isempty(obj.check_double_click)
                obj.check_double_click = 1;
                get(gcbo,'CurrentPoint');
                
                %Add a delay to distinguish single click from a double click
                pause(0.5);
                if obj.check_double_click == 1
                    %disp('I am doing a single-click');
                    obj.check_double_click = [];
                end
            else
                obj.check_double_click = [];
                %disp('I am doing a double-click');
                if ~obj.use_imline
                    %                     disp('Using drawrectangle');
                    edit_event(obj);
                else
                    %                     warning('Older version detected: Using imline');
                    edit_event_imline(obj);
                end
            end
        end
        
        %-----------------------------------------------------------
        %                EDIT USER EVENT
        %-----------------------------------------------------------
        function edit_event(obj, varargin)
            
            %Check if there are any events to edit
            if isempty(obj.event_list)
                set(gcf,'Pointer','arrow');
                return;
            else
                %Handle a double click by a region
                if isempty(obj.current_object)
                    %Get the last point clicked
                    click_pos=get(gca,'CurrentPoint');
                    click_x=click_pos(1,1);
                    
                    %Find the closest region
                    c=1;%Counter
                    
                    %Grab object bounds
                    for i=1:length(obj.event_list)
                        %Check event object
                        check_obj=obj.event_list(i);
                        
                        %Handle region and line separately
                        if check_obj.region
                            %Get the xpositions
                            event_pos=get(check_obj.obj_handle,'position');
                            
                            %Get the region left bound
                            object_bounds(c)=event_pos(1);
                            %Save index into event_list
                            object_ind(c)=i;
                            
                            %Get the region right bound
                            object_bounds(c+1)=event_pos(1)+event_pos(3);
                            %Save index into event_list
                            object_ind(c+1)=i;
                            c=c+2;
                        else
                            %Get the xpositions
                            event_pos=get(check_obj.obj_handle,'xdata');
                            %Get the x-value of the vertical line
                            object_bounds(c)=event_pos(1);
                            object_ind(c)=i;
                            c=c+1;
                        end
                    end
                    
                    %Get closest regional bounds to click
                    [~, ind]=min(abs(click_x(1)-object_bounds));
                    closest_ind=object_ind(ind);
                    closest_obj=obj.event_list(closest_ind);
                    
                    obj.selected_ind = closest_ind;
                    
                    %Get the object handle
                    obj_handle=closest_obj.obj_handle;
                    %Get the text label info from the main object
                    label_handle=closest_obj.label_handle;
                    obj_id = closest_obj.event_ID;
                    
                    %Hide the region just selected
                    set(obj_handle,'visible','off');
                    
                    if closest_obj.region
                        %Create a selectable imrect in its exact position
                        if closest_obj.constrain
                            pos=get(obj_handle,'position');
                            pos(2)=obj.ybounds(1);
                            pos(4)=abs(diff(obj.ybounds));
                            
                            %Constrain if necessary
                            selected_obj=drawrectangle(obj.main_ax, 'position', pos, 'rotatable', false, 'color','k', 'linewidth', 5);
                        else
                            selected_obj=drawrectangle(obj.main_ax, 'position',get(obj_handle,'position'), 'rotatable', false, 'color','k', 'linewidth', 5);
                        end
                        
                        set(selected_obj,'UserData', obj_id);
                        
                        addlistener(selected_obj,'MovingROI', @(src,event)obj.update_event_text(selected_obj, label_handle, true));
                        addlistener(selected_obj,'MovingROI', @(src,event)obj.constrain_rect(selected_obj,obj.xbounds,obj.ybounds, closest_obj.constrain));
                        
                        if ~isempty(obj.eventMotionCallback)
                            addlistener(selected_obj,'MovingROI', @(src,event)obj.eventMotionCallback(selected_obj, label_handle, true));
                        end
                        
                        %Change the font of the label to show selected
                        set(label_handle,'color',[0 0 0],'fontweight','bold','fontsize',obj.label_fontsize+3);
                    else
                        xpos=get(obj_handle,'xdata');
                        xpos=xpos(1);
                        
                        %Create a selectable imline in the exact position
                        selected_obj = drawline(obj.main_ax, 'position', [xpos obj.ybounds(1); xpos obj.ybounds(2)],'interactionsallowed', 'translate', 'color','k', 'linewidth', 5);
                        set(selected_obj,'UserData', obj_id);
                        
                        addlistener(selected_obj,'MovingROI', @(src,event)obj.update_event_text(selected_obj, label_handle, true));
                        
                        if ~isempty(obj.eventMotionCallback)
                            addlistener(selected_obj,'MovingROI', @(src,event)obj.eventMotionCallback(selected_obj, label_handle, true));
                        end
                        
                        %Change the font of the label to show selected
                        set(label_handle,'color',[0 0 0],'fontweight','bold','fontsize',obj.label_fontsize+3);
                    end
                    obj.current_object=selected_obj;
                    obj.current_object_ind=closest_ind;
                else
                    %Revert to the original view after double clicking off
                    %the selection
                    selected_object=obj.event_list(obj.current_object_ind);
                    label_handle=selected_object.label_handle;
                    obj_handle=selected_object.obj_handle;
                    
                    set(label_handle,'color',[0 0 0],'fontweight','normal','fontsize',obj.label_fontsize);
                    
                    if  selected_object.region
                        %Update the region to the updated position
                        set(obj_handle,'position',obj.current_object.Position);
                    else
                        newx=obj.current_object.Position;
                        %Update the line to the updated position
                        set(obj_handle,'xdata',[newx(1) newx(1)]);
                    end
                    
                    %Delete the imrect
                    delete(obj.current_object);
                    obj.current_object=[];
                    obj.current_object_ind=[];
                    obj.selected_ind = [];
                    
                    %Turn on the new position
                    set(obj_handle,'visible','on');
                end
            end
            
            %Fix the pointer
            set(gcf,'Pointer','arrow');
        end
        
        %-----------------------------------------------------------
        %                EDIT USER EVENT
        %-----------------------------------------------------------
        function edit_event_imline(obj, varargin)
            
            %Check if there are any events to edit
            if isempty(obj.event_list)
                set(gcf,'Pointer','arrow');
                return;
            else
                %Handle a double click by a region
                if isempty(obj.current_object)
                    %Get the last point clicked
                    click_pos=get(gca,'CurrentPoint');
                    click_x=click_pos(1,1);
                    
                    %Find the closest region
                    c=1;%Counter
                    
                    %Grab object bounds
                    for i=1:length(obj.event_list)
                        %Check event object
                        check_obj=obj.event_list(i);
                        
                        %Handle region and line separately
                        if check_obj.region
                            %Get the xpositions
                            event_pos=get(check_obj.obj_handle,'position');
                            
                            %Get the region left bound
                            object_bounds(c)=event_pos(1);
                            %Save index into event_list
                            object_ind(c)=i;
                            
                            %Get the region right bound
                            object_bounds(c+1)=event_pos(1)+event_pos(3);
                            %Save indext into event_list
                            object_ind(c+1)=i;
                            c=c+2;
                        else
                            %Get the xpositions
                            event_pos=get(check_obj.obj_handle,'xdata');
                            %Get the x-value of the vertical line
                            object_bounds(c)=event_pos(1);
                            object_ind(c)=i;
                            c=c+1;
                        end
                    end
                    
                    %Get closest regional bounds to click
                    [~, ind]=min(abs(click_x(1)-object_bounds));
                    closest_ind=object_ind(ind);
                    closest_obj=obj.event_list(closest_ind);
                    
                    obj.selected_ind = closest_ind;
                    
                    %Get the object handle
                    obj_handle=closest_obj.obj_handle;
                    %Get the text label info from the main object
                    label_handle=closest_obj.label_handle;
                    obj_id = closest_obj.event_ID;
                    
                    %Hide the region just selected
                    set(obj_handle,'visible','off');
                    
                    if closest_obj.region
                        %Create a selectable imrect in its exact position
                        if closest_obj.constrain
                            pos=get(obj_handle,'position');
                            pos(2)=obj.ybounds(1);
                            pos(4)=abs(diff(obj.ybounds));
                            %Constrain if necessary
                            selected_obj=imrect(obj.main_ax, pos);
                        else
                            selected_obj=imrect(obj.main_ax, get(obj_handle,'position'));
                        end
                        
                        set(selected_obj,'UserData', obj_id);
                        
                        %Set the color
                        setColor(selected_obj,[0 0 0]);
                        rectangle_parts=get(selected_obj,'children');
                        %Get rid of unnecessary control squares
                        set(rectangle_parts([1:5 7:11]),'marker','none');
                        %Make the side control squares big
                        set(rectangle_parts(1:12),'markersize',15,'linewidth',2,'color','k')
                        %Make the lines thicker
                        set(rectangle_parts(14:end),'linewidth',5)
                        
                        
                        %Constrain make region to full height
                        if ~closest_obj.constrain
                            %Make the side control squares big
                            set(rectangle_parts(1:12),'marker','s')
                        end
                        
                        %Constrain to within bounds and force constrained regions span the entire y-axis
                        setPositionConstraintFcn(selected_obj,@(pos)obj.constrain_rect_imline(pos,obj.xbounds,obj.ybounds, closest_obj.constrain));
                        %Update the event text when region is moved
                        addNewPositionCallback(selected_obj,@(src,event)obj.update_event_text_imline(selected_obj, label_handle, true));
                        
                        if ~isempty(obj.eventMotionCallback)
                            addNewPositionCallback(selected_obj,@(src,event)obj.eventMotionCallback(selected_obj, label_handle, true));
                        end
                        
                        %Change the font of the label to show selected
                        set(label_handle,'color',[0 0 0],'fontweight','bold','fontsize',obj.label_fontsize+3);
                    else
                        xpos=get(obj_handle,'xdata');
                        xpos=xpos(1);
                        
                        %Create a selectable imline in the exact position
                        selected_obj=imline(obj.main_ax,  [xpos obj.ybounds(1); xpos obj.ybounds(2)]);
                        set(selected_obj,'UserData', obj_id);
                        
                        %Constrain line to stay in bounds and span y-axis
                        setPositionConstraintFcn(selected_obj,@(pos)obj.constrain_line_imline(pos,obj.xbounds,obj.ybounds));
                        %Update the text label
                        addNewPositionCallback(selected_obj,@(src,event)obj.update_event_text_imline(selected_obj, label_handle, false));
                        
                        if ~isempty(obj.eventMotionCallback)
                            addNewPositionCallback(selected_obj,@(src,event)obj.eventMotionCallback(selected_obj, label_handle, false));
                        end
                        
                        %Set line width
                        lineparts=get(selected_obj,'children');
                        set(lineparts(4),'linewidth',1); %Set the mask width
                        set(lineparts(3),'linewidth',5); %The main line width
                        set(lineparts(1:2),'linewidth',2,'visible','off'); %The control point width
                        set(lineparts,'color','k');
                        
                        %Change the font of the label to show selected
                        set(label_handle,'color',[0 0 0],'fontweight','bold','fontsize',obj.label_fontsize+3);
                    end
                    obj.current_object=selected_obj;
                    obj.current_object_ind=closest_ind;
                else
                    %Revert to the original view after double clicking off
                    %the selection
                    selected_object=obj.event_list(obj.current_object_ind);
                    label_handle=selected_object.label_handle;
                    obj_handle=selected_object.obj_handle;
                    
                    set(label_handle,'color',[0 0 0],'fontweight','normal','fontsize',obj.label_fontsize);
                    
                    if  selected_object.region
                        %Update the region to the updated position
                        set(obj_handle,'position',getPosition(obj.current_object));
                    else
                        newx=getPosition(obj.current_object);
                        %Update the line to the updated position
                        set(obj_handle,'xdata',[newx(1) newx(1)]);
                    end
                    
                    %Delete the imrect
                    delete(obj.current_object);
                    obj.current_object=[];
                    obj.current_object_ind=[];
                    obj.selected_ind=[];
                    
                    %Turn on the new position
                    set(obj_handle,'visible','on');
                end
            end
            
            
            %Fix the pointer
            set(gcf,'Pointer','arrow');
        end
        
        %-----------------------------------------------------------
        %     UPDATE THE EVENT TEXT WHEN THE LINES ARE MOVED
        %-----------------------------------------------------------
        function update_event_text(obj, imobject, label_handle, region)
            %Get current labelposition
            label_pos=get(label_handle,'position');
            
            %Get the text related to the line obj and move it
            if obj.use_imline
                obj_pos=getPosition(imobject);
            else
                obj_pos = imobject.Position;
            end
            
            if region
                obj_middle=mean([obj_pos(1) (obj_pos(1)+obj_pos(3))]);
            else
                obj_middle=obj_pos(1,1);
            end
            
            label_pos(1)=obj_middle;
            set(label_handle,'position',label_pos);
        end
        
        %-----------------------------------------------------------
        %     UPDATE THE EVENT TEXT WHEN THE LINES ARE MOVED
        %-----------------------------------------------------------
        function update_event_text_imline(~, imobject, label_handle, region)
            %Get current labelposition
            label_pos=get(label_handle,'position');
            
            %Get the text related to the line obj and move it
            obj_pos=getPosition(imobject);
            
            if region
                obj_middle=mean([obj_pos(1) (obj_pos(1)+obj_pos(3))]);
            else
                obj_middle=obj_pos(1,1);
            end
            
            label_pos(1)=obj_middle;
            set(label_handle,'position',label_pos);
        end
        
        %-----------------------------------------------------------
        %     CONSTRAIN THE REGIONS TO FIT THE WHOLE AXIS
        %-----------------------------------------------------------
        function new_pos=constrain_rect(~, obj_handle, xbounds, ybounds, constrain)
            %New position
            pos=obj_handle.Position;
            new_pos = pos;
            
            %Make sure object stays in bounds
            new_pos(1)=min(max(pos(1),xbounds(1)), xbounds(2)-pos(3));
            new_pos(2)=min(max(pos(2),ybounds(1)), ybounds(2)-pos(4));
            
            %Constrain to fill y axis for constrained regions
            if constrain
                new_pos(4)=diff(ybounds);
                new_pos(2)=ybounds(1);
            end
            obj_handle.Position = new_pos;
        end
        
        
        %-----------------------------------------------------------
        %     CONSTRAIN THE REGIONS TO FIT THE WHOLE AXIS
        %-----------------------------------------------------------
        function new_pos=constrain_rect_imline(~, pos, xbounds, ybounds, constrain)
            %New position
            new_pos = pos;
            
            %Make sure object stays in bounds
            new_pos(1)=min(max(pos(1),xbounds(1)), xbounds(2)-pos(3));
            new_pos(2)=min(max(pos(2),ybounds(1)), ybounds(2)-pos(4));
            
            %Constrain to fill y axis for constrained regions
            if constrain
                new_pos(4)=diff(ybounds);
                new_pos(2)=ybounds(1);
            end
        end
        
        
        %-----------------------------------------------------------
        %                 CONSTRAIN EVENT LINES
        %-----------------------------------------------------------
        function new_pos=constrain_line(~,pos, xbounds, ybounds)
            %New position
            new_pos=pos;
            
            %Make sure object stays in bounds
            new_pos(1,:)=min(max(pos(1,1),xbounds(1)), xbounds(2));
            %Set the height of the line to the y limits
            new_pos(:,2)=ybounds';
        end
        
        
        
        %-----------------------------------------------------------
        %                 CONSTRAIN EVENT LINES
        %-----------------------------------------------------------
        function new_pos=constrain_line_imline(~,pos, xbounds, ybounds)
            %New position
            new_pos=pos;
            
            %Make sure object stays in bounds
            new_pos(:,1) = min(max(pos(1,1),xbounds(1)), xbounds(2));
            %Set the height of the line to the y limits
            new_pos(:,2) = ybounds';
        end
        
        %-----------------------------------------------------------
        %                NICER CLICK ROUTINE
        %-----------------------------------------------------------
        function pos = get_clicks(obj, num_clicks)
            h_fig = obj.main_fig;
            h_ax = obj.main_ax;
            
            pos = zeros(num_clicks, 2);
            
            %             iptPointerManager(h_fig);
            %             iptSetPointerBehavior(h_ax, @(h_fig, currentPoint)set(h_fig, 'Pointer', 'cross'));
            
            clicks = 0;
            pos = zeros(num_clicks,2);
            while clicks<num_clicks
                
                [pos(clicks+1,1), pos(clicks+1,2)] = ginput(1);
                clicks=clicks+1;
                %                 w = waitforbuttonpress;
                %
                %                 if ~w
                %                     clicks = clicks + 1;
                %
                %                     pos(clicks,:) = p(1,1:2);
                %                 end
            end
            
            %             iptSetPointerBehavior(h_ax, @(h_fig, currentPoint)set(h_fig, 'Pointer', 'arrow'));
        end
        
    end
end


