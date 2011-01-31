xquery version "1.0-ml";

(: Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved. :)

(:

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

declare namespace itunes = "http://marklogic.com/extension/plugin/boingboing";

import module namespace plugin = "http://marklogic.com/extension/plugin" at "/MarkLogic/plugin/plugin.xqy";
import module namespace info="http://marklogic.com/appservices/infostudio" at "/MarkLogic/appservices/infostudio/info.xqy";
import module namespace infodev="http://marklogic.com/appservices/infostudio/dev" at "/MarkLogic/appservices/infostudio/infodev.xqy";

declare namespace ml="http://marklogic.com/appservices/mlogic";
declare namespace lbl="http://marklogic.com/xqutils/labels";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace atom = "http://www.w3.org/2005/Atom";

declare namespace t="http://marklogic.com/demo/tunes";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(:~ Map of capabilities implemented by this Plugin.
:
: Required capabilities for all Collectors
: - http://marklogic.com/appservices/infostudio/collector/model
: - http://marklogic.com/appservices/infostudio/collector/start
: - http://marklogic.com/appservices/string
:)

declare function itunes:capabilities()
as map:map
{
    let $map := map:map()
    let $_ := map:put($map, "http://marklogic.com/appservices/infostudio/collector/model", xdmp:function(xs:QName("itunes:model")))
    let $_ := map:put($map, "http://marklogic.com/appservices/infostudio/collector/start", xdmp:function(xs:QName("itunes:start")))
    let $_ := map:put($map, "http://marklogic.com/appservices/infostudio/collector/config-view", xdmp:function(xs:QName("itunes:view")))
    let $_ := map:put($map, "http://marklogic.com/appservices/infostudio/collector/cancel", xdmp:function(xs:QName("itunes:cancel")))
    let $_ := map:put($map, "http://marklogic.com/appservices/infostudio/collector/validate", xdmp:function(xs:QName("itunes:validate")))
    let $_ := map:put($map, "http://marklogic.com/appservices/string", xdmp:function(xs:QName("itunes:string")))
    return $map
};

(:~ Data model underlying UI; represents the data to be passed into invoke :)
declare function itunes:model()
as element(plugin:plugin-model)
{
    <plugin:plugin-model>
      <plugin:data>
        <uri>/Users/jmakeig/Downloads/bbpostdump.xml</uri>
      </plugin:data>
    </plugin:plugin-model>
};

(:~ Invoke the plugin :)
declare function itunes:start(
  $model as element(),
  $ticket-id as xs:string,
  $policy-deltas as element(info:options)?
)
as empty-sequence()
{
		let $_ := xdmp:log(fn:concat("Loading from: ", fn:data($model/plugin:data/*:uri)))
    
		let $xml := xdmp:document-get(data($model/plugin:data/*:uri), <options xmlns="xdmp:document-get">
      <repair>full</repair>
      <encoding>auto</encoding>
    </options>)
    
    let $_ := xdmp:log(info:ticket($ticket-id))
    
		
		let $tracks := $xml/custom/row
		let $total := count($tracks)
		
    (: get transaction-size from policy :)
    let $policy-name := fn:data(info:ticket($ticket-id)/info:policy-name)
    let $max :=  fn:data(infodev:effective-policy($policy-name,())/info:max-docs-per-transaction)

    let $transaction-size := $max 
    let $total-transactions := ceiling($total div $transaction-size)
    let $_log := xdmp:log(concat("Total transactions: ", $total-transactions))

    (: set total documents and total transactions so UI displays collecting :)
    let $set-total := infodev:ticket-set-total-documents($ticket-id, $total)
    let $set-trans := infodev:ticket-set-total-transactions($ticket-id, $total-transactions)
 
    (: create transactions by breaking document set into maps
       each maps's documents are saved to the db in their own transaction :)
    let $transactions :=
        for $i at $index in 1 to $total-transactions
        let $_log := xdmp:log(concat("Procesing transaction: ", $i))
        let $map := map:map()
        let $start :=  (($i -1) * $transaction-size) + 1
        let $finish := min((($start  - 1 + $transaction-size), $total))
        let $put :=
            for $track as element() in ($tracks)[$start to $finish]
            let $id := fn:concat(xdmp:md5($track),".xml")
            return map:put($map, $id, $track)
        return $map
let $_ := xdmp:log(info:ticket($ticket-id))

    (: the callback function for ingest :)
    let $function := xdmp:function(xs:QName("itunes:process-file"))
    let $ingestion :=
        for $transaction at $index in $transactions
        return
           try {
               infodev:transaction($transaction, $ticket-id, $function, $policy-deltas, $index, (), ())
           } catch($err) {
               (:xdmp:log(string-join(($ticket-id, concat("transaction ", $index)), ","), "error"),:)
               infodev:handle-error($ticket-id, concat("transaction ", $index), $err)
           }
    (:set ticket completed for UI:)
    let $_ := infodev:ticket-set-status($ticket-id, "completed")
    let $_log := xdmp:log("Successfully completed iTunes collection") 
    return ()
};

declare function itunes:process-file(
    $document as node(),
    $source-location as xs:string,
    $ticket-id as xs:string,
    $policy-deltas as element(info:options)?,
    $context as item()?
)
{
    infodev:ingest($document,$source-location,$ticket-id,$policy-deltas,())
};

(:~ A stand-alone page to configure the collector :)
declare function itunes:view($model as element(plugin:plugin-model)?, $lang as xs:string, $submit-here as xs:string)
as element(plugin:config-view)
{
    <config-view xmlns="http://marklogic.com/extension/plugin">
        <html xmlns="http://www.w3.org/1999/xhtml">
            <head>
                <title>iframe plugin configuration</title>
            </head>
            <body>
              <h2>iTunes Metadata Collector Configuration</h2>
              <form style="margin-top: 20px;" action="{$submit-here}" method="post">
                  <label for="uri">{ itunes:string("uri-label", $model, $lang) }</label>
                  <input type="text" name="uri" id="uri" style="width: 400px" value="{$model/plugin:data/*:uri}"/>
                  <p style="color: rgb(125,125,125); font-style: italic;">
                    The path to the iTunes metadata on the current machine ({xdmp:hostname()}). 
                  </p>
                  <div style="position: absolute; bottom: 2px; right: 0px;">
                      <ml:submit label="Done"/>
                  </div>
              </form>
            </body>
        </html>
    </config-view>
};

declare function itunes:cancel($ticket-id as xs:string)
as empty-sequence()
{
    infodev:ticket-set-status($ticket-id,"cancelled")
};

(:~ Validate a given model, return () if good, specific errors (with IDs) if problems :)
declare function itunes:validate(
    $model as element(plugin:plugin-model)
) as element(plugin:report)*
{
(:  
    if (string-length($model/plugin:data/uri) eq 0 )
    then <plugin:report id="uri">Specified feed URI must not be empty</plugin:report>
    else
        let $since-date := $model/plugin:data/sincedate/string()
        let $date-tokens := fn:tokenize(fn:normalize-space($since-date),"/")
        return if((fn:count($date-tokens) eq 3) or  fn:empty($date-tokens)) then
                 ()
               else
                 <plugin:report id="sincedate">Specified date is not the appropriate format (MM/DD/YYYY).</plugin:report>
:)
()
};

(:~ All labels needed for display are collected here. :)
declare function itunes:string($key as xs:string, $model as element(plugin:plugin-model)?, $lang as xs:string)
as xs:string?
{
    let $labels :=
    <lbl:labels xmlns:lbl="http://marklogic.com/xqutils/labels">
        <lbl:label key="name">
            <lbl:value xml:lang="en">iTunes Metadata Collector</lbl:value>
        </lbl:label>
        <lbl:label key="description">
             <lbl:value xml:lang="en">{
                if($model)
                then concat("Load from this library: ", $model/plugin:data/uri/string())
                else "Load tracks from an iTunes library"
             }</lbl:value>
        </lbl:label>
        <lbl:label key="start-label">
            <lbl:value xml:lang="en">Run</lbl:value>
        </lbl:label>
        <lbl:label key="dir-label">
            <lbl:value xml:lang="en">Feed URI</lbl:value>
        </lbl:label>
    </lbl:labels>
    return $labels/lbl:label[@key eq $key]/lbl:value[@xml:lang eq $lang]/string()

};


(:~ ----------------Main, for registration---------------- :)

plugin:register(itunes:capabilities(),"collector-boingboing.xqy")