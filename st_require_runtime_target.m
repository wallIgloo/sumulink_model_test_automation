function cfg = st_require_runtime_target()
%ST_REQUIRE_RUNTIME_TARGET Validate and load the selected runtime model.
%
% The target model is selected by st_find_target_paths and stored in
% runtime_target.mat.

cfg = st_config();

if ~cfg.HasRuntimeTarget

    error( ...
        ['Target model is not selected. ' ...
         'Run st_find_target_paths first.']);
end

if ~isfile(cfg.ModelFile)

    error( ...
        'Selected model file does not exist: %s', ...
        cfg.ModelFile);
end

if ~bdIsLoaded(cfg.TopModel)

    load_system(cfg.ModelFile);
end

end
