$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 Edg/128.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("checkCookiesEnabled", "value", "/", "guestaup-eun.linklaters.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("APPSESSIONID", "B988E2996AD23154CDBC98766E8D6F82", "/", "guestaup-eun.linklaters.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("token", "DE1QYIGOTTQ5CD5I3TIV35LHTBUJDFIS", "/", "guestaup-eun.linklaters.com")))
$session.Cookies.Add((New-Object System.Net.Cookie("portalSessionId", "713a5936-91f5-4244-868f-77777e5a3746", "/", "guestaup-eun.linklaters.com")))
Invoke-WebRequest -UseBasicParsing -Uri "https://guestaup-eun.linklaters.com:8443/portal/AupSubmit.action?from=AUP" `
-Method "POST" `
-WebSession $session `
-Headers @{
"Accept"="text/html, */*; q=0.01"
  "Accept-Encoding"="gzip, deflate, br, zstd"
  "Accept-Language"="en-US,en;q=0.9,en-GB;q=0.8"
  "Origin"="https://guestaup-eun.linklaters.com:8443"
  "Referer"="https://guestaup-eun.linklaters.com:8443/portal/PortalSetup.action?portal=1534a796-0604-4b14-b791-30fe6ef8ecc7&sessionId=0114280A0000D0B104F043ED&action=cwa&redirect=http%3A%2F%2Fwww.msftncsi.com%2F"
  "Sec-Fetch-Dest"="empty"
  "Sec-Fetch-Mode"="cors"
  "Sec-Fetch-Site"="same-origin"
  "X-Requested-With"="XMLHttpRequest"
  "sec-ch-ua"="`"Chromium`";v=`"128`", `"Not;A=Brand`";v=`"24`", `"Microsoft Edge`";v=`"128`""
  "sec-ch-ua-arch"="`"x86`""
  "sec-ch-ua-full-version"="`"128.0.2739.63`""
  "sec-ch-ua-mobile"="?0"
  "sec-ch-ua-model"="`"`""
  "sec-ch-ua-platform"="`"Windows`""
  "sec-ch-ua-platform-version"="`"15.0.0`""
} `
-ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
-Body "token=DE1QYIGOTTQ5CD5I3TIV35LHTBUJDFIS&aupAccepted=false"
