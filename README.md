KanjiForAnki
============

This program takes a list of kanji and generates Anki flash cards for each them.

Objective
=========

This project is a script that takes a list of kanji as input and outputs a file that can be imported into Anki and used to study the given kanji.

Kanji are Japanese characters.  There are several thousand in existence.  Of those, roughly 2,000 are important for daily life in Japan.  English speakers learning Japanese often use SRS flash card systems to study.  One such program is Anki (<http://ankisrs.net/>).  People have created many different Anki decks for studying, but there are three drawbacks commonly encountered: the information is unreliable, the information is not freely licensed, or the information is not in the format you want.

Using this script, or rather, by modifying this script, you can customize flash card generation and produce cards you feel are particularly efficient for your studying needs.  The default settings are ones the author finds useful, so presumably you can use the script as-is, should you so desire.

Getting Dependencies
====================

This code is under the MIT License.  However, to make the script work, some more restrictive dependencies are needed.  Download the following files and put them in the same directory as this script.

The kanji dictionary and Japanese word dictionary are Creative Commons Attribution-Share Alike 3.0 licensed and can be downloaded here.

* <https://dperkins.org/2014/2014-01-24.kanjidic2.zip>
* <https://dperkins.org/2014/2014-01-24.edict.zip>

Or do this from the command line.

    wget https://dperkins.org/2014/2014-01-24.kanjidic2.zip
    unzip 2014-01-24.kanjidic2.zip
    wget https://dperkins.org/2014/2014-01-24.edict.zip
    unzip 2014-01-24.edict.zip


Running the Script
==================

Modify the file `targetkanji.txt` so that it contains all of the kanji you want to appear in your Anki deck.  The file should consist of entirely kanji with no other characters whatsoever.  If you're looking for kanji lists, see `Joyo Kanji.txt`, which contains lists for all the elementary and junior high school kanji.

To run the script, simply call `kanjiforanki.rb`.  Here's an example of generating cards for first grade elementary school level kanji.

    $ ./kanjiforanki.rb 
    Parsing edict.txt ...
    Parsing wordfreq_ck.txt ...
    Parsing kanjidic2.xml ...
    Characters in kanjidic2: 13108.
    Parsing targetkanji.txt ...
    Target kanji count: 80.
    Target characters: 一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六.
    Looking up kanji ...
    Found 80 kanji in kanjidic.
    Making the deck ...
    Writing the deck to anki.txt...
    Done writing.


Creating the note type
======================

Before importing the deck into Anki, it may be necessary to tell Anki what information it should be looking for during the import.  This is a little technical, but nothing tricky is going on, so have no fear.

1. Click on `Tools / Manage Note Types...`/
2. Create a new note type and call it "Kanji".  This can be done using `Add` followed by `Rename`.
3. Click on `Fields` and create the following fields in the following order.
	* Radical
	* Strokes
	* Grade
	* Meaning
	* Meanings
	* Onyomis
	* Kunyomis
	* Examples
4. That's all.  You now have a note type with eight fields: one for each piece of information that shows up on a kanji flash card.


Importing the deck into Anki
============================

Once you have a deck you need to import it.

1. Open up Anki.  Go to `File / Import ...`  A dialog opens.
2. Select the text file you generated above.
3. Choose whatever options you like.  I prefer to create a separate deck for just these cards.
4. Make sure `Allow HTML in fields` is checked.
5. Make sure `Fields separated by: Tab` is displayed.
6. Click `Import`.  A dialog should open telling you everything worked.

To make the deck visually appealing, we need to modify the styling of it.


Styling the deck
================

1. Browse to the deck.
2. Select a card from it.
3. Click on `Cards...`.  A style editing window opens.
4. We need to enter new styling information in the `Styling` box on the left side.  Some styling information is already specified.  Copy the contents of `style.css` below anything that's already there.
5. By default, only two of the eight information fields are displayed.  We need to enable the other six....
6. In `Front Template`, enter the following.
````HTML
<span class="literal">{{Literal}}</span>
<span class="strokes">{{Strokes}}</span>
<span class="grade">{{Grade}}</span>
````
7. In `Styling`, enter the following.
````CSS
.card { font-family: arial; font-size: 30px; text-align: center; color: black; background-color: white; }
.literal { color: blue; font-size: 200%; }
.strokes { float: left; font-size: 75%; color: #ff66ff; }
.grade { float: right; font-size: 75%; color: gray; }
.meaning { color: green; }
.meanings { color: #6699cc; }
.onyomis { color: orange; font-size: 75%; }
.kunyomis { color: red; font-size: 75%; }
.examples { font-size: 75%; }
````
8. In `Back Template`, enter the following.
````HTML
{{FrontSide}}

<hr id=answer>

<div class="meaning">{{Meaning}}</div>
<div class="meanings">{{Meanings}}</div>
<div class="onyomis">{{Onyomis}}</div>
<div class="kunyomis">{{Kunyomis}}</div>
<div class="examples">{{Examples}}</div>
````
You are ready to go.  Have fun studying!


Issues
======

If you see any issues, obvious but missing features, or problems with the documentation, feel free to open an issue at <https://github.com/dper/KanjiForAnki/issues> or contact the author at <https://microca.st/dper>.


Sources
=======

The source code here is a modification of some code I wrote in 2011 to make paper flash cards for elementary school kanji.  Back then I didn't have a smart phone with SRS, and regardless, paper flash cards have their own strengths and weaknesses. <https://dperkins.org/arc/2011-03-22.kanji%20flashcards.html>

The kanji lists themselves are published by the Ministry of Education (MEXT) in Japan.  Other websites copy and paste the data from official MEXT documents.

* <http://www.mext.go.jp/a_menu/shotou/new-cs/youryou/syo/koku/001.htm>.  Elementary school kanji.
* <http://www.imabi.net/joyokanjilist.htm>.  Elementary and junior high school kanji.

The word frequency list is public domain and is included with the source.

* <http://ftp.monash.edu.au/pub/nihongo/00INDEX.html>.
* <http://www.bcit-broadcast.com/monash/wordfreq.README>.
* <http://ftp.monash.edu.au/pub/nihongo/wordfreq_ck.gz>.  Retrieved 2014-01-24.

The kanji dictionary and Japanese word dictionary are available from their original sources.  The original sources aren't in Unicode, but you can and should check there for updates and make the conversions yourself using a web browser and some copy and pasting.

* <http://www.csse.monash.edu.au/~jwb/kanjidic2/>.
* <http://www.csse.monash.edu.au/~jwb/kanjidic2/kanjidic2.xml.gz>.
* <http://www.csse.monash.edu.au/~jwb/edict.html>.
* <http://ftp.monash.edu.au/pub/nihongo/edict.gz>.
