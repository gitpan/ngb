#!/usr/local/bin/perl
#
# ngb-confirm.pl
# The "Confirmation" half of the Nizkor Guest Book
$version = "1.01";
# Requires perl 5;  tested only with perl5.001m.
#
# Written by Jamie McCarthy (jamie@nizkor.almanac.bc.ca)
# for the Nizkor Project (http://www.almanac.bc.ca/).
# Copyright 1995 Jamie McCarthy.
# Available from <ftp://ftp.almanac.bc.ca/pub/miscellany/ngb/>
#
# This source code may be publicly distributed by any means,
# as long as the above authorship, copyright, and availability
# notices are kept intact.  If you distribute a modified version,
# please explain what changes have been made.
#
# Changes in 1.01:
#
# Removed simple boolean check of $!, since $! returns boolean true on
#     some systems even when no error occurred.
# Guest book file and special guest book file are properly created now.
# Minor textual changes.
# Time zone correction variable.  You'd think someone would have put
#     this into a standard perl CGI library by now...


   # If you don't have cgi-lib.pl, check out
   # http://www.bio.cam.ac.uk/web/form.html
require "cgi-lib.pl";



###################################################################
###################################################################
#    CONSTANTS
###################################################################
###################################################################

###################################################################
# constants you can change if you want
###################################################################

   # This value is only valid if you're using UnixWare 2.0 (and,
   # obviously, if you're in Canada's Pacific time zone!).  This
   # format is more common:  "PST8PDT".  To find the appropriate
   # value for your site, 'echo $TZ' at your shell prompt.
$ENV{"TZ"} = ":Canada/Pacific";

   # If you'd prefer not to have horizontal rules between entries,
   # simply make this variable empty.  Or if you prefer double
   # rules, or blockquoted rules, or a special graphic that you
   # use for a rule, or whatever, just put its HTML tag here.
$entrySeparator = "<hr>";

   # Feel free to localize to your own language.
@monthFullName = (
   "January", "February", "March",     "April",   "May",      "June",
   "July",    "August",   "September", "October", "November", "December"
);


###################################################################
# constants you should leave alone
###################################################################

$todaysDate = $monthFullName[(localtime)[4]] . " "
   . (localtime)[3]
   . ", 19" . (localtime)[5];

   # I'd appreciate it if you left this as is.  Thanks.

$ngbCredits = <<END_OF_NGB_CREDITS;
<p><a href="http://www.almanac.bc.ca/guest-book.html">Nizkor guest book
$version</a>
END_OF_NGB_CREDITS

###################################################################
# constants you must modify for your web site
###################################################################

$upToLink = <<END_OF_UP_TO_LINK;
<p align=center>[ up to <a href="http://www.almanac.bc.ca/">Home Page</a> ]
END_OF_UP_TO_LINK

$addressInformation = <<END_OF_ADDRESS_INFORMATION;
<p><a href="http://www.almanac.bc.ca/">The Nizkor Project</a>
<br><a href="mailto:webmaster\@nizkor.almanac.bc.ca">webmaster\@nizkor.almanac.bc.ca</a>
<br>Director: <a href="http://www.almanac.bc.ca/contributors/mcvay-ken.html">Ken McVay OBC</a>
END_OF_ADDRESS_INFORMATION

   # This directory must be readable and writable by the scripts,
   # which means the user/guest that is running your http daemon
   # must have read/write permission to it.  Usually you'll want
   # to keep prying eyes out of this directory;  for information
   # on NCSA httpd's authentication, for example, see
   # http://hoohoo.ncsa.uiuc.edu/docs/setup/admin/UserManagement.html
$guestBookPrivateDir = "/web/debug/guest-book/";

   # This is the URL for that private directory.
$guestBookPrivateDirURL = "http://www.almanac.bc.ca/debug/guest-book/";

   # This is the filename of the special guest book, which always
   # goes in that private directory.
