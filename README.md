# Fortune Screensaver
This is a screensaver which displays a quotation (with attribution) from a set in a similar manner to the old Unix fortune program.

By default the screensaver comes with a small set of Steven Wright quotes, but you can create your own quotes XML file and request the screensaver take quotes from that.

The background animations are Quartz Composer files with the text animated above.

## Supported OS X versions
This is designed to work with OS X Yosemite (10.10). Screensavers can be picky about compiler options, ARC-support etc. so it may not work on older OS X versions. It doesn’t use any Yosemite-specific APIs however, so please feel free to give it a shot.

## The Quotes XML file
This consists of a single element called “Quotes”, containing an arbitrary number of “Quote” elements. Each Quote contains a “Text” element and an “Attribution” element.

```xml
<?xml version=‘1.0’ encoding=‘utf-8’?>
<Quotes>
  <Quote>
    <Text>This is the text of the first quote.
Newlines will be preserved.</Text>
    <Attribution>This is the first quote author.</Attribution>
  </Quote>
  <Quote>
    <Text>This is the second quote</Text>
    <Attribution>The second quote author.</Attribution>
  </Quote>
</Quotes>
```
You then specify the XML file you have created in the preferences.

## Preferences
There are a few default styles available as well as a “Custom” option. If you select Custom, then you can specify the background as well as the font size and colour.

## Acknowledgements
The “Green Glitter” background is based on the *Dictionary* screensaver provided by Apple.
