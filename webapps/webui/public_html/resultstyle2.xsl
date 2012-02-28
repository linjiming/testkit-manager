<?xml version="1.0" encoding="UTF-8"?>
	<!--
# Copyright (C) 2010 Intel Corporation
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#   Authors:
#
#          Tang, Shao-Feng  <shaofeng.tang@intel.com>
#

	-->
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:template match="/">
		<html>
			<body>
				<xsl:for-each select="testresults/suite">
					<xsl:sort select="@name" />
					<h2>
						<font size="4" face="Arial">
							Suite:
							<xsl:value-of select="@name" />
						</font>
					</h2>
					<xsl:for-each select=".//set">
						<xsl:sort select="@name" />
						<h3>
							<font size="4" face="Arial">
								Set:
								<xsl:value-of select="@name" />
							</font>
						</h3>
						<xsl:for-each select=".//case">
							<xsl:sort select="@name" />
							<p>
								<h4>
									<font size="2.5" face="Arial">
										<xsl:if test="@manual = 'true'">
											Manual Case:
										</xsl:if>
										<xsl:if test="@manual = 'false'">
											Automatic Case:
										</xsl:if>
										<xsl:value-of select="@name" />
									</font>
									<br />
									<xsl:if test="@result = 'FAIL'">
										<font size="2" face="Arial" color="Red">
											Result:
											<xsl:value-of select="@result" />
										</font>
									</xsl:if>
									<xsl:if test="@result != 'FAIL'">
										<font size="2.5" face="Arial" color="Green">
											Result:
											<xsl:value-of select="@result" />
										</font>
									</xsl:if>
								</h4>
								<font size="2" face="Arial">
									<B>Description: </B>
									<xsl:variable name="case_name" select="@name" />
									<div>
										<xsl:attribute name="id"><xsl:value-of select='translate(@name, "&apos;", " ")' /></xsl:attribute>
									</div>
									<script language="JavaScript">
										var di = document.getElementById('<xsl:value-of select='translate(@name, "&apos;", " ")' />');
										di.innerHTML = '<xsl:value-of  select="//case[@name = $case_name and last()]/description" />';
      								</script>
								</font>
								<br />
								<xsl:for-each select=".//step">
									<font size="2" face="Arial">
										<B>Command: </B>
										<xsl:value-of select="@command" />
									</font>
									<br />
									<font size="2" face="Arial">
										<B>Result: </B>
										<xsl:value-of select="@result" />
									</font>
									<br />
									<font size="2" face="Arial">
										<B>Return Code: </B>
										<xsl:value-of select="return_code" />
									</font>
									<br />
									<font size="2" face="Arial">
										<B>Expected: </B>
										<xsl:value-of select="expected_result" />
									</font>
									<br />
									<font size="2" face="Arial">
										<B>Start time: </B>
										<xsl:value-of select="start" />
									</font>
									<br />
									<font size="2" face="Arial">
										<B>End time: </B>
										<xsl:value-of select="end" />
									</font>
									<br />
									<font size="2" face="Arial">
										<B>stdout: </B>
										<xsl:call-template name="br-replace">
											<xsl:with-param name="word" select="stdout" />
										</xsl:call-template>
									</font>
									<br />
									<font size="2" face="Arial">
										<B>stderr: </B>
										<xsl:call-template name="br-replace">
											<xsl:with-param name="word" select="stderr" />
										</xsl:call-template>
									</font>
									<br />
								</xsl:for-each>
								<p>------------------------------------------------------------------------------------------------------</p>
							</p>
						</xsl:for-each>
					</xsl:for-each>
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>
	<xsl:template name="br-replace">
		<xsl:param name="word" />
		<xsl:variable name="cr">
			<xsl:text>
</xsl:text>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="contains($word,$cr)">
				<xsl:value-of select="substring-before($word,$cr)" />
				<br />
				<xsl:call-template name="br-replace">
					<xsl:with-param name="word" select="substring-after($word,$cr)" />
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$word" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>