$specialGuestBookFilename = "guest-book-special.html";

   # Permissions for the special guest book.
$specialGuestBookPermissions = 0600;

   # This is the directory of the normal guest book.
$guestBookDir = "/web/";

   # This is the URL for the directory of the normal guest book.
$guestBookDirURL = "http://www.almanac.bc.ca/";

   # This is the filename of the guest book, which always goes in
   # that directory.
$guestBookFilename = "guest-book.html";

   # Permissions for the guest book.
$guestBookPermissions = 0644;

   # Your email contact address.
$emailContact = "webmaster\@nizkor.almanac.bc.ca";

   # The text of the guest book file.
$emptyGuestBookText = <<END_OF_EMPTY_GUEST_BOOK_TEXT;
<!doctype html public "-//IETF//DTD HTML//EN">
<html>
<head>
<title>Nizkor Guest Book</title>
<link rev="made" href="mailto:$emailContact">
</head>
<body>
<h2 align=center>Nizkor Guest Book</h2>
<p><hr>

<p>These are comments left by visitors to the Nizkor web site.
You are welcome to
<a href="http://www.almanac.bc.ca/cgi-bin/ngb-sign-in.pl">add
your own</a>.

<!-- insert new entries here and do not edit this line -->
<p><hr>
$upToLink
<address>
$addressInformation
<br>HTML: <a href="http://www.almanac.bc.ca/contributors/mccarthy-jamie.html">Jamie McCarthy</a>
<p>$todaysDate
$ngbCredits
</address>
</body>
</html>
END_OF_EMPTY_GUEST_BOOK_TEXT

   # The text of the special guest book file.
$emptySpecialGuestBookText = <<END_OF_EMPTY_SPECIAL_GUEST_BOOK_TEXT;
<!doctype html public "-//IETF//DTD HTML//EN">
<html>
<head>
<title>Nizkor Special Guest Book</title>
<link rev="made" href="mailto:webmaster\@nizkor.almanac.bc.ca">
</head>
<body>
<h2 align=center>Nizkor Special Guest Book</h2>
<p><hr>

<p>This is the "special" guest book, where we decide what to do with
entries that we don't want to go to the
<a href="http://www.almanac.bc.ca/guest-book.html">main guest book</a>.

<!-- insert new entries here and do not edit this line -->
<p><hr>
<p align=center>[ up to
<a href="http://www.almanac.bc.ca/">Nizkor Home Page</a> ]
<address>
<p><a href="http://www.almanac.bc.ca/">The Nizkor Project</a>
<br><a href="mailto:webmaster\@nizkor.almanac.bc.ca">webmaster\@nizkor.almanac.bc.ca</a>
<br>Director: <a href="http://www.almanac.bc.ca/contributors/mcvay-ken.html">Ken McVay OBC</a>
<br>HTML: <a href="http://www.almanac.bc.ca/contributors/mccarthy-jamie.html">Jamie McCarthy</a>
<p>
<!--#! daily begin datestamp -->
October 28, 1995
<!--#! daily end datestamp -->
</address>
</body>
</html>
END_OF_EMPTY_SPECIAL_GUEST_BOOK_TEXT

###################################################################
###################################################################
#    SUBROUTINES
#
# subroutines are:
#
# printHTMLTop - print the code for the top of the HTML page
# printHTMLBot - print the code for the bottom of the HTML page
#
# readEntries  - read in list of entries' filenames
# loadEntries  - read entry files and load associative arrays
# getBlurb     - given info about an entry, return an identifying comment
#
# printPotentialProblems - check for and print any potential problems
# createGuestBook        - create guest book file
# createSpecialGuestBook - create special guest book file
#
# printForm    - output HTML for form to choose what to do with entries
# processForm  - handle the choices made on that form
###################################################################
###################################################################

###################################################################
# printHTMLTop
#
# Print the code for the top of the HTML page.
#
# You're welcome to change this to suit yourself.
###################################################################

