
file_list_all = dir(fullfile('replicates', '*.csv'));

file_list_all = {file_list_all.name};

prefixes = cellfun(@(x) strsplit(x, '-'), file_list_all, 'UniformOutput', false);
prefixes = cellfun(@(x) x{1}, prefixes, 'UniformOutput', false);

% Create groups based on the sample names 
uniquePrefixes = unique(prefixes);
groups = cell(1, numel(uniquePrefixes));

for i = 1:numel(uniquePrefixes)
    groups{i} = file_list_all(ismember(prefixes, uniquePrefixes{i}));
end
%%


icotopselection = readtable('Isotopes.csv', 'VariableNamingRule', 'preserve', 'FileType', 'spreadsheet');
selected = icotopselection{:, 2};

data_ = readtable(append('replicates\', file_list_all{1}), 'VariableNamingRule', 'preserve');
selected = [data_.Properties.VariableNames{1:2} , selected'];

columnsToSelect = ismember(selected, data_.Properties.VariableNames);
multi_icotops = [false; false; ismissing(icotopselection{:, 3})==0];
multi_icotops_in_selected = multi_icotops(columnsToSelect);
lod_filter = icotopselection{:, 4};
%%
%looping through each sample and merging all replicates for that sample
for g = 1:length(groups)
    data = [];
    file_list = groups{g};
    for i = 1: length(file_list)
        filepath = append('replicates\', file_list{i});
        tables = readtable(filepath, 'VariableNamingRule','preserve');
        %removing values less than lod_filter for each column
        replicate_data = tables{:, 3:end};
        mask = replicate_data < lod_filter';
        replicate_data(mask) = NaN;
        tables{:, 3:end} = replicate_data;
        %extracting the selected columns
        tables = tables(:, columnsToSelect);
        data = [data; tables{:, :}];
    
    end
    
    %extracting element names within the brackets 
    column_names = cellfun(@(x) regexprep(x, '.*\[([\dA-Za-z]+)\].*', '$1'), tables.Properties.VariableNames, 'UniformOutput', false);
    %remvoing numbers from the element names 
    column_names = cellfun(@(x) regexprep(x, '\d', ''), column_names, 'UniformOutput', false);
    %replacing multi isotops elements with their full name
    column_names(multi_icotops_in_selected) =  icotopselection{multi_icotops(3:end), 3};

    data(:,1) = [1:size(data,1)]';
    outputtable = array2table(data, 'VariableNames',column_names');
    tic
    tmp = table2cell(outputtable);             %Converting the table to a cell array
    
    tmp(isnan(outputtable.Variables)) = {[]};  %Replacing the NaN entries with []
    
    T = array2table(tmp,'VariableNames',outputtable.Properties.VariableNames); %Converting back to table
    
    % filename = append('combined\', extractBefore(file_list{1}, min(length(file_list{1}), 30)), '.csv');
    filename = append('combined\', extractBefore(file_list{1}, '-'), '.csv');
    
    writetable(T, filename);
    toc
end