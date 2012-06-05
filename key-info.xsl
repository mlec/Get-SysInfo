<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!--	This transform file converts xml output of Get-ServerInfo.ps1 to a text file
		that is formatted to be inserted into SOMIS SysAdmin Wiki page for server
		documentation. This transform tries to duplicate, as closely as possible,
		existing scripts used by Linux servers.
		
		ASSUMPTIONS:
			The following assumptions are made by the script:
			
			- If the server contains more than one processor, this script assumes that
			  both processors are the same.
			- If the server is a virtual server, the amount of physical memory is stated
			  as "0 Modules Installed" as there are no physical modules for a vm.
			- Sizes of Memory in the output of Get-ServerInfo.ps1 are in KB, so this script 
			  assumes the lowest unit is 1 KB
			- Sizes of Disk in the output of Get-ServerInfo.ps1 are in bytes, so this script
			  assumes the lowest unit is 1 byte
		
		NOTES:
			Created by: Michael Lecuona
			Date Coded: 5/9/2012
			
			
-->

<xsl:output method="text" />
<xsl:template match="/server">

<!-- Section Header -->
<xsl:text>---++ Key Info&#10;</xsl:text>

  <xsl:text>   * Platform: </xsl:text>
  <xsl:for-each select="/server/platform">
  <xsl:value-of select="@manufacturer" /><xsl:text>, </xsl:text>
  <xsl:value-of select="@model" /><xsl:text>, BIOS: v</xsl:text>
  <xsl:value-of select="@smbiosversion" /><xsl:text>, Serial: </xsl:text>
  <xsl:value-of select="@serialnumber" /><xsl:text>&#10;</xsl:text>
  </xsl:for-each>

  <!-- CPU Info **section assumes both processors are the same** -->
  <xsl:text>   * CPU(s): </xsl:text>
  <xsl:value-of select="/server/processor[@deviceid='CPU0']/@countphysical" /><xsl:text> x </xsl:text>
  <xsl:value-of select="normalize-space(/server/processor[@deviceid='CPU0']/@name)" /><xsl:text> Installed.</xsl:text><xsl:text>&#10;</xsl:text>
  
  <!-- Memory Info **Converstion to Human-readable Memory size and available assumes values are given in KB** -->
  <xsl:text>   * Memory: </xsl:text>
  <xsl:for-each select="/server/memory">
  <xsl:choose>
  <xsl:when test="@count &gt;= 0"><xsl:value-of select="@count" /><xsl:text> Modules Installed, </xsl:text></xsl:when>
  <xsl:otherwise><xsl:text>0 Modules Installed, </xsl:text></xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
  <xsl:when test="@size div 1024 &lt; 1"><xsl:value-of select="@size" /><xsl:text> KB Total</xsl:text><xsl:text>&#10;</xsl:text></xsl:when>
  <xsl:when test="@size div 1048576 &lt; 1"><xsl:value-of select="format-number((@size div 1024),'0.00')" /><xsl:text> MB Total</xsl:text><xsl:text>&#10;</xsl:text></xsl:when>
  <xsl:otherwise><xsl:value-of select="format-number((@size div 1048576),'0.00')" /><xsl:text> GB Total</xsl:text><xsl:text>&#10;</xsl:text></xsl:otherwise>
  </xsl:choose>
  </xsl:for-each>
  
  <!-- OS Info -->
  <xsl:text>   * OS: </xsl:text>
  <xsl:for-each select="/server/os">
  <xsl:value-of select="@name" />
  <xsl:if test="@servicepack &gt;= 1">
	<xsl:text> Service Pack </xsl:text><xsl:value-of select="@servicepack" />
  </xsl:if>
  <xsl:text>&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
  
  <!-- Network Interfaces -->
  <xsl:text>---+++ Network Interfaces&#10;</xsl:text>
  <xsl:text>| =DNS Name= | =Public IP= | =Private IP= | =Subnet= | =Interface Name= | =MAC Address=|&#10;</xsl:text>
  <xsl:for-each select="/server/net">
  <xsl:text>| </xsl:text>
  <xsl:if test="@dnsname != ''"><xsl:text>=</xsl:text><xsl:value-of select="@dnsname" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> | </xsl:text>
  <xsl:if test="@publicIP != ''"><xsl:text>=</xsl:text><xsl:value-of select="@publicIP" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> | </xsl:text>
  <xsl:if test="@publicIP = @privateIP"><xsl:text>=--=</xsl:text></xsl:if>
  <xsl:if test="@publicIP != @privateIP"><xsl:if test="@privateIP != ''"><xsl:text>=</xsl:text><xsl:value-of select="@privateIP" /><xsl:text>=</xsl:text></xsl:if></xsl:if>
  <xsl:text> | </xsl:text>
  <xsl:if test="@subnet != ''"><xsl:text>=</xsl:text><xsl:value-of select="@subnet" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> | </xsl:text><xsl:if test="@name != ''"><xsl:text>=</xsl:text><xsl:value-of select="@name" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> | </xsl:text><xsl:if test="@MACaddress != ''"><xsl:text>=</xsl:text><xsl:value-of select="@MACaddress" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> |&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
  
  <!-- Disk Info -->
  <xsl:text>---+++ Disk Information&#10;</xsl:text>
  <xsl:text>| =Drive Letter= | =Volume Name= | =Size= | =Free Space= | =File System= | =Drive Type= |&#10;</xsl:text>
  <xsl:for-each select="/server/disk">
  <xsl:text>| </xsl:text>
  <xsl:if test="@DeviceID != ''"><xsl:text>=</xsl:text><xsl:value-of select="@DeviceID" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@VolumeName != ''"><xsl:text>=</xsl:text><xsl:value-of select="@VolumeName" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:if test="@ProviderName != ''"><xsl:text>=</xsl:text><xsl:value-of select="@ProviderName" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@Size != ''"><xsl:text>=</xsl:text>
  <xsl:choose>
  <xsl:when test="@Size div 1024 &lt; 1"><xsl:value-of select="@Size" /><xsl:text> bytes</xsl:text></xsl:when>
  <xsl:when test="@Size div 1048576 &lt; 1"><xsl:value-of select="format-number((@Size div 1024),'0.00')" /><xsl:text> KB</xsl:text></xsl:when>
  <xsl:when test="@Size div 1073741824 &lt; 1"><xsl:value-of select="format-number((@Size div 1048576),'0.00')" /><xsl:text> MB</xsl:text></xsl:when>
  <xsl:when test="@Size div 1099511627776 &lt; 1"><xsl:value-of select="format-number((@Size div 1073741824),'0.00')" /><xsl:text> GB</xsl:text></xsl:when>
  <xsl:otherwise><xsl:value-of select="format-number((@Size div 1099511627776),'0.00')" /><xsl:text> TB</xsl:text></xsl:otherwise>
  </xsl:choose>
  <xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@FreeSpace != ''"><xsl:text>=</xsl:text>
  <xsl:choose>
  <xsl:when test="@FreeSpace div 1024 &lt; 1"><xsl:value-of select="@FreeSpace" /><xsl:text> bytes</xsl:text></xsl:when>
  <xsl:when test="@FreeSpace div 1048576 &lt; 1"><xsl:value-of select="format-number((@FreeSpace div 1024),'0.00')" /><xsl:text> KB</xsl:text></xsl:when>
  <xsl:when test="@FreeSpace div 1073741824 &lt; 1"><xsl:value-of select="format-number((@FreeSpace div 1048576),'0.00')" /><xsl:text> MB</xsl:text></xsl:when>
  <xsl:when test="@FreeSpace div 1099511627776 &lt; 1"><xsl:value-of select="format-number((@FreeSpace div 1073741824),'0.00')" /><xsl:text> GB</xsl:text></xsl:when>
  <xsl:otherwise><xsl:value-of select="format-number((@FreeSpace div 1099511627776),'0.00')" /><xsl:text> TB</xsl:text></xsl:otherwise>
  </xsl:choose>
  <xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@FileSystem != ''"><xsl:text>=</xsl:text><xsl:value-of select="@FileSystem" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@Description != ''"><xsl:text>=</xsl:text><xsl:value-of select="@Description" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> |&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
  
  <!-- Local Users -->
  <xsl:text>---++ Local User Accounts&#10;</xsl:text>
  <xsl:text>| =Name= | =Password Expires= | =User Changeable Password= | =Account Disabled= |&#10;</xsl:text>
  <xsl:for-each select="/server/localuser">
  <xsl:text>| </xsl:text>
  <xsl:if test="@Name != ''"><xsl:text>=</xsl:text><xsl:value-of select="@Name" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@PasswordExpires != ''"><xsl:text>=</xsl:text><xsl:value-of select="@PasswordExpires" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@PasswordChangeable != ''"><xsl:text>=</xsl:text><xsl:value-of select="@PasswordChangeable" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text>| </xsl:text>
  <xsl:if test="@Disabled != ''"><xsl:text>=</xsl:text><xsl:value-of select="@Disabled" /><xsl:text>=</xsl:text></xsl:if>
  <xsl:text> |&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
  
    <!-- Local Administrator Group -->
  <xsl:text>---++ Local Administrator Group Members&#10;</xsl:text>
  <xsl:for-each select="/server/adminmember">
  <xsl:text>   * </xsl:text>
  <xsl:value-of select="@Name" /><xsl:text>&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
  
  
  </xsl:template>
</xsl:stylesheet>