#!/usr/local/bin/perl
#
# ngb-sign-in.pl
# The "Sign In" half of the Nizkor Guest Book
$version = "1.01";
# Requires perl 5;  tested only with perl5.001m.
#
# Written by Jamie McCarthy (jamie@nizkor.almanac.bc.ca)
# for the Nizkor Project (http://www.almanac.bc.ca/).
# Copyright 1995-96 Jamie McCarthy.
#
# This source code may be publicly distributed by any means,
# as long as the above authorship and copyright notice is kept
# intact.  If a modified version is distributed, please explain
# what changes have been made.
#
# With so many guest books out there, why did I write my own?
# (1) Most of the existing guest books are messy and ugly;
# (2) I found none that required confirmation to submit entries,
#     so they were all quite susceptible to hacker mischief.
#
# Changes to 1.01:
#
# Some textual changes, mainly putting the name/email/homepage entry
#     boxes first to keep people from putting that info into the
#     main textarea.
# Also check REMOTE_USER environment variable to try to get an email
#     address.
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
# constants you must modify for your web site
###################################################################

   # This value is only valid if you're using UnixWare 2.0 (and,
   # obviously, if you're in Canada's Pacific time zone!).  This
   # format is more common:  "PST8PDT".  To find the appropriate
   # value for your site, 'echo $TZ' at your shell prompt.
$ENV{"TZ"} = ":Canada/Pacific";

$upToLink = <<END_OF_UP_TO_LINK;
<p align=center>[ up to <a href="http://www.almanac.bc.ca/">Home Page</a> ]
END_OF_UP_TO_LINK

$addressInformation = <<END_OF_ADDRESS_INFO;
<p><a href="http://www.almanac.bc.ca/">The Nizkor Project</a>
<br><a href="mailto:webmaster\@nizkor.almanac.bc.ca">webmaster\@nizkor.almanac.bc.ca</a>
<br>Director: <a href="http://www.almanac.bc.ca/contributors/mcvay-ken.html">Ken McVay OBC</a>
END_OF_ADDRESS_INFO

   # This directory must be readable and writable by the scripts,
   # which means the user/guest that is running your http daemon
   # must have read/write permission to it.  Usually you'll want
   # to keep prying eyes out of this directory;  for information
   # on NCSA httpd's authentication, for example, see
   # http://hoohoo.ncsa.uiuc.edu/docs/setup/admin/UserManagement.html
$guestBookPrivateDir = "/web/debug/guest-book/";

   # This is the URL for the directory of the normal guest book.
$guestBookDirURL = "http://www.almanac.bc.ca/";

   # This is the filename of the guest book, which always goes in
   # that directory.
$guestBookFilename = "guest-book.html";

   # Will you allow anonymous submissions?  If not, set to zero.
$allowAnonymous = 1;

   # If you don't allow anonymous submissions, here's what gets
   # told to would-be anonymous submitters.
$anonymousNotAllowed = <<END_OF_ANONYMOUS_NOT_ALLOWED;
<p>Sorry, anonymous submissions are not allowed.
END_OF_ANONYMOUS_NOT_ALLOWED

   # Your email contact address.
$emailContact = "webmaster\@nizkor.almanac.bc.ca";

   # Feel free to edit this, if desired.
$formIntro = <<END_OF_FORM_INTRO;
<p>Please leave your comments in the space below.  They will typically
appear in the
<a href="$guestBookDirURL$guestBookFilename">guest book</a>
within 48 hours.

<p>Polite comments and/or constructive criticism are welcome from
anyone. One submission per customer, please, and no advertising.  If you
have particular questions that you'd like an answer to, please email us
at
<a href="mailto:$emailContact">$emailContact</a>.

<p><strong>Double-space to separate your paragraphs.</strong> Or, if you
know HTML, you can do the formatting yourself with HTML tags. Note that
all tags except &lt;a&gt; and &lt;p&gt;will be stripped.  If you use
any tags at all -- i.e. if you use &quot;&lt;&quot; or &quot;&gt;&quot;
anywhere -- everything will be treated as HTML code.

END_OF_FORM_INTRO

   # Feel free to edit this, if desired.
$technicalDifficulties = <<END_OF_TECHNICAL_DIFFICULTIES;
<p>Sorry, but we're experiencing technical difficulties at the moment
and are unable to accept submissions.  If this situation persists, you
may want to contact the webmaster of this site and remind him or her to
configure the guest book properly.

END_OF_TECHNICAL_DIFFICULTIES

###################################################################
# constants you can change if you want
###################################################################

