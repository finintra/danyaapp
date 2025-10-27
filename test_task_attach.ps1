$url = "http://192.168.31.252:3000/flf/api/v1/task/attach"
$token = "your_auth_token_here" # Replace with a valid token

$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $token"
}

$body = @{
    "picking_barcode" = "OUT/00001"
} | ConvertTo-Json

Write-Host "Request URL: $url"
Write-Host "Request headers: $($headers | ConvertTo-Json)"
Write-Host "Request body: $body"

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "application/json"
    Write-Host "Response: $($response | ConvertTo-Json -Depth 4)"
} catch {
    Write-Host "Error: $_"
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.value__)"
    Write-Host "Status Description: $($_.Exception.Response.StatusDescription)"
    
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
    Write-Host "Response Body: $responseBody"
}
