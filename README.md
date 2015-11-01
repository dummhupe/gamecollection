gamecollection
===============
Display all games grouped by genre and provide means to start them.

Dependencies
===============
- Gtk2

Installation
===============
Copy ruby script to anywhere you like. Create a csv file that will contain all metadata with these columns:
<ol>
<li>Group title, e.g. genre</li>
<li>Title</li>
<li>Shell command</li>
</ol>

Check if you need to change defaults in selector.rb:
- Edit constant DB to set the path to csv file
