xquery version "1.0-ml";

(: Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved. :)

(:
:: Custom action.  It must be a CPF action module.
:: Replace this text completely, or use it as a template and 
:: add imports, declarations,
:: and code between START and END comment tags.
:: Uses the external variables:
::    $cpf:document-uri: The document being processed
::    $cpf:transition: The transition being executed
:)

import module namespace cpf = "http://marklogic.com/cpf"
   at "/MarkLogic/cpf/cpf.xqy";

(: START custom imports and declarations; imports must be in Modules :)


(: END custom imports and declarations :)

declare option xdmp:mapping "false";

declare variable $cpf:document-uri as xs:string external;
declare variable $cpf:transition as node() external;

if ( cpf:check-transition($cpf:document-uri,$cpf:transition))
then
    try {
       (: START your custom XQuery here :)
for $row in doc($cpf:document-uri)/row[categories]
let $cats := tokenize($row/categories/string(), "\s*,\s*")
return 
xdmp:node-replace(
$row/categories,
<categories>{
for $cat in $cats
return <category>{$cat}</category>
}</categories>
)


       (: END your custom XQuery here :)
       ,
       cpf:success( $cpf:document-uri, $cpf:transition, () )
    }
    catch ($e) {
       cpf:failure( $cpf:document-uri, $cpf:transition, $e, () )
    }
else ()