sub printHTMLTop
{
   print &PrintHeader(); # from cgi-lib.pl
   print <<END_OF_HTML_TOP;
<html>
<head>
<title>Guest Book Entry Confirmation</title>
</head>
<body>
<h2 align=center>Guest Book Entry Confirmation</h2>
<p><hr>
END_OF_HTML_TOP
}

###################################################################
# printHTMLBot
#
# Output the code for the bottom of the HTML page.
#
# You're welcome to change this to suit yourself.
###################################################################

sub printHTMLBot
{
   print <<END_OF_HTML_BOT;
<p><hr>
$upToLink
<address>
$addressInformation
<p>$todaysDate
$ngbCredits
</address>

</body>
</html>
END_OF_HTML_BOT
}

###################################################################
# readEntries
#
# Reads in the list of entries' filenames, from the
# $guestBookPrivateDir directory.  Stores that list in @entry.
###################################################################

sub readEntries
{
   local($entry);
   opendir(ENTRIES, "$guestBookPrivateDir");
   do {
      $entry = readdir(ENTRIES);
      unshift(@entry, $entry) if $entry =~ /^entry/;
   } while ($entry);
   closedir(ENTRIES);
}

###################################################################
# loadEntries
#
# Must be called after readEntries, since it uses the @entry list
# formed by readEntries.  Walks through each entry file and
# fills out associative arrays to reflect the data in those files.
#
# %timestamp is the array that holds the keys to the other arrays:
# %name, %email, %url, %ipaddress, %browserEmail, and %comments.
# In a %timestamp array member, the key is the timestamp, and the
# value is the entry filename.  For each of the other arrays, the
# key is the entry filename, and the value is the data for that
# entry.  So, to iterate through all the entries, one iterates
# through the keys of %timestamp, picks up the values, and uses
# each value as the key of the remaining arrays.  %timestamp was
# of course chosen because it's pretty much guaranteed that each
# timestamp will be unique.  (Not totally guaranteed, so yes this
# is technically a bug.  But nothing bad will happen if several
# entries should happen to have the same timestamp, and it's so
# rare I'm not going to worry about it.)
###################################################################

sub loadEntries
{
   local($entryFullText, $entry);
   LOADENTRY: foreach $entry (@entry) {
      
         # Do some (probably over-paranoid) sanity checking.
      
      if (!-s "$guestBookPrivateDir$entry") {
         print "<p><strong>Entry not found: $filename</strong>.\n";
         print "This is a bug; email\n";
         print "<a href=\"mailto:jamie\@nizkor.almanac.bc.ca\">Jamie</a>)\n\n";
         next LOADENTRY;
      }
      if (!open(ENTRY, "$guestBookPrivateDir$entry")) {
         print "<p><strong>Could not open $entry</strong>.\n";
         print "This is a bug; email\n";
         print "<a href=\"mailto:jamie\@nizkor.almanac.bc.ca\">Jamie</a>)\n\n";
         next LOADENTRY;
      }
      
         # Now read in the entry file and assign it to the
         # associative arrays.
      
      $entryFullText = "";
      while (<ENTRY>) {
         $entryFullText .= $_;
      }
      close(ENTRY);
      ($timestamp, $name{$entry}, $email{$entry}, $url{$entry},
         $ipaddress{$entry}, $browserEmail{$entry}, $comments{$entry})
         = split(/^/, $entryFullText, 7);
      chop($timestamp, $name{$entry}, $email{$entry}, $url{$entry},
         $ipaddress{$entry}, $browserEmail{$entry});
      $timestamp{$timestamp} = $entry;
      
   }
}

###################################################################
# getBlurb
#
# Given some information about a guest book entry -- specifically,
# the name, email, url, and comments -- generates a one-liner
# "blurb" that identifies that entry.
###################################################################

