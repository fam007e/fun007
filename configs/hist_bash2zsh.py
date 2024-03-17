bash_history_path = '/data/data/com.termux/files/home/.bash_history'
zsh_history_path = '/data/data/com.termux/files/home/.zsh_history'

# Read bash history file
with open(bash_history_path, 'r') as bash_history_file:
    bash_history_content = bash_history_file.readlines()

# Append bash history content to zsh history file
with open(zsh_history_path, 'a') as zsh_history_file:
    # Check if the zsh history file already has content
    zsh_history_file.seek(0, 2)  # Move cursor to the end of the file
    if zsh_history_file.tell() > 0:
        zsh_history_file.write('\n# Appended from bash history\n')
    zsh_history_file.writelines(bash_history_content)
