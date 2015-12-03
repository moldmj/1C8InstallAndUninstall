﻿# зададим параметры по умолчанию. Данные параметры можно поменять передав их скрипту перед выполнением
param([string]$pfl = "\\Server\1CDistr", # путь до файла с наименованиями компьютеров на которые необходимо применить скрипт
      [string]$pdl = "\\Server\1CLog", # путь в домене с компьютерами к которым необходимо применить скрипт
      [string]$DHCPScope = "", # область IP адресов в которых необходимо искать компьютер для пробуждения (поиск происходит в DHCP). Если параметр пустой то будет осуществляться поиск компьютеров по всем серым сетям, в которых находятся активные DHCP сервера
      [string]$DHCPServer = "", # имя сервера DHCP на котором будет осуществляться поиск компьютера для пробуждения. Если параметр пуст то будут перебраны все активные DHCP сервера
      [string]$iod = "DESIGNERALLCLIENTS=1 THINCLIENT=1 THINCLIENTFILE=1") # параметры задаваемые при установке самой платформы

# Преобразуем все переменные к более читабельному виду
$PathFileList = $pfl
$PathDomenList = $pdl
$InstallPar = $ip
$DeletPar = $dp
$InstallOptDistr = $iod

# Вспомогательные параметры
$RegExpPatternNameFolderDistrib = "^\d+\.\d+\.\d+\.\d+$"
$RegExpPatternIPAdress = "^(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[0-9]{2}|[0-9])(\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[0-9]{2}|[0-9])){3}$" # регулярное выражение для валидного IP4

(Get-DhcpServerv4Lease -ComputerName eddardstark.umtc.local -ScopeId 0.0.0.0 | Where-Object {$_.HostName -match "Old001"}).ClientID
$DHCPServerActiveArray = (Get-DhcpServerInDC).DNSName # массив всех активных DHCP серверов
ForEach ($DHCPServerActive in $DHCPServerActiveArray) {
    $a = (Get-DhcpServerv4Lease -ComputerName $DHCPServerActive -ScopeId 0.0.0.0 | Where-Object {$_.HostName -match "Old001"}).ClientID
    If ($a -notmatch "") {
            Write-Host "good"
            Break
        }
    }


#======================================================================================
#======================================================================================
#================ Начало Функций ======================================================

