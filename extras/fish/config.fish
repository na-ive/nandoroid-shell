# ─────────────────────────────────────────────────────────────────────────────
#  Nandoroid Shell: Fish Configuration
#  A clean, themed terminal experience.
# ─────────────────────────────────────────────────────────────────────────────

# --- Greeting ---
set fish_greeting

# --- Theming (Matugen) ---
# Apply dynamic terminal colors if generated
if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
end

# --- Prompt ---
if status is-interactive
    # Use starship prompt
    starship init fish | source
end

# --- General Aliases ---
alias clear "printf '\033[2J\033[3J\033[1;1H'"
alias neofetch 'fastfetch'

# --- Environment ---
# Ensure local bin is in PATH
fish_add_path "$HOME/.local/bin"
