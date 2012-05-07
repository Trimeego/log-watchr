param($FilePath,$LogChannel)

Function PostLog ($app, $message)
{
  $url = "http://watchr.labs.icggroupinc.com/api/logs"
  $message = $message.Replace("'", "|").Replace("`"", "|")

  $command = '{"application": "' + $app + '", "message": "' + $message + '"}'
  echo $command
  $bytes = [System.Text.Encoding]::ASCII.GetBytes($command)
  $web = [System.Net.WebRequest]::Create($url)
  $web.Method = "POST"
  $web.ContentLength = $bytes.Length
  $web.ContentType = "application/json"
  $stream = $web.GetRequestStream()
  $stream.Write($bytes,0,$bytes.Length)
  $stream.close()

  $reader = New-Object System.IO.Streamreader -ArgumentList $web.GetResponse().GetResponseStream()
  $reader.ReadToEnd()
  $reader.Close()  
}


$Newline = $([Environment]::Newline)
$Wait = 1
$numLines = 10
$seekOffset = -1;
$PathIntrinsics = $ExecutionContext.SessionState.Path

if ($PathIntrinsics.IsProviderQualified($FilePath))
{
    $FilePath = $PathIntrinsics.GetUnresolvedProviderPathFromPSPath($FilePath)
}

Write-Verbose "Tail-Content processing $FilePath"

try 
{        
    $output = New-Object "System.Text.StringBuilder"
    $newlineIndex = $Newline.Length - 1

    $fs = New-Object "System.IO.FileStream" $FilePath,"Open","Read","ReadWrite"    
    $oldLength = $fs.Length

    while ($numLines -gt 0 -and (($fs.Length + $seekOffset) -ge 0)) 
    {
    	[void]$fs.Seek($seekOffset--, "End")
    	$ch = $fs.ReadByte()
        
        if ($ch -eq 0 -or $ch -gt 127) 
        {
            throw "Tail-Content only works on ASCII encoded files"
        }
        
        [void]$output.Insert(0, [char]$ch)
        
        # Count line terminations
    	if ($ch -eq $Newline[$newlineIndex]) 
        {
            if (--$newlineIndex -lt 0) 
            {
                $newlineIndex = $Newline.Length - 1
                # Ignore the newline at the end of the file
                if ($seekOffset -lt -($Newline.Length + 1))
                {
                    $numLines--
                }
            }
            continue
        }
    }
                
    # Remove beginning line terminator
    $output = $output.ToString().TrimStart([char[]]$Newline)
    Write-Host $output -NoNewline
    
    if ($Wait)
    {            
        # Now push pointer to end of file 
        [void]$fs.Seek($oldLength, "Begin")
        
        for(;;)
        {
            if ($fs.Length -gt $oldLength)
            {
                $numNewBytes = $fs.Length - $oldLength
                $buffer = new-object byte[] $numNewBytes
                $numRead = $fs.Read($buffer, 0, $buffer.Length)
                
                $string = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $buffer.Length)
                #Write-Host $string -NoNewline
                $string = $string.trim()
                try{
                  PostLog $LogChannel $string
                }
                catch {
                  sWrite-Host "posr error"
                }
                                    
                $oldLength += $numRead
            }
            Start-Sleep -Milliseconds 300
        }
    }
}
finally 
{
    if ($fs) { $fs.Close() }
}    


#Get-Content $FilePath -wait | Foreach-Object {PostLog $LogChannel $_}
