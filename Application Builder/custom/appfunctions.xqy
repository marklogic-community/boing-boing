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
module namespace app = "custom-app-settings";

import module namespace asc="http://marklogic.com/appservices/component" at "/lib/standard.xqy";

import module namespace config="http://marklogic.com/appservices/config" at "/lib/config.xqy";

import module namespace search = "http://marklogic.com/appservices/search" 
    at "/MarkLogic/appservices/search/search.xqy";
import module namespace trans = "http://marklogic.com/translate" 
    at "/MarkLogic/appservices/utils/translate.xqy";
import module namespace render="http://marklogic.com/renderapi" 
    at "/MarkLogic/appservices/utils/renderapi.xqy";
import module namespace boot="http://marklogic.com/appservices/bootstrap" 
    at "/MarkLogic/appservices/appbuilder/bootstrap.xqy";

import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace proj ="http://marklogic.com/appservices/project";
declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare default element namespace "http://www.w3.org/1999/xhtml";
declare namespace label = "http://marklogic.com/xqutils/labels";
declare namespace slots = "http://marklogic.com/appservices/slots";

declare option xdmp:mapping "false";

(: -------------------------------------------:)
(: These variables can be used to override or extend values :)
(: from /lib/config.xqy :)

declare variable $FACET-LIMIT := ();
declare variable $INTRO-OPTIONS := ();
declare variable $LABELS := ();
declare variable $OPTIONS := ();
declare variable $ADDITIONAL-OPTIONS := ();
declare variable $ADDITIONAL-INTRO-OPTIONS := $ADDITIONAL-OPTIONS;
declare variable $ADDITIONAL-CSS := (
   <link xmlns='http://www.w3.org/1999/xhtml'
         rel='stylesheet' type='text/css' href='/custom/appcss.css'/>
   );
declare variable $ADDITIONAL-JS := (
   <script xmlns='http://www.w3.org/1999/xhtml'
           src='/custom/appjs.js' type='text/javascript'><!-- --></script>
   );