sub getBlurb
{
   local($blurb);
   local($name, $email, $url, $comments) = @_;
   if ($name) {
      $blurb = " (from " . $name . ")";
   } elsif ($email) {
      $blurb .= " (from " . $email. ")";
   } elsif ($url) {
      $blurb .= " (from " . $url. ")";
   } elsif ($comments) {
      local($line1);
      ($line1) = split(/^/, $comments);
      chop($line1);
      $line1 =~ s/<[^>]*>//g;
      if (length($line1) > 50) {
         $line1 = substr($line1, 0, 50);
         $line1 =~ s/\s+\S+$//;
      }
      $blurb .= " <i>(" . $line1. ")</i>";
   }
   return $blurb;
}

###################################################################
# printPotentialProblems
#
# Looks for potential problems with the script -- directories
# that don't exist or don't have the right permissions, files that
# don't have the right permissions, that kind of thing.  Prints
# HTML code describing any problems founds.  Returns false if
# everything looks okay to proceed, or true if serious problems
# were found.
###################################################################

sub printPotentialProblems
{
   local($fatalErrorFound, $printUserGroupNames);
   local($pidName, $gidName) = ((getpwuid($>))[0], (getgrgid($)))[0]);
   if (!-s "$guestBookDir" || !-d "$guestBookDir") {
      $fatalErrorFound = 1;
      print <<END_OF_GUEST_BOOK_DIR_NOT_EXIST;
<p>The specified guest book directory, <code>$guestBookDir</code>, does
not exist! Have you edited the constants in <code>ngb-confirm.pl</code>?
The variable <code>\$guestBookDir</code> is only one of many that must
be set properly.
END_OF_GUEST_BOOK_DIR_NOT_EXIST
   }
   if (!-s "$guestBookPrivateDir" || !-d "$guestBookPrivateDir") {
      $fatalErrorFound = 1;
      print <<END_OF_SPECIAL_GUEST_BOOK_DIR_NOT_EXIST;
<p>The specified special guest book directory,
<code>$guestBookPrivateDir</code>, does not exist! Have you edited the
constants in <code>ngb-confirm.pl</code>?  The variable
<code>\$guestBookPrivateDir</code> is only one of many that must be set
properly.
END_OF_SPECIAL_GUEST_BOOK_DIR_NOT_EXIST
   }
   if (-d "$guestBookDir" && !-s "$guestBookDir$guestBookFilename") {
      &createGuestBook();
      if (-s "$guestBookDir$guestBookFilename") {
         print <<END_OF_CREATED_GUEST_BOOK_FILE;
<p>The guest book file did not exist, so it was created. (This is
normal if and only if this is the first time you've executed this cgi
script. Reload this page and this message should not reappear.)
END_OF_CREATED_GUEST_BOOK_FILE
      } else {
         $fatalErrorFound = 1;
         $printUserGroupNames = 1;
         print <<END_OF_COULD_NOT_CREATE_GUEST_BOOK_FILE;
<p>The guest book file, <code>$guestBookDir$guestBookFilename</code>,
did not exist, and it could not be created. The error message reported
was &quot;$!&quot;. Just in case that isn't informative enough for you:
the most common error would be that this process user/group doesn't have
write permission for the file's parent directory, namely
<code>$guestBookDir</code>.
END_OF_COULD_NOT_CREATE_GUEST_BOOK_FILE
         if (!-w "$guestBookDir") {
            print "\nYep, that seems to be the problem.\n";
         }
      }
   }
   if (-d "$guestBookPrivateDir" && !-s "$guestBookPrivateDir$specialGuestBookFilename") {
      &createSpecialGuestBook();
      if (-s "$guestBookPrivateDir$specialGuestBookFilename") {
         print <<END_OF_CREATED_SPECIAL_GUEST_BOOK_FILE;
<p>The special guest book file did not exist, so it was created. (This
is normal if and only if this is the first time you've executed this cgi
script. Reload this page and this message should not reappear.)
END_OF_CREATED_SPECIAL_GUEST_BOOK_FILE
      } else {
         $fatalErrorFound = 1;
         $printUserGroupNames = 1;
         print <<END_OF_COULD_NOT_CREATE_SPECIAL_GUEST_BOOK_FILE;
<p>The special guest book file,
<code>$guestBookPrivateDir$specialGuestBookFilename</code>, did not
exist, and it could not be created. The error message reported was
&quot;$!&quot;. Just in case that isn't informative enough for you: the
most common error would be that this process user/group doesn't have
write permission for the file's parent directory, namely
<code>$guestBookPrivateDir</code>.
END_OF_COULD_NOT_CREATE_SPECIAL_GUEST_BOOK_FILE
         if (!-w "$guestBookPrivateDir") {
            print "\nYep, that seems to be the problem.\n";
         }
      }
   }
   if (-e "$guestBookDir$guestBookFilename"
   && !-w "$guestBookDir$guestBookFilename") {
      $fatalErrorFound = 1;
      $printUserGroupNames = 1;
      print <<END_OF_NO_WRITE_PERMS_GUEST_BOOK;
<p>This process user/group does not have write permission to the
specified guest book file, <code>$guestBookDir$guestBookFilename</code>.
END_OF_NO_WRITE_PERMS_GUEST_BOOK
   }
   if (-e "$guestBookPrivateDir$specialGuestBookFilename"
   && !-w "$guestBookPrivateDir$specialGuestBookFilename") {
      $fatalErrorFound = 1;
      $printUserGroupNames = 1;
      print <<END_OF_NO_WRITE_PERMS_SPECIAL_GUEST_BOOK;
<p>This process user/group does not have write permission to the
specified special guest book file,
<code>$guestBookPrivateDir$specialGuestBookFilename</code>.
END_OF_NO_WRITE_PERMS_SPECIAL_GUEST_BOOK
   }
   if ($printUserGroupNames) {
      print <<END_OF_USER_GROUP_NAMES;
<p>For your reference, this perl script is running under the effective
user name of &quot;$pidName&quot; and the effective group name of
&quot;$gidName&quot;.
END_OF_USER_GROUP_NAMES
   }
   return $fatalErrorFound;
}

