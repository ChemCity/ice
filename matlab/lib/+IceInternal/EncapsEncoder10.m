%{
**********************************************************************

Copyright (c) 2003-2017 ZeroC, Inc. All rights reserved.

This copy of Ice is licensed to you under the terms described in the
ICE_LICENSE file included in this distribution.

**********************************************************************
%}

classdef EncapsEncoder10 < IceInternal.EncapsEncoder
    methods
        function obj = EncapsEncoder10(os, encaps)
            obj = obj@IceInternal.EncapsEncoder(os, encaps);
            obj.sliceType = IceInternal.SliceType.NoSlice;
            obj.valueIdIndex = 0;
            obj.toBeMarshaledMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            obj.marshaledMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        end

        function writeValue(obj, v)
            %
            % Object references are encoded as a negative integer in 1.0.
            %
            if ~isempty(v)
                obj.os.writeInt(-obj.registerValue(v));
            else
                obj.os.writeInt(0);
            end
        end

        function startInstance(obj, sliceType, slicedData)
            obj.sliceType = sliceType;
        end

        function endInstance(obj)
            if obj.sliceType == IceInternal.SliceType.ValueSlice
                %
                % Write the Object slice.
                %
                obj.startSlice(Ice.Value.ice_staticId(), -1, true);
                obj.os.writeSize(0); % For compatibility with the old AFM.
                obj.endSlice();
            end
            obj.sliceType = IceInternal.SliceType.NoSlice;
        end

        function startSlice(obj, typeId, compactId, last)
            %
            % For instance slices, encode a boolean to indicate how the type ID
            % is encoded and the type ID either as a string or index. For
            % exception slices, always encode the type ID as a string.
            %
            if obj.sliceType == IceInternal.SliceType.ValueSlice
                index = obj.registerTypeId(typeId);
                if index < 0
                    obj.os.writeBool(false);
                    obj.os.writeString(typeId);
                else
                    obj.os.writeBool(true);
                    obj.os.writeSize(index);
                end
            else
                obj.os.writeString(typeId);
            end

            obj.os.writeInt(0); % Placeholder for the slice length.

            obj.writeSlice = obj.os.pos();
        end

        function endSlice(obj)
            %
            % Write the slice length.
            %
            sz = obj.os.pos() - obj.writeSlice + 4;
            obj.os.rewriteInt(sz, obj.writeSlice - 4);
        end

        function writePendingValues(obj)
            while obj.toBeMarshaledMap.Count > 0
                %
                % Consider the to be marshalled instances as marshaled now,
                % this is necessary to avoid adding again the "to be
                % marshaled instances" into toBeMarshaledMap while writing
                % instances.
                %
                obj.marshaledMap = [obj.marshaledMap; obj.toBeMarshaledMap];

                savedMap = obj.toBeMarshaledMap;
                obj.toBeMarshaledMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
                obj.os.writeSize(savedMap.Count);
                keys = savedMap.keys();
                for i = 1:length(keys)
                    %
                    % Ask the instance to marshal itself. Any new class
                    % instances that are triggered by the classes marshaled
                    % are added to toBeMarshaledMap.
                    %
                    obj.os.writeInt(keys{i});

                    v = savedMap(keys{i});
                    try
                        v.ice_preMarshal();
                    catch ex
                        % TODO: logger
                        %String s = "exception raised by ice_preMarshal:\n" + com.zeroc.IceInternal.Ex.toString(ex);
                        %obj.os.instance().initializationData().logger.warning(s);
                    end

                    v.iceWrite_(obj.os);
                end
            end
            obj.os.writeSize(0); % Zero marker indicates end of sequence of sequences of instances.

            %
            % Clear the identifier from all instances.
            %
            values = obj.marshaledMap.values();
            for i = 1:length(values)
                values{i}.internal_ = -1;
            end
        end
    end
    methods(Access=protected)
        function r = registerValue(obj, v)
            assert(~isempty(v));

            %
            % We can't use object identity in MATLAB so we assign each value a unique identifier.
            %
            if v.internal_ == -1
                %
                % We haven't seen this value yet.
                %
                obj.valueIdIndex = obj.valueIdIndex + 1;
                v.internal_ = obj.valueIdIndex;
            end

            r = v.internal_;

            %
            % Look for this instance in the to-be-marshaled map.
            %
            if obj.toBeMarshaledMap.isKey(v.internal_)
                return;
            end

            %
            % Didn't find it, try the marshaled map next.
            %
            if obj.marshaledMap.isKey(v.internal_)
                return;
            end

            %
            % We haven't seen this instance previously, create a new
            % index, and insert it into the to-be-marshaled map.
            %
            obj.toBeMarshaledMap(v.internal_) = v;
        end
    end
    properties(Access=private)
        sliceType
        writeSlice
        valueIdIndex
        toBeMarshaledMap
        marshaledMap
    end
end
