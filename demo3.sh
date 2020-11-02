#!/bin/sh

source helper_script4.sh

    SECONDS=0
    log_info "Program started"

    # the default log level is INFO; override it to DEBUG
    set_log_level DEBUG

    log_debug "Running step 1"
    # code for step 1

    log_warn "This is a warning"

    required_file=/path/to/required/file
    if [[ ! -f $required_file ]]; then
        log_error "File '$required_file' does not exist, skipping this step"
    else
        # log the contents of this file in DEBUG mode
        log_debug_file "$required_file"

        log_verbose "Calling process_file"
        process_file "$required_file"
        log_verbose "Call to process_file finished"
    fi

    log_info  "Program finished, elapsed time = $SECONDS seconds"
