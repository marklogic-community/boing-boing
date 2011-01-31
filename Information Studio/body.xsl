<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:xdmp="http://marklogic.com/xdmp" xmlns:error="http://marklogic.com/xdmp/error" extension-element-prefixes="xdmp">
  <!-- Default copy template -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  <!-- Get rid of elements whose value is NULL -->
  <xsl:template match="*[normalize-space(.) eq 'NULL']" priority="10" />
  <!-- Clean up dates to make them castable as xs:dateTime -->
  <xsl:template match="created_on">
    <created_on><xsl:value-of select='replace(string(.), " ", "T")'/></created_on>
  </xsl:template>
  <!-- Parse -->
  <xsl:template match="body|body_more">
    <xsl:copy>
      <xdmp:try>
        <xsl:copy-of select="xdmp:unquote(concat('&lt;div&gt;',string(text()),'&lt;/div&gt;'), 'http://www.w3.org/1999/xhtml', ('repair-full'))"/>
        <xdmp:catch name="e">
          <xsl:attribute name="orig"><xsl:value-of select="text()"/></xsl:attribute>
          <xsl:attribute name="parse-error"><xsl:value-of select="$e/error:format-string"/></xsl:attribute>
          <xsl:copy-of select="text()"/>
        </xdmp:catch>
      </xdmp:try>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>