declare function app:results()
as element(div)
{
    <div id="resultlist">
    <div class="incident-histogram">
    {
let $query as cts:query := cts:query($config:RESPONSE/search:query/*)
let $buckets as xs:dateTime+ := for $d in (0 to 11*12) return xs:dateTime(functx:add-months(xs:dateTime("2000-01-01T00:00:00"), $d))
(: Get the maximum value so the bars scale correctly :)
let $MAX := cts:frequency(cts:element-value-ranges(
	fn:QName("", "created_on"), 
	$buckets, 
	("frequency-order", "limit=1"),
	$query
))
return
	(<p class="max">Out of {fn:format-number($MAX, "#,###")}</p>,
	(: Loop through the actual buckets :)
	for $r at $i in
	cts:element-value-ranges(
		fn:QName("", "created_on"), 
		$buckets, 
		"empties",
		$query
	)
	let $HT := 80
	let $f := cts:frequency($r)
	let $h := floor(xs:float($f) div xs:float($MAX) * $HT)
	return <a href="/search?q=created+GT+{data($r/cts:lower-bound)}+created+LT+{data($r/cts:upper-bound)}" title="{$i}: {$r/cts:lower-bound}: {$f}" 
		class="bar" style="height: {$h}px; margin-top: {$HT - $h}px;">{$h}: {$f}</a>)
    }
    </div>
    {
        for $result in $config:RESPONSE/search:result
        return xdmp:apply($config:transform-result, $result)
    }
    </div>
};

(:~
 : Main front page content (browse links)
 :)
declare function app:browse()
as element(div)
{
  <div class="front-page-content">
  	<div style="padding: 1em; line-height: 1.55;">
  	<p>The good folks at <a href="http://boingboing.net/">Boing Boing</a> were kind enough to release all 
        <a href="http://www.boingboing.net/2011/01/25/eleven-years-worth-o.html">11 years of their content</a> for re-mixing, mashing-up, 
        and analysis. This application uses MarkLogic Server to expose the 64,000 posts in an intuitive search interface. Here are some interesting 
        searches to get you started: </p> 
        <ul style="padding-left: 2.5em;">
        	<li style="list-style: disc; line-height: 1.55;"><a href="/search?q=steampunk">The growth of steampunk references over the years</a></li>
        	<li style="list-style: disc; line-height: 1.55;"><a href="/search?q=%22september%2011%22%20OR%20%22ground%20zero%22%20OR%20%22world%20trade%20center%22%20OR%20WTC%20sort%3Adate">September 11 mentioned early and often</a></li>
        	<li style="list-style: disc; line-height: 1.55;"><a hre="/detail%2Fcontent%2F540f0a9e54622e6ed78dd3533f53ae0a.xml?q=%28internet%20meme%29%20AND%20category%3AVideo">Hitler planning Burning Man in the convergence of internet meme and popular culture</a></li>
        </ul>
   </div>
   {let $front-page := $config:OPTIONS/search:constraint[search:annotation/xs:boolean(proj:front-page) eq true()]/@name
    return xdmp:apply($config:browse-facets, $config:RESPONSE/search:facet[@name = $front-page], ())}
   {xdmp:apply( $config:bootstrap )}
   </div>
};


(:~
 : Content for contact page on application.
 :)
declare function app:contact()
as element(div)
{
    <div class="static contact">
        <h2>Contact Us</h2>
        <p>This application was developed as a demonstration of MarkLogic Server by Justin Makeig. Justin is in no way affiliated with the (superb) <a href="http://www.boingboing.net">Boing Boing blog</a>. 
        For questions or comments, please contact Justin directly (<a href="mailto:jmakeig@marklogic.com">jmakeig@marklogic.com</a>). For more information about MarkLogic Server or how you can build a similar application on your content, please visit the <a href="http://www.marklogic.com/products/marklogic-server.html?referrer=boing-boing.demo.marklogic.com">MarkLogic Server homepage</a>.</p>
    </div>
};


(:~
 : Content for help page on application.
 :)
declare function app:help()
as element(div)
{
    <div class="static help">
        <h2>Help</h2>
        <p>The good folks at <a href="http://boingboing.net/">Boing Boing</a> were kind enough to release all 
        <a href="http://www.boingboing.net/2011/01/25/eleven-years-worth-o.html">11 years of their content</a> for re-mixing, mashing-up, 
        and analysis. This application uses MarkLogic Server to expose the 64,000 posts in an intuitive search interface. Here are some interesting 
        searches to get you started: </p> 
        <ul>
        	<li><a href="/search?q=steampunk">The growth of steampunk references over the years</a></li>
        	<li><a href="/search?q=%22september%2011%22%20OR%20%22ground%20zero%22%20OR%20%22world%20trade%20center%22%20OR%20WTC%20sort%3Adate">September 11 mentioned early and often</a></li>
        	<li><a hre="/detail%2Fcontent%2F540f0a9e54622e6ed78dd3533f53ae0a.xml?q=%28internet%20meme%29%20AND%20category%3AVideo">Hitler planning Burning Man in the convergence of internet meme and popular culture</a></li>
        </ul>
    </div>
};

(:~
 : Content for terms page on application.
 :)
declare function app:terms()
as element(div)
{
	<div class="static terms">
		<h2>Terms of Use</h2>
    <p>The content is used under the terms of <a href="http://creativecommons.org/licenses/by-nc-sa/2.0/">Creative Commons Non-Commercial, Share-Alike license</a>.</p> 
    <p>The application is a demonstration to illustrate how to use MarkLogic Information Studio and MarkLogic Application Builder. 
    It has not been thouroughly tested nor optimized as you’d expect in production-quality application. With that, however, you are free to <a href="https://github.com/marklogic/boing-boing">explore it and repurpose it</a>. 
    The code is copyright MarkLogic Corporation and <a href="https://github.com/marklogic/boing-boing">distributed</a> without warranty under the <a href="http://www.apache.org/licenses/LICENSE-2.0.html">Apache 2.0 license</a>. 
    </p>
    <h3>Downloads</h3>
    <ul>
    	<li><a href="https://s3.amazonaws.com/bbpostdump/bbpostdump.xml.zip">Raw XML content</a></li>
    	<li><a href="https://github.com/marklogic/boing-boing">Code repository on Github</a></li>
    </ul>
	</div>
};

(:~
 : Personalized welcome message.
 :)
declare function app:user() as element(div)?
{
    ()
};

