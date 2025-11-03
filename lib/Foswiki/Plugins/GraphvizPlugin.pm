# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# GraphvizPlugin is Copyright (C) 2015-2025 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::GraphvizPlugin;

=begin TML

---+ package Foswiki::Plugins::GraphvizPlugin

plugin class to hook into the foswiki core

=cut

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins ();
use Foswiki::Attrs ();
use Foswiki::Plugins::WysiwygPlugin ();

our $VERSION = '1.12';
our $RELEASE = '%$RELEASE%';
our $SHORTDESCRIPTION = 'Draw graphs using the !GraphViz utility';
our $LICENSECODE = '%$LICENSECODE%';
our $NO_PREFS_IN_TOPIC = 1;
our $core;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean

initialize the plugin, automatically called during the core initialization process

=cut

sub initPlugin {

  Foswiki::Func::registerTagHandler('GRAPHVIZ', sub { return getCore()->GRAPHVIZ(@_); });

  Foswiki::Plugins::WysiwygPlugin::addXMLTag('dot', sub { 1 });
  Foswiki::Plugins::WysiwygPlugin::addXMLTag('graphviz', sub { 1 });

  return 1;
}

=begin TML

---++ finishPlugin

finish the plugin and the core if it has been used,
automatically called during the core initialization process

=cut

sub finishPlugin {
  undef $core;
}

=begin TML

---++ getCore() -> $core

returns a singleton core object for this plugin

=cut

sub getCore {

  unless (defined $core) {
    require Foswiki::Plugins::GraphvizPlugin::Core;
    $core = new Foswiki::Plugins::GraphvizPlugin::Core();
  }
  return $core;
}


=begin TML

---++ ObjectMethod commonTagsHandler() 

process dot and graphviz markup

=cut

sub commonTagsHandler {
  my $topic = $_[1];
  my $web   = $_[2];

  $_[0] =~ s/<(graphviz|dot)(.*?)>(.*?)<\/\1>/_handleXML($web, $topic, $2, $3)/gise;
}

sub _handleXML {
  my ($web, $topic, $attrs, $code) = @_;
  
  my $params = new Foswiki::Attrs($attrs);
  delete $params->{_RAW};
  delete $params->{_ERROR};
  $params->{_DEFAULT} = $code;

  my $session = $Foswiki::Plugins::SESSION;
  return getCore()->GRAPHVIZ($session, $params, $topic, $web);
}

=begin TML

---++ ObjectMethod afterSaveHandler() 

=cut

sub afterSaveHandler {
  getCore()->afterSaveHandler(@_);
}

1;
