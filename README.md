Glory Holes Engine
==================

Glory holes CPC demo released at ReSeT &8 in the 4K compo.
The repository contains only the displaying routine code, there
is no music data, no player source.

Feel free to improve and share the routine (there are tons of possible improvements) or to
create new patterns.

http://pouet.net/prod.php?which=59393


Credits
-------

 Before the party:
 - main code: Krusty/Benediction
 - player: Grim/Semilanceata

 During the party:
 - Music: Tom&Jerry/GPA
 - Batman: Grim/Semilanceata
 - Nebulus: Grim/Semilanceata
 - Self-portrait: Beb/Vanity
 - Quadripus: Ced/Condense (complete version available in the sources)

 After the party
 - Dancing in the moonlight: Voxfreax/Benediction

Notes
-----
A part of the source is included.
Feel free to modify it and assemble under winape in order
to test and share your own pictures.

`...` label is a pointer on the list of pictures.
Each picture is as this:
 - First line is `COLORS A, B, C, D` in order to select 
   the 4 first inks as being colors A, B, C and D.
 - Following lines are `CIRCLE X_pos, Y_pos, Radius, Ink` with CPC coordinates,
   or `PSD X_pos, Y_pos, Radius, Ink` with photoshop coordinates
 - Last line is `dw 0`
