(: 
Copyright 2002-2011 MarkLogic Corporation.  All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

@author Justin Makeig <jmakeig@marklogic.com>

:)
xquery version "1.0-ml";

import module namespace cpf = "http://marklogic.com/cpf" at "/MarkLogic/cpf/cpf.xqy";
declare option xdmp:mapping "false";

(: Variables that CPF populates :)
declare variable $cpf:document-uri as xs:string external;
declare variable $cpf:transition as node() external;

if(cpf:check-transition($cpf:document-uri, $cpf:transition))
then
    try {
    	(: Make sure the current row has categories :)
			for $row in doc($cpf:document-uri)/row[categories]
			(: Tokenize the categories by comma-spaces :)
			let $cats := tokenize($row/categories/string(), "\s*,\s*")
			return 
				xdmp:node-replace(
					$row/categories,
					(: Build a new categories node with a category element for each category :)
					<categories>{
						for $cat in $cats
						return <category>{$cat}</category>
					}</categories>
				),
       cpf:success( $cpf:document-uri, $cpf:transition, () )
    }
    catch ($e) {
       cpf:failure( $cpf:document-uri, $cpf:transition, $e, () )
    }
else ()