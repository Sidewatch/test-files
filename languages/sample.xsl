<?xml version="1.0" encoding="UTF-8"?>
<!-- XSLT 1.0: orders XML to an HTML table, paid first. -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="yes"/>
  <xsl:param name="currency" select="'GBP'"/>

  <xsl:template match="/orders">
    <html>
      <body>
        <h1>Orders (<xsl:value-of select="count(order)"/>)</h1>
        <table>
          <xsl:apply-templates select="order">
            <xsl:sort select="@status = 'paid'" order="descending"/>
            <xsl:sort select="@number" data-type="number"/>
          </xsl:apply-templates>
        </table>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="order">
    <tr>
      <xsl:attribute name="class"><xsl:value-of select="@status"/></xsl:attribute>
      <td>#<xsl:value-of select="@number"/></td>
      <td><xsl:value-of select="format-number(total, '#,##0.00')"/><xsl:text> </xsl:text><xsl:value-of select="$currency"/></td>
      <xsl:if test="@status = 'paid'"><td>&#10003;</td></xsl:if>
    </tr>
  </xsl:template>
</xsl:stylesheet>
