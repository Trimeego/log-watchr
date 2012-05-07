param($FilePath,$LogChannel)

Function PostLog ($app, $message)
{
  $url = "http://watchr.labs.icggroupinc.com/api/logs"
  $message = $message.Replace("'", "|").Replace("`"", "")

  $command = '{"application": "' + $app + '", "message": "' + $message + '"}'

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

Get-Content $FilePath -wait | Foreach-Object {PostLog $LogChannel $_}