# Благодоря данной функции окончание файла логирования всегода одинаковое
# Входящие данные: Путь до файла логирования
# Возвращяемые параметры: нет
Function EndLogFile($LogFile) {

# Функция служит для записи и поддержания однообразия записей в файле логировния
# Входящие данные: Путь до файла логирования и строка которую надо в него записать
# Возвращяемые параметры: нет
Function WriteLog($LogFile, $str) {
    ((Get-Date -UFormat "%Y.%m.%d %T") + " " + $str) >> $LogFile
}

# Благодоря данной функции окончание файла логирования всегода одинаковое
# Входящие данные: Путь до файла логирования
# Возвращяемые параметры: нет
Function EndLogFile($LogFile) {

# Данная функция вызывается в случае невозможности записи лог файлов в указанный для этого каталог
# Входящие данные: нет
# Возвращяемые параметры: прямой путь до лог файла
Function ErrDirLog {
    $LogFile = $env:LOCALAPPDATA + "\1C8InstallAndUninstall.log"
    If (-not (Test-Path -path $LogFile)) {
        # файл не существует, создадим его
        $LogFile = New-Item -Path $LogFile -ItemType "file"
    Return $LogFile

# функция находит все установленные программы 1С:Предприятия 8 на компьютере
# Входящие данные: нет
# Возвращяемые параметры: массив
Function SearchInstallPlatformInComputer {
    Return Get-WmiObject Win32_Product | Where-Object {$_.Name -match "^(1С|1C)"}   
}

# непосредстенное удаление 1С:Предприятие с компьютера
# Входящие данные: код продукта или путь до каталога с удаляемой версией, версия продукта, путь к файлу с логами
# Возвращяемые параметры: нет
Function UninstallPlatform ($Product, $ProductVer, $LogFile) {
    WriteLog $LogFile ("Удаление 1С:Предприятие, версия " + $ProductVer)
    # проверим что пришло в переменную $Product
    If ( -not ($Product -match "^{.*}$")) {
        # в переменную пришол путь к папке с дистрибутивом удаляемого продукта, преобразуем его
        # приведём полученные пути к каталогу установки к нужной форме добавив в них обратный слеш в конце
        If (-not $Product.EndsWith("\")) {$Product = $Product + "\"}
          
        # проверим соответствие переданой версии и версии находящейся в папке с установкой
        $SetupFile = Get-Content ($Product + "setup.ini")
        [string]$SetupFile -match "ProductVersion=(?<ver>$RegExpPatternNameFolderDistrib)"
        If ( -not ($ProductVer -match $matches.ver) ) {
            WriteLog $LogFile ("Внимание. Должна быть удалена версия " + $ProductVer + ", но в каталоге находиться версия " + $matches.ver + ", именно она будет удалена")
        }

        # Найдём msi файл удаляемого продукта

    Start-Process -Wait -FilePath msiexec -ArgumentList  ('/uninstall "' + $Product + '" /quiet /norestart /Leo+ "' + $LogFile + '"')
}

# непосредстенное установка 1С:Предприятие на компьютер
# Входящие данные: полный путь до папки с платформой, опции установки, версия устанавливаемого продукта, путь к файлу с логами
# Возвращяемые параметры: нет
Function InstallPlatform ($InstallFolder, $InstallOptDistr, $ProductVer, $LogFile){
    WriteLog $LogFile ("Установка 1С:Предприятие, версия " + $ProductVer)
    # приведём полученные пути к каталогу установки к нужной форме добавив в них обратный слеш в конце
    If (-not $InstallFolder.EndsWith("\")) {$InstallFolder = $InstallFolder + "\"}

    # проверим соответствие переданой версии и версии находящейся в папке с установкой
    $SetupFile = Get-Content ($InstallFolder + "setup.ini")
    [string]$SetupFile -match "ProductVersion=(?<ver>$RegExpPatternNameFolderDistrib)"
    If ( -not ($ProductVer -match $matches.ver) ) {
            WriteLog $LogFile ("Внимание. Должна быть установлена версия " + $ProductVer + ", но в каталоге находиться версия " + $matches.ver + ", именно она будет установлена")
    }

    # Найдём установочный msi файл

    # проверим опции установки, если они не соответствуют шаблону, то включим установку всех компонентов

#================= Конец Функций ======================================================
#======================================================================================
#======================================================================================

# приведём полученные пути к каталогам к нужной форме добавив в них обратный слеш в конце
If (-not $DistribDir.EndsWith("\")) {$DistribDir = $DistribDir + "\"}
If (-not $DirLog.EndsWith("\")) {$DirLog = $DirLog + "\"}

# для каждого из компьютеров будет свой лог файл соответствующий имени компьютера. в одной сети не может быть 2 компьютера с одинаковыми именами
$LogFile = $DirLog + $env:COMPUTERNAME + ".log"
# создадим вспомогательную переменную с описанием ошибки
$StrErr = ""

# проверим существование файла для логирования в указанном пути
If (Test-Path -path $LogFile) {
    # файл существует, попробум в него записать
    Try {
        Out-File -FilePath $LogFile -InputObject "" -Append -ErrorAction Stop
    } Catch {
        # опишем ошибку
        $StrErr = "Не удалось записать логи в $LogFile"
        $LogFile = ErrDirLog
    }
    # файл НЕ существует, попытаемся создадать его
    Try {
        $LogFile = New-Item -Path $LogFile -ItemType "file" -ErrorAction Stop
    } Catch {
        # опишем ошибку
        $StrErr = "Не удалось создать файл $LogFile"
        $LogFile = ErrDirLog
    }

# запишем данные о начале работы скрипта
" " >> $LogFile
"---------------------------------------------------------------------------------" >> $LogFile
# отработаем исключителюную операцию удаления всех дистрибутивов если в скрипт передали параметр -dp "all"
If ($DeletPar -match "all") {
    WriteLog $LogFile "Параметр удаления находяться в положении 'all', все остальные параметры игнорируются и производиться удаление всех найденных на компьютере платформ."
    # получим все установленные 1С платформы на компьютере
    $Array = SearchInstallPlatformInComputer
    # Последовательно удалим все платформы
    ForEach ($Element in $Array) {
        UninstallPlatform -Product $Element.IdentifyingNumber -ProductVer $Element.Version -LogFile $LogFile    
    }
    EndLogFile -LogFile $LogFile
}

# Проверим необходимость дальнейших действий. Параметры установки и удаления находятся в положении "no"?
    EndLogFile -LogFile $LogFile
}
    WriteLog $LogFile "Параметр инсталяции и установки не подходит не под один из известных, ни каких действий выполнять не требуется."
}
# После всех проверок выше можно заключить что имеется хотябы один из параметров "x.x.x.x" или "last" или "ael" 
#  прверим доступ к каталогу с дистрибутивами, как указано выше, для выполнения одноиго из параметров нам понадобиться доступ к каталогу с дистрибутивами
If (-not (Test-Path -path $DistribDir)) {
    # доступ к каталогу с дистрибутивами 1С закрыт или не существует, запишем это и выйдем из скрипта
    WriteLog $LogFile "Не удалось получить доступ к каталогу с дистрибутивами 1С, проверьте путь и права доступа $DistribDir"
    EndLogFile -LogFile $LogFile
}
}

# произведём установку если было заданано установить конкретную версию
}

If ( ($InstallPar -match "last") -or ($DeletPar -match "ael") ) {
    # составим массив из всех имён папок находящихся в дистрибутивах и имеющих вид версии продукта
    $AllPlatforms = (Get-ChildItem -Path $DistribDir | Where-Object { ($_.Mode -match "^d*") -and ($_.Name -match $RegExpPatternNameFolderDistrib) }).Name

    # посмотрим на кол-во найденых дистрибутивов
        EndLogFile -LogFile $LogFile
    } elseif ($AllPlatforms.Length -eq 1) {
        If ($InstallPar -match 'last' ) {
            WriteLog $LogFile "Найден только один дитрибутив. Он будет установлен как самый старший."
            InstallPlatform -InstallFolder ($DistribDir + $AllPlatforms[0]) -InstallOptDistr $InstallOptDistr -ProductVer $AllPlatforms[0] -LogFile $LogFile
        } ifelse ($DeletPar -match 'ael') {
            WriteLog $LogFile "Найден только один дитрибутив. Удаление произведено не будет, т.к. данный дистрибутив является последним (старшим)."
        }
        EndLogFile -LogFile $LogFile
    }

    # было найдено много дистрибутивов, найдём самый старший из них
    
        ForEach ($InstallPlatformInComputer in $ArrayInstallPlatformsInComputer) {
            ForEach ($PlatformInFolder in $AllPlatforms) {
                If ( ($InstallPlatformInComputer.Version -match $PlatformInFolder) -and -not ($PlatformInFolder -match $LastDistr) ) {
                    UninstallPlatform -Product ($DistribDir + $PlatformInFolder) -ProductVer $PlatformInFolder -LogFile $LogFile
                }
            }
        }
    }

            If ($InstallPlatformInComputer.Version -match $LastDistr) {$FlagLastPlatformInstall = $true}
        }
        If (-not $FlagLastPlatformInstall) {
            InstallPlatform -InstallFolder ($DistribDir + $LastDistr) -InstallOptDistr $InstallOptDistr -ProductVer $LastDistr -LogFile $LogFile
        } else {
            WriteLog $LogFile "Последняя (старшая) платформа $LastDistr уже установлена."
        }
    }
}

EndLogFile -LogFile $LogFile