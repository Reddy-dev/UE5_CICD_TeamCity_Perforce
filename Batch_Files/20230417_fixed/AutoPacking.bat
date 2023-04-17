@REM @title p4 sync ......
@REM p4 sync //UE5/Dev/...#head
@REM @if %errorlevel%==0 (
@REM   echo p4 sync ok
@REM ) else (
@REM   echo p4 sync error
@REM   call .\SendDingMsg.bat
@REM   color 4
@REM   pause
@REM   exit /b 1
@REM )

@REM -----------------------------------Mk Pack Dir----------------------------------------------
@REM unzip teamcity build config file and make new version package dir
@REM @echo off

@if "%teamcity_data_dir%"=="" (
  @set teamcity_data_dir=C:\ProgramData\JetBrains\TeamCity
)

@if "%teamcity_project_id%"=="" (
  @set teamcity_project_id=Ue5t6
)

@if "%build_conf_name%"=="" (
  @REM set build_conf_name=SecondBuildTest
  @set build_conf_name=firstbuild
)

@REM build info dir contains all build info dirs, which are named of internal_build_id
@if "%build_info_dir%"=="" (
  @set build_info_dir=%teamcity_data_dir%\system\artifacts\%teamcity_project_id%\%build_conf_name%\
)

@REM TODO: 这里可能有问题
@REM get the latest dir
@for /f %%i in ('dir /o-d /tc /b "%build_info_dir%"') do (
  @set "Files=%%i"
  @call :unzip
  @goto :eof
)

:unzip
@REM build_prop_path          build property's file path
@if "%build_prop_path%"=="" (
  @set build_prop_path=%build_info_dir%%Files%\.teamcity\properties\build.start.properties.gz
)
@REM a temp dir to store the build properties file
@if "%tempdir%"=="" (
  @set tempdir=%~dp0Projects\t6\ArchivedBuilds\temp\
)
@rmdir /s /q %tempdir% >nul 2>&1
@mkdir %tempdir%
@REM TODO: 经常找不到解压后的路径，这个问题好好解决一下
@winrar x -y %build_prop_path% %tempdir%
@REM find the certain row of revision number 
@REM /b start find from begin
@REM get the vcs num str
@setlocal enabledelayedexpansion
@for /f %%x in ('findstr /b "build.vcs.number=" "%tempdir%build.start.properties"') do (set vcs_num_str=%%x)&goto endSch
:endSch
@REM handle the vcs num str
@if "%revision_num%"=="" (
  @REM TODO: 这里可能会变成 4 位，需要注意
  @set /a revision_num = %vcs_num_str:~-4,4%
)

@if %errorlevel%==0 (
  echo get revision num ok
) else (
  echo get revision num error
  color 4
  pause
  exit /b 1
)

set mainvernum=0
set subvernum=0
@REM ------------------- Set Previous Version Num as Base Ver Everytime------------------------------------
if "%verprop%"=="" (
  set verprop=%~dp0Projects\t6\ArchivedBuilds\versioncontrol.properties
)
for /f %%x in ('findstr /b "curr.version.num=" %verprop%') do (set tmpprevrevnum=%%x)&goto endfindprever
:endfindprever
if "%prevrevnum%"=="" (
  @REM TODO: 这里可能会变成 4 位，今后需要注意
  set /a prevrevnum=%tmpprevrevnum:~-4,4%
)
echo prevrevnum: %prevrevnum%
if "%prevvernum%"=="" (
  @REM TODO: 这里可能会变成 4 位，今后需要注意
  set prevvernum=%mainvernum%.%subvernum%.%prevrevnum%
)
echo prevvernum: %prevvernum%

@REM @set baseverrevisionnum=975
@REM @if "%baseversion%"=="" (
@REM   @set baseversion=%mainvernum%.%subvernum%.%baseverrevisionnum%
@REM )
@REM teamcity internal build num
@REM @set /a buildnum=%Files%

if "%currvernum%"=="" (
  set currvernum=%mainvernum%.%subvernum%.%revision_num%
)

if "%archivedirectory%"=="" (
  @REM @set archivedirectory=%~dp0Projects\t6\ArchivedBuilds\%mainvernum%.%subvernum%.%revision_num%.%buildnum%
  set archivedirectory=%~dp0Projects\t6\ArchivedBuilds\%currvernum%
)

rmdir /S /Q %archivedirectory% >nul 2>&1

set logdir=%archivedirectory%\log\
mkdir %logdir%

@if %errorlevel%==0 (
  echo set archivedirectory ok
) else (
  echo set archivedirectory error
  color 4
  pause
  exit /b 1
)


@REM -----------------------------------Mk Pack Dir----------------------------------------------


@title AutoBuilding.bat ......
call .\AutoBuilding.bat
@if %errorlevel%==0 (
  echo AutoBuilding.bat ok
) else (
  echo AutoBuilding.bat error
  call .\SendDingMsg.bat 1
  color 4
  pause
  exit /b 1
)

@title Packing.bat ......
call .\Packing.bat
@if %errorlevel%==0 (
  echo Packing.bat ok
  call .\SendDingMsg.bat 0
  exit /b 0
) else (
  echo Packing.bat error
  call .\SendDingMsg.bat 1
  color 4
  pause
  exit /b 1
)