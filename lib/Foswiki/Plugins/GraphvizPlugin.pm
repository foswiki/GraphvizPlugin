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

package Foswiki::Plugins::GraphvizPlugin;

use strict;
use warnings;

use Foswiki::Func ();
use Foswiki::Plugins ();
use Foswiki::Attrs ();
use Foswiki::Plugins::WysiwygPlugin ();

our $VERSION = '0.02';
our $RELEASE = '11 Aug 2015';
our $SHORTDESCRIPTION = 'Draw graphs using the !GraphViz utility';
our $NO_PREFS_IN_TOPIC = 1;
our $core;

sub core {
  unless (defined $core) {
    require Foswiki::Plugins::GraphvizPlugin::Core;
    $core = new Foswiki::Plugins::GraphvizPlugin::Core();
  }
  return $core;
}

sub initPlugin {

  Foswiki::Func::registerTagHandler('GRAPHVIZ', sub { return core->GRAPHVIZ(@_); });

  Foswiki::Plugins::WysiwygPlugin::addXMLTag('dot', sub { 1 });
  Foswiki::Plugins::WysiwygPlugin::addXMLTag('graphviz', sub { 1 });

  return 1;
}

sub commonTagsHandler {
  my $topic = $_[1];
  my $web   = $_[2];

  $_[0] =~ s/<(?:graphviz|dot)(.*?)>(.*?)<\/(?:graphviz|dot)>/_handleXML($web, $topic, $1, $2)/gise;
}

sub _handleXML {
  my ($web, $topic, $attrs, $code) = @_;
  
  my $params = new Foswiki::Attrs($attrs);
  delete $params->{_RAW};
  delete $params->{_ERROR};
  $params->{_DEFAULT} = $code;

  my $session = $Foswiki::Plugins::SESSION;
  return core->GRAPHVIZ($session, $params, $topic, $web);
}

sub afterSaveHandler {
  core->afterSaveHandler(@_);
}

sub finishPlugin {
  undef $core;
}

1;
