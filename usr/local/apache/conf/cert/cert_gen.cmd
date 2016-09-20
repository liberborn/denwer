@echo off

REM Writed by Landgraph
REM http://www.landgraph.ru

set PATH=%PATH%;\usr\local\vcredist;\usr\local\apache\bin
set OPENSSL_CONF=\usr\local\apache\conf\openssl.cnf
set /P domain=Enter domain name [example.com]: 

IF "%DOMAIN%" == "" GOTO EOF

IF "%DOMAIN%" == "*" (
set dir=%~dp0all\
) ELSE (
set dir=%~dp0%DOMAIN%\
)

IF NOT EXIST "%dir%" mkdir "%dir%"

cd "%dir%"
cls
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!       Please, enter PIN 1234     !!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
openssl.exe genrsa -des3 -out "server.key" 1024

copy "server.key" "server.pin.key"
cls
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!       Please, enter PIN 1234     !!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
openssl.exe rsa -in "server.pin.key" -out "server.key"
cls
openssl.exe req -new -key "server.key" -out "server.csr" -subj "/C=RU/ST=Moscow/L=MOSCOW/O=None/OU=None/emailAddress=test@example.com/CN=%DOMAIN%"
openssl.exe x509 -req -days 3650 -in "server.csr" -signkey "server.key" -out "server.crt"
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo !!!            COMPLETE              !!!
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
pause