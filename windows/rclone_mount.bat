@echo off
setlocal

rem Define your remote names here
set remotes=utkarshraj19052000 utkarsh.sendmail utkarsh_longstraw

rem Mount each remote to a unique directory on the Desktop with full permissions
for %%a in (%remotes%) do (
    start "" rclone mount "%%a:" "%USERPROFILE%\OneDrive\Desktop\%%a" --vfs-cache-mode full --dir-cache-time=10s -vv
)

endlocal
