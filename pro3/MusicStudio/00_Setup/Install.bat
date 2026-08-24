@echo off
chcp 65001 >nul
title 音乐制作系统 - 安装程序
color 0A

echo ========================================
echo   音乐制作系统 v2.0 - 轻量级版
echo ========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 需要管理员权限以安装必要的组件
    echo 请以管理员身份运行此脚本
    pause
    exit /b 1
)

:: 设置路径
set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

:: 检查Python
echo [1/6] 检查Python环境...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo 未检测到Python，正在安装Python 3.9...
    powershell -Command "Start-Process -Wait -FilePath '.\00_Setup\OfflinePackages\python-3.9.7-amd64.exe' -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1'"
    echo Python安装完成
) else (
    echo Python已安装
)

:: 检查FFmpeg
echo [2/6] 检查FFmpeg...
where ffmpeg >nul 2>&1
if %errorLevel% neq 0 (
    echo 正在安装FFmpeg...
    powershell -Command "Expand-Archive -Path '.\00_Setup\OfflinePackages\ffmpeg.zip' -DestinationPath 'C:\ffmpeg' -Force"
    setx PATH "%PATH%;C:\ffmpeg\bin" /M
    echo FFmpeg安装完成
) else (
    echo FFmpeg已安装
)

:: 检查MIDI驱动程序
echo [3/6] 检查MIDI支持...
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MCI" /v "Sequencer" >nul 2>&1
if %errorLevel% neq 0 (
    echo 配置MIDI支持...
    powershell -Command "Start-Process -Wait -FilePath '.\00_Setup\OfflinePackages\VirtualMIDISynthSetup.exe' -ArgumentList '/S'"
    echo MIDI驱动程序安装完成
) else (
    echo MIDI支持已就绪
)

:: 安装Python依赖
echo [4/6] 安装Python依赖库...
if exist "requirements.txt" (
    echo 正在安装依赖包（这可能需要几分钟）...
    python -m pip install --upgrade pip
    pip install -r requirements.txt --no-index --find-links=".\00_Setup\OfflinePackages\pip"
    echo 依赖安装完成
) else (
    echo 正在安装核心依赖...
    for %%p in (numpy,pygame,pretty_midi,soundfile) do (
        echo 安装 %%p...
        pip install ".\00_Setup\OfflinePackages\pip\%%p*.whl"
    )
)

:: 下载音色库
echo [5/6] 设置音色库...
if not exist "Libs\SoundFonts" mkdir "Libs\SoundFonts"
if not exist "Libs\SoundFonts\default.sf2" (
    echo 正在下载免费音色库...
    powershell -Command "Invoke-WebRequest -Uri 'https://downloads.sourceforge.net/project/fluid-soundfonts/FluidR3_GM/FluidR3_GM.sf2' -OutFile 'Libs\SoundFonts\default.sf2'"
    echo 音色库下载完成
)

:: 创建示例项目
echo [6/6] 创建示例文件...
if not exist "Data\Instruments" mkdir "Data\Instruments"
if not exist "Data\MIDI" mkdir "Data\MIDI"
if not exist "Data\Audio" mkdir "Data\Audio"
if not exist "Output\Projects" mkdir "Output\Projects"
if not exist "Output\Renders" mkdir "Output\Renders"

:: 创建示例配置
if not exist "Config\Defaults.ini" (
    echo [System] > "Config\Defaults.ini"
    echo SampleRate=44100 >> "Config\Defaults.ini"
    echo Channels=2 >> "Config\Defaults.ini"
    echo BufferSize=2048 >> "Config\Defaults.ini"
    echo. >> "Config\Defaults.ini"
    echo [Audio] >> "Config\Defaults.ini"
    echo SoundFont=default.sf2 >> "Config\Defaults.ini"
    echo NormalizeOutput=true >> "Config\Defaults.ini"
)

echo.
echo ========================================
echo   安装完成！
echo ========================================
echo.
echo 已安装的组件：
echo   - Python 3.9+
echo   - FFmpeg
echo   - MIDI驱动程序
echo   - 音色库
echo   - Python音频库
echo.
echo 使用方法：
echo   1. 运行 MusicStudio.bat 启动主界面
echo   2. 或运行子模块的 .bat 文件
echo.
pause