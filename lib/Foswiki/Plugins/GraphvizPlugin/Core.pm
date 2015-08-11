# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# GraphvizPlugin is Copyright (C) 2015 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

package Foswiki::Plugins::GraphvizPlugin::Core;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Sandbox ();
use File::Temp();
use File::Path();
use Digest::MD5 ();
use Encode ();

use constant TRACE => 0; # toggle me

sub writeDebug {
  #Foswiki::Func::writeDebug("GraphvizPlugin::Core - $_[0]") if TRACE;
  print STDERR "GraphvizPlugin::Core - $_[0]\n" if TRACE;
}

sub new {
  my $class = shift;

  my $this = bless({
    dotCmd => $Foswiki::cfg{GraphvizPlugin}{DotCmd} || '/usr/bin/dot -K%RENDERER|S% -T%TYPE|S% -o%OUTFILE|F% %INFILE|F%',
    imageFormat => $Foswiki::cfg{GraphvizPlugin}{ImageFormat} || '<noautolink><img src=\'$url\' class=\'graphviz\' $style$width$height/></noautolink>',
    svgFormat => $Foswiki::cfg{GraphvizPlugin}{ImageFormat} || '<noautolink><literal>$svg</literal></noautolink>',
    @_
  }, $class);

  return $this;
}

