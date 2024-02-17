# ---+ Extensions
# ---++ GraphvizPlugin
# This is the configuration used by the <b>GraphvizPlugin</b>.

# **STRING**
$Foswiki::cfg{GraphvizPlugin}{DotCmd} = '/usr/bin/dot -K%RENDERER|S% -T%TYPE|S% -o%OUTFILE|F% %INFILE|F%';

# **STRING**
$Foswiki::cfg{GraphvizPlugin}{ImageFormat} = '<noautolink><object data=\'$url\' class=\'graphviz\' $style$width$height></object></noautolink>';

# **STRING**
$Foswiki::cfg{GraphvizPlugin}{SvgFormat} = '<noautolink><literal>$svg</literal></noautolink>';

1;
