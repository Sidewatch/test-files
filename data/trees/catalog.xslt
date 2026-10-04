<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" indent="yes"/>
  <xsl:template match="/catalog">
    <html>
      <body>
        <h1>Catalog</h1>
        <ul>
          <xsl:apply-templates select="book"/>
        </ul>
      </body>
    </html>
  </xsl:template>
  <xsl:template match="book">
    <li>
      <xsl:value-of select="dc:title" xmlns:dc="http://purl.org/dc/elements/1.1/"/>
      <xsl:text> — </xsl:text>
      <xsl:value-of select="price"/>
    </li>
  </xsl:template>
</xsl:stylesheet>