###################################################################
# createGuestBook
#
# This subroutine is called when it's time to write to the guest
# book and there isn't a file there!  It simply creates the guest
# book file itself.
###################################################################

sub createGuestBook
{
   if (open(GUESTBOOK, ">$guestBookDir$guestBookFilename")) {
      print GUESTBOOK $emptyGuestBookText;
      close(GUESTBOOK);
      chmod $guestBookPermissions, "$guestBookDir$guestBookFilename";
   }
}

###################################################################
# createSpecialGuestBook
#
# This subroutine is called when it's time to write to the special
# guest book and there isn't a file there!  It simply creates the
# special guest book file itself.
###################################################################

sub createSpecialGuestBook
{
   if (open(SPECIALGUESTBOOK, ">$guestBookPrivateDir$specialGuestBookFilename")) {
      print SPECIALGUESTBOOK $emptySpecialGuestBookText;
      close(SPECIALGUESTBOOK);
      chmod $specialGuestBookPermissions,
         "$guestBookPrivateDir$specialGuestBookFilename";
   }
}

###################################################################
# printForm
#
# Print out the form for the webmaster to fill in. 
###################################################################

sub printForm
{
   local($entry, $nEntries, $entryFullText);
   local($timestamp);
   local($addCheckText, $deleteCheckText);
   
   $nEntries = @entry;
   
   print <<END_OF_GUIDE_PART_1;
<p>The quick usage guide:

<p>When you click the &quot;Submit Confirmations&quot; button,
you perform an action on each entry to the guest book.   That
action is determined by the radio button above that entry.
END_OF_GUIDE_PART_1
   if ($nEntries < 90) {
      print "<p>Usually, you'll want to Add an entry, so that is default.\n";
      $addCheckText = "checked";
      $deleteCheckText = "";
   } else {
      print "<p><strong>Note: Since there are over 90 entries, it's assumed\n";
      print "that a hacker has tried to flood the system.  <em>Delete</em>\n";
      print "is the default.</strong>\n";
      $addCheckText = "";
      $deleteCheckText = "checked";
   }
   print <<END_OF_GUIDE_PART_2;
<p>If you Add to Special, the entry will not appear in the
<a href="$guestBookDirURL$guestBookFilename">normal guest book</a>,
but rather in
<a href="$guestBookPrivateDirURL$specialGuestBookFilename">$guestBookPrivateDirURL$specialGuestBookFilename</a>.
The IP name or number, and the email address that the browser may or may
not report, will only be logged for entries in the special guest book. 
Such entries are typically not visible to the public.
<p>If you want to leave an entry alone for now and deal with it later,
choose Leave.  If you want to delete an entry outright, choose Delete.

END_OF_GUIDE_PART_2
   local($entrySingPl) = "entr" . ($nEntries == 1 ? "y" : "ies");
   print "<p>There ", ($nEntries == 1) ? "is" : "are", " $nEntries\n";
   print "$entrySingPl waiting to be added or deleted.\n\n";
   
   if (&printPotentialProblems()) {
      print <<END_OF_ERRORS_PRECLUDE_FORM;
<p>These errors preclude the possibility of this script working
properly, so the form to confirm the $entrySingPl will not even be
presented.  If you can't solve the problems on your own, you might try
emailing the author, Jamie McCarthy, at
<a href="mailto:jamie\@nizkor.almanac.bc.ca">jamie\@nizkor.almanac.bc.ca</a>.
END_OF_ERRORS_PRECLUDE_FORM
   } else {
      if ($nEntries > 0) {
         print "<p><form method=post>\n\n";
         
         &loadEntries();
         
         foreach $timestamp (sort keys %timestamp) {
            $entry = $timestamp{$timestamp};
            print <<END_OF_ENTRY;
<p><hr>

<p><input type=radio $addCheckText name=$entry value=add>Add
<input type=radio name=$entry value=addspecial>Add to Special
<input type=radio name=$entry value=leave>Leave
<input type=radio $deleteCheckText name=$entry value=delete>Delete
<p>Timestamp: $timestamp
<br>Name: $name{$entry}
<br>Submitted email: $email{$entry}
<br>URL: $url{$entry}
<br>IP: $ipaddress{$entry}
<br>Browser email: $browserEmail{$entry}

$comments{$entry}

END_OF_ENTRY
         }
         
         print <<END_OF_SUBMIT_BUTTONS;
<p><hr>

<p><input type=submit value="Submit Confirmations">
<input type=reset value="Reset Form">

END_OF_SUBMIT_BUTTONS
      }
   }
}

