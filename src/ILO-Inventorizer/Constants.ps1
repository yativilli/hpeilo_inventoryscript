### Constants
$RECOMMENDED_VERSION = "4.4.0.0";
$DEFAULT_PATH = $ENV:APPDATA + "\hpeilo"
$NO_VALUE_FOUND_SYMBOL = "-";
$DATE_FILENAME = "yyyy_MM_dd";
$DEFAULT_USERNAME_ILO = "Administrator";
$DEFAULT_PATH_TEMPORARY = $ENV:TEMP + "\hpeilo";
$PART_DEFAULT_PATH_UNREACHABLE_SERVERS = "\unreachable_servers.txt";

Function Get-NoValueFoundSymbol {
    return $NO_VALUE_FOUND_SYMBOL;
}