# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# GraphvizPlugin is Copyright (C) 2015-2018 Michael Daum http://michaeldaumconsulting.com
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

package Foswiki::Plugins::GraphvizPlugin::TableParser;

use strict;
use warnings;

use Foswiki::Tables::Reader ();
our @ISA = ('Foswiki::Tables::Reader');

sub parse {
  my ($this, $text, $meta) = @_;

  $this->SUPER::parse($text, $meta);

  return $this->{result};
}

sub getNodes {
  my ($this, $tableIndex, $params) = @_;

  my $table = $this->{result}[$tableIndex];

  return unless $table;

  $params->{nodecol} = 0 unless defined $params->{nodecol};

  my @lines = ();

  # generate nodes
  my $index = 0;
  foreach my $table ($table->getCellData) {
    foreach my $row (@$table) {
      $index++;
      next if $index == 1;# skip header
      my @attrs = ();
      push @attrs, "$row->[$params->{nodeattrcol}]" if defined $params->{nodeattrcol};
      my $attrs = '';
      $attrs = "[".join(", ", @attrs)."]" if @attrs;
      push @lines, "  \"$row->[$params->{nodecol}]\" $attrs";
    }
  }

  return join("\n", @lines);  
}

sub getEdges {
  my ($this, $tableIndex, $params) = @_;

  my $table = $this->{result}[$tableIndex];

  return unless $table;

  $params->{sourcecol} = 0 unless defined $params->{sourcecol};
  $params->{targetcol} = 1 unless defined $params->{targetcol};

  my @lines = ();

  # generate edges
  my $index = 0;
  foreach my $table ($table->getCellData) {
    foreach my $row (@$table) {
      $index++;
      next if $index == 1;# skip header
      my @attrs = ();
      push @attrs, "xlabel=\"$row->[$params->{labelcol}]\"" if defined $params->{labelcol};
      push @attrs, "$row->[$params->{edgeattrcol}]" if defined $params->{edgeattrcol};
      my $attrs = '';
      $attrs = "[".join(", ", @attrs)."]" if @attrs;
      push @lines, "  \"$row->[$params->{sourcecol}]\" -> \"$row->[$params->{targetcol}]\" $attrs";
    }
  }

  return join("\n", @lines);  
}

sub line {
  my ( $this, $line ) = @_;

  # ignore all non-table lines
}

1;

