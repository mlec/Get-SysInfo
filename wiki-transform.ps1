#http://msdn.microsoft.com/en-us/library/system.xml.xsl.aspx
param(
	[string]$xmlIn = $(Read-Host -prompt "Please enter the path to the xml document to be transformed:"),
	[string]$xslIn = $(Read-Host -Prompt "Please enter the path to the xsl transform file to use:")
	)
	

IF(!(Test-Path $xmlIn)){Write-Host "Cannot find xml file. Script terminating."}
elseif(!(Test-Path $xslIn)){Write-Host "Cannot find xsl file. Script terminating."}
else {

$myDir = (Get-Location)
#$xmlIn = "$myDir\test.xml"
#$xslIn = "$myDir\key-info.xsl"
$output = "$myDir\wiki.txt"



$xsl = [xml](Get-Content $xslIn)

$xmlString = Get-Content $xmlIn

#[string]$result

$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
[Void]$xslt.Load($xsl);
[Void]$xslt.Transform($xmlIn, $output);

#Write-Host $result

}