###################################################################
# processForm
#
# Process the form, handling each entry appropriately. 
###################################################################

sub processForm
{
   &loadEntries();
   #
   # Walk through the keys in the %timestamp array.  Since we
   # sort the keys before walking through them, we know we'll
   # be getting the entries in chronological order.
   #
   HANDLEENTRY: foreach $timestamp (sort keys %timestamp) {
      $entry = $timestamp{$timestamp};
      $filename = "$guestBookPrivateDir$entry";
      if (!open(ENTRY, $filename)) {
         print "<p><strong>Could not open: $filename</strong>\n";
         print "(this error shouldn't happen; email\n";
         print "<a href=\"mailto:jamie\@nizkor.almanac.bc.ca\">Jamie</a>)\n\n";
         next HANDLEENTRY;
      }
      if (!defined($in{$entry}) || !$in{$entry}) {
         print "<p>The entry\n";
         print "<a href=\"$guestBookPrivateDirURL$entry\">$entry</a>\n";
         print "is unaccounted for.  It was\n";
         print "probably just entered -- you might want to go back to the\n";
         print "confirmation page and reload.\n";
         next HANDLEENTRY;
      }
      #
      # The entry seems to be OK.  Let's handle it.
      #
      if ($in{$entry} eq "leave") {
         #
         # If "leave" was chosen, we don't do anything, and just print
         # a note saying that it was indeed left alone.
         #
         print "<p>Left alone \n";
         print "<a href=\"$guestBookPrivateDirURL$entry\">$entry</a>\n";
         print &getBlurb($name{$entry}, $email{$entry}, $url{$entry},
            $comments{$entry});
         print "\n\n";
      } elsif ($in{$entry} eq "delete") {
         #
         # If "delete" was chosen, we try to unlink the entry file
         # and, if successful, print a note to that effect.
         #
         if (!unlink($filename)) {
            print "<p><strong>Could not delete: $filename</strong>\n";
            print "(this error shouldn't happen; email\n";
            print "<a href=\"mailto:jamie\@nizkor.almanac.bc.ca\">Jamie</a>)\n\n";
            next HANDLEENTRY;
         }
         print "<p>Deleted $entry";
         print &getBlurb($name{$entry}, $email{$entry}, $url{$entry},
            $comments{$entry});
         print "\n\n";
      } elsif ($in{$entry} eq "add" || $in{$entry} eq "addspecial") {
         #
         # If "add" was chosen, things are tricky.  We have to add
         # the comments in a certain form, into the _middle_ of the
         # guest book file.
         #
         # We do this by copying the existing guest book, up to
         # and including a special trigger line, into a temporary
         # file.  Then we copy these comments into that file as
         # well.  Then we continue copying the rest of the old
         # guest book.  Then we replace the old guest book with
         # the temporary file.
         #
         # This could be done slightly more efficiently by
         # processing all guest-book entries in batch, but the
         # net savings would be small and the error-handling would
         # be trickier.
         #
         unlink("${guestBookPrivateDir}guest-temp.html");
         open(GUESTTEMP, ">${guestBookPrivateDir}guest-temp.html");
         select(GUESTTEMP);
         $success = 0;
         $tryingToCreate = 0;
         if ($in{$entry} eq "add") {
            if (!-s "$guestBookDir$guestBookFilename") {
               $tryingToCreate = 1;
               &createGuestBook();
            }
            $success = open(GUESTBOOK, "$guestBookDir$guestBookFilename");
         } else {
            if (!-s "$guestBookPrivateDir$specialGuestBookFilename") {
               $tryingToCreate = 1;
               &createSpecialGuestBook();
            }
            $success = open(GUESTBOOK,
               "$guestBookPrivateDir$specialGuestBookFilename");
         }
         #
         # Did we successfully open up the appropriate guest book?
         #
         if (!$success) {
            #
            # No -- output the reason why and continue handling entries.
            #
            select(STDOUT);
            close(GUESTTEMP);
            print "<p>The entry\n";
            print "<a href=\"$guestBookPrivateDirURL$entry\">$entry</a>\n";
            print "could not be added, because the guest book could not\n";
            print "be ";
            if ($tryingToCreate) {
               print "created. ";
            } else {
               print "opened. ";
            }
            print "The entry was left alone. The error reported was\n";
            print "&quot;$!.&quot;\n\n";
            next HANDLEENTRY;
         }
         #
         # Walk through the existing guest book, and when the special
         # line is found, insert this new entry.
         #
         while (<GUESTBOOK>) {
            tr#\015##d; # if guestbook file had CRs somehow inserted, trim them
            print $_;
            if (/<!-- insert new entries here and do not edit this line -->/) {
               #
               # There's that special line.  Insert the entry.
               #
               print "<p>$entrySeparator\n\n";
               #
               # Print the comments.
               #
               print "$comments{$entry}\n\n";
               #
               # Now print the cite.  This "firstLinePrinted" trickery is
               # so that the first line is preceded by a "<p>" and each
               # following line by a "<br>".
               #
               $firstLinePrinted = 0;
               print "<blockquote><cite>\n";
               if ($name{$entry}) {
                  print ($firstLinePrinted++ ? "<br>" : "<p>");
                  print "$name{$entry}\n";
               }
               if ($email{$entry}) {
                  print ($firstLinePrinted++ ? "<br>" : "<p>");
                  print "<a href=\"mailto:$email{$entry}\">";
                  print "$email{$entry}</a>\n";
               }
               if ($url{$entry}) {
                  print ($firstLinePrinted++ ? "<br>" : "<p>");
                  print "<a href=\"$url{$entry}\">$url{$entry}</a>\n";
               }
               if ($in{$entry} eq "addspecial") {
                  print ($firstLinePrinted++ ? "<br>" : "<p>");
                  print "$ipaddress{$entry}\n";
                  print "<br>$browserEmail{$entry}\n" if $browserEmail{$entry};
               }
               print ($firstLinePrinted++ ? "<br>" : "<p>");
               print "$todaysDate\n";
               print "</cite></blockquote>\n\n";
               #
               # After we insert the entry in the guest book, we continue
               # walking through the guest book, line by line, copying it
               # to the temp file.
               #
            }
         }
         close(GUESTBOOK);
         select(STDOUT);
         close(GUESTTEMP);
         #
         # Now rename that temp file to overwrite the guest book.
         #
         $success = 0;
         if ($in{$entry} eq "add") {
            $success = rename("${guestBookPrivateDir}guest-temp.html",
               "$guestBookDir$guestBookFilename");
            chmod $guestBookPermissions,
               "$guestBookDir$guestBookFilename" if $success;
         } else {
            $success = rename("${guestBookPrivateDir}guest-temp.html",
               "$guestBookPrivateDir$specialGuestBookFilename");
            chmod $specialGuestBookPermissions,
               "$guestBookPrivateDir$specialGuestBookFilename" if $success;
         }
         if (!$success) {
            #
            # This means that no further entries will be able to be
            # added to this guest book, since they won't be able
            # to overwrite it either.  This error needs to be taken
            # care of immediately, so processing is aborted to
            # indicate its seriousness.
            #
            print "<p><strong>Could not overwrite guest book</strong>.\n";
            print "Aborting entry processing.  The error reported was\n";
            print "&quot;$!.&quot;\n";
            print "I suggest returning to the confirmation form (with\n";
            print "your &quot;go back&quot; button) and seeing if there\n";
            print "aren't any warnings that you should take care of.\n\n";
            last HANDLEENTRY;
         }
         #
         # The entry was successfully added;  report that fact.
         #
         print "<p>Added $entry to\n";
         print "<a href=\"$guestBookDirURL$guestBookFilename\">guest book</a>"
            if ($in{$entry} eq "add");
         print "<a href=\"$guestBookPrivateDirURL$specialGuestBookFilename\">special guest book</a>"
            if ($in{$entry} eq "addspecial");
         print &getBlurb($name{$entry}, $email{$entry}, $url{$entry},
            $comments{$entry});
         #
         # Delete the entry file.
         #
         if (!unlink($filename)) {
            print "\n<p>But <strong>could not delete: $filename</strong>\n";
            print "(this error shouldn't happen; email\n";
            print "<a href=\"mailto:jamie\@nizkor.almanac.bc.ca\">Jamie</a>)";
         }
         print "\n\n";
      }
   }
}



###################################################################
###################################################################
# main program
#
# Decide whether to invoke printForm() or processForm().
###################################################################
###################################################################

&readEntries();

&printHTMLTop();
if (&ReadParse()) {
   &processForm();
} else {
   &printForm();
}
&printHTMLBot();