@monthFullName = (
   "January", "February", "March",     "April",   "May",      "June",
   "July",    "August",   "September", "October", "November", "December"
);

$anonymousComment = $allowAnonymous
   ? "Or leave all three blank if you prefer to remain anonymous."
   : "Anonymous submissions will not be accepted.";

$formMain = <<END_OF_FORM_MAIN;
<form method=post>

<p>First, please leave us your name, email address if any, and home page
URL if any.  $anonymousComment

<table>
<tr><td align=right>
<p>Name: <td><input type=text name="name" size=30 maxlength=99>
<tr><td align=right>
<p>Email: <td><input type=text name="email" size=30 maxlength=99>
<tr><td align=right>
<p>Home Page URL: <td><input type=text name="url" size=50 maxlength=199>
</table>

<p>The date will be added automatically.
<p>Enter your comments here.

<p><textarea name="comments" rows=10 cols=64></textarea>

<p><input type=submit value="Submit Comments">
<input type=reset value="Reset Form">
END_OF_FORM_MAIN

$guestBookFull = <<END_OF_GUEST_BOOK_FULL;
<p>Sorry, but the guest book is currently full.
Please try again tomorrow.
END_OF_GUEST_BOOK_FULL

$myURL = &MyURL();
$errorNoComments = <<END_OF_ERROR_NO_COMMENTS;
<p>An empty comment field was submitted.  Perhaps you'd like to <a href="$myURL">try again</a>.
END_OF_ERROR_NO_COMMENTS
undef($myURL);

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
###################################################################
#    SUBROUTINES
#
# subroutines are:
#
# printHTMLTop - print the code for the top of the HTML page
# printHTMLBot - print the code for the bottom of the HTML page
#
# stripMultiline   - strip multiline input (i.e. comments)
# stripSingleline  - strip single-line input (e.g. name)
#
# emailIsAnonymous - tries to determine if an email address is anon
#
# printForm    - output HTML for input of comments
# processForm  - handle those comments (write them to a file)
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
<title>Guest Book Sign-In</title>
</head>
<body>
<h2 align=center>Guest Book Sign-In</h2>
<!-- want the perl5 source code?
     visit http://www.almanac.bc.ca/guest-book.html -->
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
# stripMultiline
#
# Given multiline input (i.e. the comment textarea), make it all
# nice and neat:  no unwanted tags, no messiness, and automatically
# add <p> tags where it's double-spaced.
###################################################################

