The good folks at [Boing Boing](http://boingboing.net/) were kind enough to release all [11 years of their content](http://www.boingboing.net/2011/01/25/eleven-years-worth-o.html) for re-mixing, mashing-up, and analysis. You can get easily get started with the content (about 64,000 posts) in [MarkLogic Server](http://www.marklogic.com/products/marklogic-server.html) with MarkLogic Application Services. This project contains set-up for 

## Information Studio
Information Studio is an easy new way to load information into a MarkLogic database. It includes a web-based UI as well as high-level APIs to collect, transform, and load content. I’ve created a custom collector to load the unzipped post archive. To install the collector, copy (or soft link) the `Information Studio/collector-boingboing.xqy` file into `$MARKLOGIC_HOME/Plugins`, where `$MARKLOGIC_HOME` is where you installed MarkLogic Server. Restart the Server and you should see the “Boing Boing Collector” in your list of collectors in the Information Studio UI.

Next, grab [the archive](https://s3.amazonaws.com/bbpostdump/bbpostdump.xml.zip) and unzip it somewhere accessible to your MarkLogic Server instance.

## Application Builder
Application Builder allows you to build search applications without having to write any code. It’s great for prototyping new concepts or exploring content. 

More to come…

### License, Disclaimer, and Other Boring Legal Stuff
This is a demonstration to illustrate how to use MarkLogic Information Studio and MarkLogic Application Builder. It has not been thouroughly tested nor optimized as you’d expect in production-quality application. With that, however, you are free to explore it and repurpose it. All code is copyright MarkLogic and is distributed as-is under the [Apache 2.0 license](http://www.apache.org/licenses/LICENSE-2.0.html). 