let $xml := xdmp:document-get('/Users/jmakeig/Downloads/bbpostdump.xml', <options xmlns="xdmp:document-get">
      <repair>full</repair>
      <encoding>auto</encoding>
    </options>)
for $row in $xml/custom/row
return
  xdmp:save(concat("/Users/jmakeig/tmp/data/boing-boing/", xdmp:md5($row), ".xml"), $row)