sub GRAPHVIZ {
  my ($this, $session, $params, $topic, $web) = @_;

  writeDebug("called GRAPHVIZ()");

  my $query = Foswiki::Func::getRequestObject();
  my $refresh = $query->param("refresh") || '';
  my ($theWeb, $theTopic) = Foswiki::Func::normalizeWebTopicName($web, $params->{topic} || $topic);

  # extract graph code
  my $text = "";
  my $attachment = $params->{attachment};
  my $section = $params->{section};
  my $nodeTable = $params->{nodestable};
  my $edgeTable = $params->{edgestable} || $params->{table};
  my $doGraphFromTable = (defined $nodeTable || defined $edgeTable);
  my $parser;

  if ($doGraphFromTable) {
    require Foswiki::Plugins::GraphvizPlugin::TableParser;
    $parser = Foswiki::Plugins::GraphvizPlugin::TableParser->new();
    my ($meta) = Foswiki::Func::readTopic($theWeb, $theTopic);
    $parser->parse($meta->text, $meta);
    $text = "digraph $theTopic {\n";
    $text .= "\n".($params->{preamble} || '')."\n";
  }

  # .... read attachment
  if (defined $attachment) {
    return _inlineError("Error: attachment '$attachment' not found at $theWeb.$theTopic")
      unless Foswiki::Func::attachmentExists($theWeb, $theTopic, $attachment);
    $text = Foswiki::Func::readAttachment($theWeb, $theTopic, $attachment);
  } 

  # ... from a named section
  elsif (defined $section) {
    my $thisParams = Foswiki::Attrs->new(); 

    while (my ($key, $val) = each %$params) {
      next if $key =~ /^(_.*|attachment|type|renderer|engine|topic|library|inline|expand|style|width|height)$/;
      $thisParams->{$key} = $val;
    }
    $thisParams->{_DEFAULT} = "$theWeb.$theTopic";
    my ($meta) = Foswiki::Func::readTopic($web, $topic);
    $text = $session->INCLUDE($thisParams, $meta)
  }

  # ... from table
  elsif (defined $nodeTable || defined $edgeTable) {
    $text .= $parser->getNodes($nodeTable, $params) if defined $nodeTable;
    $text .= $parser->getEdges($edgeTable, $params) if defined $edgeTable;
  }

  # ... from text param
  else {
    $text = $params->remove("_DEFAULT") || $params->remove("text");
  }

  if ($doGraphFromTable) {
    $text .= "}";
  }

  # expand
  $text = Foswiki::Func::expandCommonVariables($text) 
    if Foswiki::Func::isTrue($params->{expand}, 0);

  return _inlineError("Error: no dot code") unless defined $text;

  $text = Encode::encode_utf8($text);

  my $type = $params->{type} || "svg";
  return _inlineError("Error: unknown type '$type'")
    unless $type =~ /^(svgz?|png|gif|jpe?g|pdf)$/;

  my $renderer = $params->{renderer} || $params->{engine} || "dot";
  return _inlineError("Error: unknown renderer '$renderer'")
    unless $renderer =~ /^(dot|neato|twopi|circle|s?fdp|patchwork)$/;

  my $library = $params->{library};
  my ($libraryWeb, $libraryTopic) = Foswiki::Func::normalizeWebTopicName($theWeb, $library||$theTopic);
  my $libraryPath = $Foswiki::cfg{PubDir}.'/'.$libraryWeb.'/'.$libraryTopic.'/';
  writeDebug("libraryPath=$libraryPath");
  $ENV{'GV_FILE_PATH'} = $libraryPath;

  my $doInline = Foswiki::Func::isTrue($params->{inline}, 0);

  my $pubDir = $Foswiki::cfg{PubDir}.'/'.$theWeb.'/'.$theTopic;
  File::Path::make_path($pubDir) unless -d $pubDir;

  my $md5 = Digest::MD5::md5_hex($text, $params->stringify);
  my $outfile = 'graphviz_'.$md5.".".$type;
  my $outfilePath = $pubDir.'/'.$outfile;

  my $error;
  my $output;
  my $exit;
  my $result;

  if (-f $outfilePath && $refresh !~ /^(img|graphviz|dot|all)$/) {
    writeDebug("$outfilePath already exists");
  } else {
    writeDebug("generating $outfilePath");

    my $dotFH = File::Temp->new(
      UNLINK => TRACE?0:1,
      SUFFIX => '.dot'
    );

    writeDebug("infile=".$dotFH->filename);
    writeDebug("outfile=".$outfilePath);

    print $dotFH $text;


    ($output, $exit, $error) = Foswiki::Sandbox->sysCommand(
      $this->{dotCmd},
      TYPE => $type, 
      RENDERER => $renderer, 
      OUTFILE => $outfilePath,
      INFILE => $dotFH->filename,
    );

    writeDebug("exit=".$exit);
    writeDebug("output=$output");
    writeDebug("error=$error");
  }

  if ($error) {
    $error =~ s/^Warning.*:/Warning:/g;
    $result = _inlineError("<pre>$error</pre>");
  } else {
    my $url = Foswiki::Func::getPubUrlPath()."/$theWeb/$theTopic/$outfile";

    my $style = $params->{style};
    $style = "style='".$style."'" if defined $style;

    my $width = $params->{width};
    my $height = $params->{height};

    if ($type eq 'svg' && $doInline) {
      my $svg = Foswiki::Func::readFile($outfilePath);
      $svg =~ s/<\?xml .*?>/<!-- -->/g;
      $svg =~ s/<!DOCTYPE.*dtd">/<!-- -->/gs;
      $result = $this->{svgFormat};

      $result =~ s/\$svg/$svg/;
      $result =~ s/width="[^"]*"/width="$width"/ if defined $width;
      $result =~ s/height="[^"]*"/height="$height"/ if defined $height;
      $result =~ s/<svg /<svg $style / if defined $style;

    } else {
      $result = $this->{imageFormat};

      $style ||= '';
      $width ||= '';
      $height ||= '';
      $width = "width='".$width."'" if $width;
      $height = "height='".$height."'" if $height;

      $result =~ s/\$style/$style/g;
      $result =~ s/\$width/$width/g;
      $result =~ s/\$height/$height/g;
    }

    $result =~ s/\$url/$url/g;
  }

  #writeDebug("result=$result");

  return $result;
}

sub afterSaveHandler {
  my $this = shift;
  #my ( $text, $topic, $web, $error, $meta ) = @_;

  $this->cleanUp($_[2], $_[1]);
}

sub cleanUp {
  my ($this, $web, $topic) = @_;

  opendir(my $dh, $Foswiki::cfg{PubDir} . '/' . $web . '/' . $topic . '/') || return;
  my @thumbs = grep { /^graphviz_[0-9a-f]{32}/ } readdir $dh;
  closedir $dh;

  writeDebug("cleaning up @thumbs");

  foreach my $file (@thumbs) {
    my $thumbPath = $web . '/' . $topic . '/' . $file;
    $thumbPath = Foswiki::Sandbox::untaint($thumbPath, \&Foswiki::Sandbox::validateAttachmentName);
    unlink $Foswiki::cfg{PubDir} . '/' . $thumbPath;
  }
}

sub _inlineError {
  return "<div class='foswikiAlert'>$_[0]</div>";
}


1;