sub stripMultiline
{
   local ($_) = @_;
   
      # limit incoming text to 16K -- no comment should be that long!
   if (length($_) > 16384) {
      $_ = substr($_, 0, 16384);
   }
   
                           # convert non-printable chars to " "
   tr#\000-\011\013-\014\015-\037# #;
   s#\r\n#\n#gm;           # some browsers send CRLF to separate lines;
   s#\n\r#\n#gm;           # convert that to a single newline
   
   if (!m#[<>]#) {         # if no HTML code,
      s#\n{2,}\s*#<p>#gm;  # convert blank lines to <p>
      s#\n\s+#<p>#gm;      # convert indented lines to <p>
   }
   s#<>##gm;               # remove any empty tags: "<>"
   s# +$##gm;              # remove any trailing whitespace
                           # strip the <> from <URL:xxx://xyz>
   s#<((URL.{1,3})?(http|ftp|gopher|telnet)://[^>\r\n]+)>#$1#gm;
   s#<[^ap/][^>]*>##gmi;   # remove all non-/ tags except <a...> and <p...>
   s#</[^a][^>]*>##gmi;    # remove all / tags except </a>
   s#<p[^>]*>#<p>#gmi;     # convert all <p xxx> tags into plain <p>
   s#\s+# #gm;             # convert all whitespace sequences to " "
   s#<p>\s*(?=<p>)##gmi;   # remove all empty paragraphs
   s#\s*<p>#\n\n<p>#gmi;   # put a double-space in front of <p> tags
   s#\A\n\n<p>#<p>#gm;     # except the first one
   s#<p>\s+#<p>#gm;        # remove paragraphs' initial whitespace
   if (!m#\A<p>#m) {       # if no initial <p>,
      $_ = "<p>" . $_;     # add one
   }
   
                           # make URLs clickable if they aren't already
   s#([^>"]|\A)
    ((http|ftp|gopher|telnet)://[\-\w/.:+~\#%?]+)
    ([^<"]|\Z)
    #
    $1<a href="$2">$2</a>$4
    #gmx;
   
   return $_;
}

###################################################################
# stripSingleline
#
# Given single-line input (i.e. the name), just do some basic
###################################################################

sub stripSingleline
{
   local ($_) = @_;
   
   tr#\000-\037# #s;       # convert non-printable chars to " "
   s#\s+# #gm;             # convert text to a single line
   s#^\s+# #g;             # with no leading whitespace
   s#\s+$# #g;             # and no trailing whitespace
   tr#<>##d;               # remove any < or > characters
   
   return $_;
}

###################################################################
# emailIsAnonymous
#
# Tries to guess whether an email address is anonymous.  (If it's
# empty, it's an easy guess.  :-)
###################################################################

sub emailIsAnonymous
{
   return (!$email || $email =~ /anon\.penet\.fi/);
}

###################################################################
# printForm
#
# Print out the form for the user to "sign."
###################################################################

sub printForm
{
   opendir(ENTRYDIR, $guestBookPrivateDir);
   $nEntries = 0;
   grep(++$nEntries, readdir(ENTRYDIR));
   closedir(ENTRYDIR);
   
   if ($nEntries > 100) {
      
      print $guestBookFull;
      
   } else {
      
      if (-d $guestBookPrivateDir && -w $guestBookPrivateDir) {
         print $formIntro;
         print $formMain;
      } else {
         print $technicalDifficulties;
      }
      
   }
}

###################################################################
# processForm
#
# Process the form, writing the file for the entry. 
###################################################################

sub processForm
{
   $comments = &stripMultiline($in{'comments'});
   
   opendir(ENTRYDIR, $guestBookPrivateDir);
   $nEntries = 0;
   grep(++$nEntries, readdir(ENTRYDIR));
   closedir(ENTRYDIR);
   
   if ($nEntries > 100) {
      
      print $guestBookFull;
      
   } elsif (!$comments) {
      
      print $errorNoComments;
      
   } else {
      
      $name = &stripSingleline($in{'name'});
      $email = &stripSingleline($in{'email'}); # note, this must be global
      $url = &stripSingleline($in{'url'});
      $ip = $ENV{'REMOTE_HOST'};
      $ip = $ENV{'REMOTE_ADDR'} if !$ip;
      $ip = &stripSingleline($ip);
         # see http://www.best.com/~hedlund/cgi-faq/faq-environment.html
      $browserEmail = $ENV{'HTTP_FROM'};
      if (!$browserEmail && $ENV{'REMOTE_USER'}) {
         $browserEmail = $ENV{'REMOTE_USER'} . "\@$ip";
         $browserEmail .= " (from REMOTE_ADDR, IP may be invalid)" if !$ENV{'REMOTE_HOST'};
      }
      $browserEmail = &stripSingleline($browserEmail) if $browserEmail;
      if ($url !~ m#^http://#) {
         if ($url =~ m#^www\.#) {
            if ($url !~ m#/#) {
               $url .= "/";
            }
            $url = "http://" . $url;
         } elsif ($url =~ m#^ftp\.#) {
            $url = "ftp://" . $url;
         }
      }
      
      local($filename, $id, @localtime, $i);
      $filename = "${guestBookPrivateDir}entry";
      $id = $$;
      while (-e "$filename$id") {
         ++$id;
      }
      local($isAnonymous, $anonymously);
      $isAnonymous = ($name !~ /.{3,}/ && &emailIsAnonymous());
      if ($isAnonymous && !$allowAnonymous) {
         
         print $anonymousNotAllowed;
         
      } else {
        
         if (!open(ENTRY, ">$filename$id")) {
         print <<END_OF_ERROR_NO_ENTRY_FILE;
<p>Sorry, but there was an error in writing the entry file:
&quot;$!.&quot;  Please report this to
<a href="mailto:$emailContact">$emailContact</a>.
END_OF_ERROR_NO_ENTRY_FILE
         
         } else {
            
            @localtime = localtime();
            for ($i=5; $i>=0; --$i) {
               print ENTRY "0" if $localtime[$i] < 10;
                  # output e.g. 950926133350 for 95/10/26 1:33:50 PM
               print ENTRY "$localtime[$i]";
            }
            print ENTRY "\n$name\n$email\n$url\n$ip\n$browserEmail\n$comments";
            close(ENTRY);
            
            $anonymously = $isAnonymous ? "anonymously" : "";
            
            print <<END_OF_SUCCESSFUL_SUBMISSION;
<p>Your comments have been $anonymously submitted.  Thank you.  They
should appear in the
<a href="$guestBookDirURL$guestBookFilename">guest book</a>
within 48 hours.
END_OF_SUCCESSFUL_SUBMISSION
            
         }
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

&printHTMLTop();
if (&ReadParse()) {
   &processForm();
} else {
   &printForm();
}
&printHTMLBot();
