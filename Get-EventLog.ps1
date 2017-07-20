#Read Serverlist
$serverlist = Get-Content $PathToServerlist #PathToServerlist currently undefined
#Date declaration
$date = Get-Date
$DatetoDelete = $date.AddDays(-30)
$strDate = $date.ToString("yyyy-MM-dd")
#Logs analysed
$logs = "System", "Application"
#Number of elements
$elements = 250
#Create log file
$file = New-Item $PathToLogDir\$strDate.log -type File -force #PathToLogDir currently undefined
#Define SMTP Server
$smtp = New-Object Net.Mail.SmtpClient($mailserver) #Mailserver currently undefined
$message = ""


ForEach ($servername in $serverlist) {
    #Check if machine is online
    If (Test-Connection -Count 1 -ComputerName $servername -Quiet) {
                    
        Add-content $file "--------------------------"
        Add-content $file "Ereignisauswertung: $servername"
        Add-content $file "--------------------------"
        # Count events (information, warning, error)
        ForEach ($log in $logs) {            
            $events = Get-EventLog -log $log -newest $elements -computername $servername
            $inf_count = 0
            $err_count = 0
            $warn_count = 0
            ForEach ($event in $events) {
                If ($event.EntryType -eq "Information") {
                    $inf_count = $inf_count + 1 
                } ElseIf ($event.EntryType -eq "Error") {
                    $err_count = $err_count + 1 
                } ElseIf ($event.EntryType -eq "Warning") {
                    $warn_count = $warn_count + 1 
                }
            }
            If ($err_count -gt 42) {
                $message = $message + "Vorsicht bei $servername, mehr als $err_count Fehler.`n"
            }
            #Write to log file
            Add-content $file "Log: $log"
            Add-content $file "Fehler:`t`t`t$err_count"
            Add-content $file "Warnungen:`t`t$warn_count"
            Add-content $file "Informationen:`t$inf_count`r`n"
        } 
    }
    Else {
        Add-content $file "--------------------------"
        Add-content $file "Ereignisauswertung: $servername"
        Add-content $file "--------------------------"
        Add-content $file "$servername ist OFFLINE.`r`n"
    }
}
If ($message -ne "") {
    $smtp.Send($sender,$recipient,$Title,$message) #Sender, Recipient, Title currently undefined
}
#Remove old log files
Get-ChildItem $PathToLogDir | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
