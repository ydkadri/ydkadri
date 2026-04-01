
# General functions for BAU
field() {
    # Extract a field from a whitespace delimited string
    awk -F "${2:- }" "{print \$${1:-1} }"
}

# tmux functions
tn() {
    # Create a new tmux session
    if [[ -z $1 ]]; then
        echo "Usage: tn <session_name>"
        return 1
    fi

    tmux new-session -s $1
}

tl() {
    # List all tmux sessions
    tmux list-sessions
}

ta() {
    # Attach to a tmux session
    if [[ -z $1 ]]; then
        echo "Usage: ta <session_name>"
        return 1
    fi

    tmux attach-session -t $1
}
