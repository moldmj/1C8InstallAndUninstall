###############################################################################
# Имя скрипта:  Установка и удаление дистрибутивов 1С:Предприятия 8 на локальных компьютерах
# Автор: Dim
# Версия: 0.11
# Прочитать статью по работе со скриптом и обсудить несущие вопросы можно по адресу http://infostart.ru/public/299829/
# Входные параметры:
#    -dd -- Distribution Directory -- путь до каталога с дистрибутивами платфоры 1С 8
#    -dl -- Directory Logs -- путь до каталога в который будут записываться логи установки и удаления
#    -ip -- Install Parameters -- параметры инсталяции согласно которым будет работать скрипт
#        "no" - не производить установку 
#        "last" - установить последнию найденную версия в каталоге с дистрибутивами 1С 8
#        "8.3.5.1111" - установить конкретный дистрибутив платформы
#    -dp -- Delet Parameters -- параметры удаления соответствии с которыми будет работать скрипт
#        "no" - не производить удаление 
#        "ael" - удалить все версии кроме последней (all except last)
#        "8.3.5.1111" - удалить конкретный дистрибутив платформы
#        "all" - удалить все дистрибутивы 1С:Предприятие 8 найденые на локальном компьютере
#    -iod -- Installation Options Distribution -- параметры задаваемые при установке самой платформы, выглядят как строка "DESIGNERALLCLIENTS=1 THINCLIENT=0 THINCLIENTFILE=0"
#        "DESIGNERALLCLIENTS" - основной клиент и конфигуратор
#        "THINCLIENT" - тонкий клиент для клиент-серверного варианта работы
#        "THINCLIENTFILE" - тонкий клиент с возможностью работы с файловыми информационными базами
# Описание Скрипта: Данный скрипт удаляет и устанавливает дистрибутивы 1С из сетевого каталога и пишит логи установки
#    Тонкости работы:
#        1. Если по какой либо причине скрипт не сможет записать логи в указанный каталог, то запись будет произведена в файл 1C8InstallAndUninstall.log в локальный каталог пользователя, примерный путь: c:\Users\Vasa\AppData\Local\
#        2. Параметр "last" у ключа -ip установит последнюю версию из найденных в каталоге дистрибутивов
#        3. Параметр "ael", у ключа -dp, удалит только те установленные версии которые будут в каталоге с дистрибутивами
#        4. Параметр "all", у ключа -dp, подавляет все другие параметры и является приоритетным, более того, он удалит всё установленное, похоже на платформу 1С:Предвриятие, несмотря на то что лежит в каталого с дистрибутивами
#        5. В каталоге с дистрибутивами рассматриваются только папки вида "Х.Х.Х.Х", соответствующие версии платформы в ней находящеёся. Все остальные папки и файлы игнорируются
###############################################################################
