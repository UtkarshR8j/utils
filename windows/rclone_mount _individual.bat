@echo off
setlocal

rem List all remote names using rclone
echo Available remotes:
rclone listremotes

rem Prompt the user to select a remote
set /p selected_remote="Enter the name of the remote to mount: "

rem Mount the selected remote to a unique directory on the Desktop with full permissions
rclone mount "%selected_remote%:" "%USERPROFILE%\OneDrive\Desktop\%selected_remote%" --vfs-cache-mode full --dir-cache-time=10s

endlocal
