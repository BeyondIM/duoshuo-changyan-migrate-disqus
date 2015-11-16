# About
A ruby script to migrate from [duoshuo](http://duoshuo.com/) or [changyan](http://changyan.kuaizhan.com/) to [disqus](https://disqus.com/).

# Usage

``` bash
$ ruby migrate.rb -h
Usage: migrate.rb [options]
        -f, --from json_file             Specify json file to convert from
        -t, --to xml_file                Specify xml file to convert to
        -h, --help                       Display help

ruby migrate.rb -f export.json -t import.xml
```
